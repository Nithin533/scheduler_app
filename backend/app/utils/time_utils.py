from datetime import time, datetime, timedelta


def time_to_minutes(t: time) -> int:
    return t.hour * 60 + t.minute


def minutes_to_time(m: int) -> time:
    h = m // 60
    mn = m % 60
    return time(hour=h, minute=mn)


def time_slot_label(t: time) -> str:
    m = time_to_minutes(t)
    if 360 <= m < 720:
        return "morning"
    elif 720 <= m < 1020:
        return "afternoon"
    elif 1020 <= m < 1320:
        return "evening"
    else:
        return "night"
