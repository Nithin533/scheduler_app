"""Gemini AI integration for the scheduling engine.

Design: the rule-based SchedulerService already does the hard, safety-
critical part correctly — it carves out sleep, meals, hygiene, travel,
and fixed events as protected blocks. What it does NOT do well is decide
*which* tasks deserve the remaining free slots and in what order, when
there are more pending tasks than free time. That's a judgment call
(priority vs. deadline vs. variety vs. "this hasn't been touched in
days") that's a better fit for an LLM than a fixed sort key.

So Gemini's job here is narrow and bounded: given the list of pending
tasks and the amount of free time available today, return an ordered
subset of task IDs to schedule today, plus a short reason per task. The
actual time-block math (start/end times, gaps, breaks) stays in
scheduler.py — Gemini never invents times, it only orders/filters tasks.
This keeps the blast radius small if the API call fails or returns
something malformed: we fall back to the existing priority/due_date sort
and the user's day still gets built correctly.
"""
import json
import logging
from datetime import date

import httpx

from app.config import settings

logger = logging.getLogger(__name__)

GEMINI_URL = (
    "https://generativelanguage.googleapis.com/v1beta/models/"
    "gemini-2.0-flash:generateContent"
)


async def get_ai_task_ordering(
    tasks: list[dict],
    free_minutes_today: int,
    target_date: date,
    profile_summary: dict,
) -> list[int] | None:
    """Ask Gemini to pick and order which pending tasks fit today.

    Returns a list of task IDs in the order they should be scheduled, or
    None if Gemini is not configured / the call fails / the response
    can't be parsed — callers MUST fall back to rule-based sorting in
    that case, never raise.
    """
    if not settings.gemini_api_key:
        logger.debug("GEMINI_API_KEY not set — skipping AI ordering, using rule-based fallback")
        return None

    if not tasks:
        return []

    task_lines = "\n".join(
        f"- id={t['id']} | \"{t['title']}\" | category={t['category']} | "
        f"priority={t['priority']} (1=urgent..5=can wait) | "
        f"duration={t['estimated_duration_minutes']}min | "
        f"due_date={t.get('due_date') or 'none'}"
        for t in tasks
    )

    prompt = f"""You are a scheduling assistant. Pick which of these pending tasks
should be done on {target_date.isoformat()}, given only {free_minutes_today}
minutes of free time available, and return them in the best order.

USER CONTEXT:
- Occupation: {profile_summary.get('occupation', 'unknown')}
- Hobbies: {', '.join(profile_summary.get('hobbies', [])) or 'none listed'}
- Skills being developed: {', '.join(profile_summary.get('skills_learning', [])) or 'none listed'}

PENDING TASKS:
{task_lines}

RULES:
1. Respect priority (lower number = more urgent) as the primary signal.
2. Respect due_date — anything due today or overdue must be included if it fits.
3. Don't pick tasks whose total duration exceeds {free_minutes_today} minutes.
4. Prefer variety — don't let one category (e.g. only "career") crowd out
   hobbies/fitness entirely across the week; assume other days exist for
   what doesn't fit today.
5. If two tasks are equally urgent, prefer the one that's gone longest
   without being scheduled (you don't have that data, so just use a
   sensible default order).

Return ONLY a JSON array of task IDs (integers) in the order they should
be scheduled today. No explanation, no markdown, no extra text. Example:
[3, 7, 1]"""

    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.post(
                GEMINI_URL,
                params={"key": settings.gemini_api_key},
                json={
                    "contents": [{"parts": [{"text": prompt}]}],
                    "generationConfig": {"temperature": 0.4, "maxOutputTokens": 500},
                },
            )
        resp.raise_for_status()
        data = resp.json()
        text = data["candidates"][0]["content"]["parts"][0]["text"]
        clean = text.replace("```json", "").replace("```", "").strip()
        ordering = json.loads(clean)

        if not isinstance(ordering, list):
            logger.warning("Gemini returned non-list ordering, falling back: %r", ordering)
            return None

        valid_ids = {t["id"] for t in tasks}
        ordering = [tid for tid in ordering if tid in valid_ids]
        return ordering

    except (httpx.HTTPError, KeyError, IndexError, json.JSONDecodeError) as e:
        logger.error("Gemini task ordering failed, falling back to rule-based sort: %s", e)
        return None
    except Exception as e:
        # Catch-all so a Gemini hiccup never breaks schedule generation —
        # the rule-based scheduler must always be able to run standalone.
        logger.error("Unexpected error calling Gemini, falling back: %s", e)
        return None
