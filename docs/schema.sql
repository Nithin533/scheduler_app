-- Scheduler App - MySQL Schema
-- Run this to create the database and all tables

CREATE DATABASE IF NOT EXISTS scheduler_app
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE scheduler_app;

-- ============================================
-- 1. Users
-- ============================================
CREATE TABLE users (
  id            INT           AUTO_INCREMENT PRIMARY KEY,
  email         VARCHAR(255)  NOT NULL UNIQUE,
  password_hash VARCHAR(255)  NOT NULL,
  name          VARCHAR(100)  DEFAULT NULL,
  created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_users_email (email)
) ENGINE=InnoDB;

-- ============================================
-- 2. User Profiles (onboarding / lifestyle)
-- ============================================
CREATE TABLE user_profiles (
  id                    INT           AUTO_INCREMENT PRIMARY KEY,
  user_id               INT           NOT NULL UNIQUE,
  age                   INT           DEFAULT NULL,
  occupation            VARCHAR(100)  DEFAULT NULL,
  work_start_time       TIME          DEFAULT NULL,
  work_end_time         TIME          DEFAULT NULL,
  work_days             JSON          DEFAULT NULL,
  commute_time_minutes  INT           DEFAULT 30,
  sports                JSON          DEFAULT NULL,
  hobbies               JSON          DEFAULT NULL,
  skills_learning       JSON          DEFAULT NULL,
  long_term_goals       JSON          DEFAULT NULL,
  fitness_info          JSON          DEFAULT NULL,
  diet_tracking         JSON          DEFAULT NULL,
  sleep_target_hours    DECIMAL(3,1)  DEFAULT 8.0,
  has_part_time_job     BOOLEAN       DEFAULT FALSE,
  part_time_start       TIME          DEFAULT NULL,
  part_time_end         TIME          DEFAULT NULL,
  part_time_days        JSON          DEFAULT NULL,
  created_at            DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at            DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- 3. Fixed Events (immutable schedule blocks)
-- ============================================
CREATE TABLE fixed_events (
  id                INT           AUTO_INCREMENT PRIMARY KEY,
  user_id           INT           NOT NULL,
  title             VARCHAR(200)  NOT NULL,
  description       TEXT          DEFAULT NULL,
  day_of_week       TINYINT       DEFAULT NULL COMMENT '0=Sun .. 6=Sat',
  start_time        TIME          NOT NULL,
  end_time          TIME          NOT NULL,
  start_date        DATE          DEFAULT NULL,
  end_date          DATE          DEFAULT NULL,
  is_recurring      BOOLEAN       DEFAULT FALSE,
  recurrence_rule   VARCHAR(255)  DEFAULT NULL,
  category          ENUM('college','work','part_time','appointment','other') NOT NULL DEFAULT 'other',
  color             VARCHAR(7)    DEFAULT '#3788d8',
  is_active         BOOLEAN       DEFAULT TRUE,
  created_at        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_fixed_events_user (user_id),
  INDEX idx_fixed_events_day (day_of_week)
) ENGINE=InnoDB;

-- ============================================
-- 4. Tasks (flexible / schedulable items)
-- ============================================
CREATE TABLE tasks (
  id                      INT           AUTO_INCREMENT PRIMARY KEY,
  user_id                 INT           NOT NULL,
  title                   VARCHAR(200)  NOT NULL,
  description             TEXT          DEFAULT NULL,
  priority                TINYINT       NOT NULL DEFAULT 3 COMMENT '1=urgent .. 5=can wait',
  estimated_duration_minutes INT        NOT NULL DEFAULT 30,
  category                ENUM('hobby','skill','fitness','career','health','academic','chore','other') NOT NULL DEFAULT 'other',
  due_date                DATE          DEFAULT NULL,
  is_completed            BOOLEAN       DEFAULT FALSE,
  is_recurring            BOOLEAN       DEFAULT FALSE,
  recurrence_rule         VARCHAR(255)  DEFAULT NULL,
  is_flexible             BOOLEAN       DEFAULT TRUE,
  preferred_time_slot     ENUM('morning','afternoon','evening','any') DEFAULT 'any',
  min_times_per_week      INT           DEFAULT NULL,
  parent_goal_id          INT           DEFAULT NULL,
  progress                DECIMAL(5,2)  DEFAULT 0.00,
  created_at              DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at              DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (parent_goal_id) REFERENCES tasks(id) ON DELETE SET NULL,
  INDEX idx_tasks_user (user_id),
  INDEX idx_tasks_priority (priority),
  INDEX idx_tasks_due (due_date),
  INDEX idx_tasks_completed (is_completed)
) ENGINE=InnoDB;

-- ============================================
-- 5. Habits (trackable daily / weekly items)
-- ============================================
CREATE TABLE habits (
  id            INT           AUTO_INCREMENT PRIMARY KEY,
  user_id       INT           NOT NULL,
  name          VARCHAR(100)  NOT NULL,
  description   TEXT          DEFAULT NULL,
  unit          VARCHAR(50)   DEFAULT NULL,
  target_value  DECIMAL(10,2) DEFAULT NULL,
  frequency     ENUM('daily','weekly','per_meal') NOT NULL DEFAULT 'daily',
  icon          VARCHAR(50)   DEFAULT NULL,
  is_active     BOOLEAN       DEFAULT TRUE,
  created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_habits_user (user_id)
) ENGINE=InnoDB;

-- ============================================
-- 6. Habit Logs
-- ============================================
CREATE TABLE habit_logs (
  id          INT           AUTO_INCREMENT PRIMARY KEY,
  habit_id    INT           NOT NULL,
  user_id     INT           NOT NULL,
  log_date    DATE          NOT NULL,
  value       DECIMAL(10,2) DEFAULT NULL,
  notes       TEXT          DEFAULT NULL,
  created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY uk_habit_log (habit_id, log_date),
  INDEX idx_habit_logs_user (user_id),
  INDEX idx_habit_logs_date (log_date)
) ENGINE=InnoDB;

-- ============================================
-- 7. Daily Schedules
-- ============================================
CREATE TABLE daily_schedules (
  id                    INT         AUTO_INCREMENT PRIMARY KEY,
  user_id               INT         NOT NULL,
  schedule_date         DATE        NOT NULL,
  is_confirmed          BOOLEAN     DEFAULT FALSE,
  total_free_hours      DECIMAL(4,1) DEFAULT NULL,
  total_scheduled_hours DECIMAL(4,1) DEFAULT NULL,
  is_balanced           BOOLEAN     DEFAULT NULL COMMENT 'health check passed',
  generated_at          DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at            DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY uk_daily_schedule (user_id, schedule_date),
  INDEX idx_schedules_user (user_id),
  INDEX idx_schedules_date (schedule_date)
) ENGINE=InnoDB;

-- ============================================
-- 8. Schedule Items (individual time blocks)
-- ============================================
CREATE TABLE schedule_items (
  id                    INT           AUTO_INCREMENT PRIMARY KEY,
  schedule_id           INT           NOT NULL,
  title                 VARCHAR(200)  NOT NULL,
  start_time            DATETIME      NOT NULL,
  end_time              DATETIME      NOT NULL,
  duration_minutes      INT           NOT NULL,
  item_type             ENUM('fixed_event','task','habit','break','meal','travel','sleep','bath','free','gym') NOT NULL,
  task_id               INT           DEFAULT NULL,
  event_id              INT           DEFAULT NULL,
  habit_id              INT           DEFAULT NULL,
  status                ENUM('scheduled','completed','missed','rescheduled') NOT NULL DEFAULT 'scheduled',
  completed_at          DATETIME      DEFAULT NULL,
  priority_at_schedule  TINYINT       DEFAULT NULL,
  created_at            DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (schedule_id) REFERENCES daily_schedules(id) ON DELETE CASCADE,
  FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE SET NULL,
  FOREIGN KEY (event_id) REFERENCES fixed_events(id) ON DELETE SET NULL,
  FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE SET NULL,
  INDEX idx_schedule_items_schedule (schedule_id),
  INDEX idx_schedule_items_status (status),
  INDEX idx_schedule_items_start (start_time)
) ENGINE=InnoDB;

-- ============================================
-- 9. End-of-Day Checklists
-- ============================================
CREATE TABLE end_of_day_checklists (
  id              INT       AUTO_INCREMENT PRIMARY KEY,
  user_id         INT       NOT NULL,
  checklist_date  DATE      NOT NULL,
  is_completed    BOOLEAN   DEFAULT FALSE,
  completed_at    DATETIME  DEFAULT NULL,
  created_at      DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY uk_checklist (user_id, checklist_date),
  INDEX idx_checklists_user (user_id),
  INDEX idx_checklists_date (checklist_date)
) ENGINE=InnoDB;

-- ============================================
-- 10. Checklist Items
-- ============================================
CREATE TABLE checklist_items (
  id              INT       AUTO_INCREMENT PRIMARY KEY,
  checklist_id    INT       NOT NULL,
  schedule_item_id INT      DEFAULT NULL,
  title           VARCHAR(200) NOT NULL,
  is_checked      BOOLEAN   DEFAULT FALSE,
  checked_at      DATETIME  DEFAULT NULL,
  FOREIGN KEY (checklist_id) REFERENCES end_of_day_checklists(id) ON DELETE CASCADE,
  FOREIGN KEY (schedule_item_id) REFERENCES schedule_items(id) ON DELETE SET NULL,
  INDEX idx_checklist_items_checklist (checklist_id)
) ENGINE=InnoDB;

-- ============================================
-- 11. Rescheduled Items
-- ============================================
CREATE TABLE rescheduled_items (
  id                  INT       AUTO_INCREMENT PRIMARY KEY,
  schedule_item_id    INT       NOT NULL,
  original_date       DATE      NOT NULL,
  rescheduled_to_date DATE      NOT NULL,
  reason              ENUM('not_completed','conflict','user_request') NOT NULL DEFAULT 'not_completed',
  created_at          DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (schedule_item_id) REFERENCES schedule_items(id) ON DELETE CASCADE,
  INDEX idx_rescheduled_original (original_date),
  INDEX idx_rescheduled_new (rescheduled_to_date)
) ENGINE=InnoDB;

-- ============================================
-- 12. Reminders
-- ============================================
CREATE TABLE reminders (
  id                INT       AUTO_INCREMENT PRIMARY KEY,
  user_id           INT       NOT NULL,
  schedule_item_id  INT       DEFAULT NULL,
  reminder_time     DATETIME  NOT NULL,
  is_sent           BOOLEAN   DEFAULT FALSE,
  sent_at           DATETIME  DEFAULT NULL,
  type              ENUM('pre_task','bedtime','habit','daily_review','wake_up') NOT NULL DEFAULT 'pre_task',
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (schedule_item_id) REFERENCES schedule_items(id) ON DELETE CASCADE,
  INDEX idx_reminders_time (reminder_time),
  INDEX idx_reminders_unsent (is_sent, reminder_time)
) ENGINE=InnoDB;

-- ============================================
-- 13. Google Calendar Sync
-- ============================================
CREATE TABLE google_calendar_sync (
  id                INT           AUTO_INCREMENT PRIMARY KEY,
  user_id           INT           NOT NULL UNIQUE,
  access_token      TEXT          DEFAULT NULL,
  refresh_token     TEXT          DEFAULT NULL,
  token_expiry      DATETIME      DEFAULT NULL,
  google_calendar_id VARCHAR(255) DEFAULT 'primary',
  last_synced_at    DATETIME      DEFAULT NULL,
  sync_enabled      BOOLEAN       DEFAULT TRUE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- 14. User Devices (FCM push tokens)
-- ============================================
CREATE TABLE user_devices (
  id            INT           AUTO_INCREMENT PRIMARY KEY,
  user_id       INT           NOT NULL,
  fcm_token     VARCHAR(500)  NOT NULL,
  platform      VARCHAR(20)   DEFAULT 'android',
  is_active     BOOLEAN       DEFAULT TRUE,
  created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_devices_user (user_id),
  INDEX idx_user_devices_token (fcm_token(255))
) ENGINE=InnoDB;
