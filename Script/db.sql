CREATE DATABASE IF NOT EXISTS dodam
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_general_ci;


CREATE TABLE IF NOT EXISTS dodam.users (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(255),
  password VARCHAR(255),
  role VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS dodam.quiz (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  book_id BIGINT NOT NULL,
  title VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS dodam.question (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  quiz_id BIGINT,
  question_text VARCHAR(255) NOT NULL,
  question_type VARCHAR(50) NOT NULL,
  CONSTRAINT fk_question_quiz FOREIGN KEY (quiz_id) REFERENCES quiz(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DO
  (SELECT COUNT(*) INTO @exists FROM information_schema.statistics
    WHERE table_schema = 'dodam' AND table_name = 'question' AND index_name = 'idx_question_quiz_id');
SET @sql = IF(@exists = 0, 'CREATE INDEX idx_question_quiz_id ON dodam.question(quiz_id);', 'SELECT "index exists";');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

CREATE TABLE IF NOT EXISTS dodam.quiz_option (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  question_id BIGINT,
  option_text VARCHAR(255) NOT NULL,
  is_correct BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT fk_quiz_option_question FOREIGN KEY (question_id) REFERENCES dodam.question(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DO
  (SELECT COUNT(*) INTO @exists FROM information_schema.statistics
    WHERE table_schema = 'dodam' AND table_name = 'quiz_option' AND index_name = 'idx_quiz_option_question_id');
SET @sql = IF(@exists = 0, 'CREATE INDEX idx_quiz_option_question_id ON dodam.quiz_option(question_id);', 'SELECT "index exists";');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

CREATE TABLE IF NOT EXISTS dodam.quiz_submission (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT,
  question_id BIGINT,
  selected_option_id BIGINT,
  is_correct BOOLEAN NOT NULL,
  submitted_at DATETIME,
  CONSTRAINT fk_quiz_submission_user FOREIGN KEY (user_id) REFERENCES dodam.users(id) ON DELETE SET NULL,
  CONSTRAINT fk_quiz_submission_question FOREIGN KEY (question_id) REFERENCES dodam.question(id) ON DELETE SET NULL,
  CONSTRAINT fk_quiz_submission_selected_option FOREIGN KEY (selected_option_id) REFERENCES dodam.quiz_option(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DO
  (SELECT COUNT(*) INTO @exists FROM information_schema.statistics
    WHERE table_schema = 'dodam' AND table_name = 'quiz_submission' AND index_name = 'idx_quiz_submission_user_id');
SET @sql = IF(@exists = 0, 'CREATE INDEX idx_quiz_submission_user_id ON dodam.quiz_submission(user_id);', 'SELECT "index exists";');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

DO
  (SELECT COUNT(*) INTO @exists FROM information_schema.statistics
    WHERE table_schema = 'dodam' AND table_name = 'quiz_submission' AND index_name = 'idx_quiz_submission_question_id');
SET @sql = IF(@exists = 0, 'CREATE INDEX idx_quiz_submission_question_id ON dodam.quiz_submission(question_id);', 'SELECT "index exists";');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

DO
  (SELECT COUNT(*) INTO @exists FROM information_schema.statistics
    WHERE table_schema = 'dodam' AND table_name = 'quiz_submission' AND index_name = 'idx_quiz_submission_selected_option_id');
SET @sql = IF(@exists = 0, 'CREATE INDEX idx_quiz_submission_selected_option_id ON dodam.quiz_submission(selected_option_id);', 'SELECT "index exists";');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

CREATE TABLE IF NOT EXISTS dodam.reading (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  read_date DATE NOT NULL,
  start_time TIME,
  end_time TIME,
  pages_read INT,
  thought VARCHAR(1000),
  read_duration_minutes INT DEFAULT 0,
  read_book_id BIGINT,
  read_book_title VARCHAR(255),
  is_goal_achieved BOOLEAN DEFAULT FALSE,
  is_book_completed_for_this_log BOOLEAN DEFAULT FALSE,
  created_at DATETIME,
  updated_at DATETIME,
  CONSTRAINT fk_reading_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DO
  (SELECT COUNT(*) INTO @exists FROM information_schema.statistics
    WHERE table_schema = 'dodam' AND table_name = 'reading' AND index_name = 'idx_reading_user_id');
SET @sql = IF(@exists = 0, 'CREATE INDEX idx_reading_user_id ON dodam.reading(user_id);', 'SELECT "index exists";');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

DO
  (SELECT COUNT(*) INTO @exists FROM information_schema.statistics
    WHERE table_schema = 'dodam' AND table_name = 'reading' AND index_name = 'idx_reading_read_date');
SET @sql = IF(@exists = 0, 'CREATE INDEX idx_reading_read_date ON dodam.reading(read_date);', 'SELECT "index exists";');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
