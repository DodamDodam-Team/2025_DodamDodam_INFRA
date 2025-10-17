CREATE TABLE `dodam.user` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `password` VARCHAR(255) NOT NULL,
    `username` VARCHAR(255) NOT NULL UNIQUE,
    `role` VARCHAR(255),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dodam.quiz` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `book_id` BIGINT,
    `title` VARCHAR(255),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dodam.reading` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `read_date` DATE NOT NULL,
    `read_focus` BIGINT,
    `read_month` INT,
    `created_at` DATETIME(6) NOT NULL,
    `is_book_completed_for_this_log` BIT(1),
    `is_goal_achieved` BIT(1),
    `read_book_id` BIGINT,
    `read_book_title` VARCHAR(255),
    `read_duration_minutes` INT,
    `updated_at` DATETIME(6),
    `user_id` BIGINT NOT NULL,
    `end_time` TIME(6),
    `pages_read` INT,
    `start_time` TIME(6),
    `thought` VARCHAR(1000),
    PRIMARY KEY (`id`),
    FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dodam.question` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `correct_answer` VARCHAR(255),
    `options` TEXT,
    `question_text` VARCHAR(255) NOT NULL,
    `question_type` ENUM('multiple_choice', 'ox') NOT NULL,
    `quiz_id` BIGINT NOT NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`quiz_id`) REFERENCES `quiz`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;