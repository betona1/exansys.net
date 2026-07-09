CREATE TABLE `app_builds` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`app_id` integer NOT NULL,
	`version` text NOT NULL,
	`file_key` text NOT NULL,
	`file_size` integer NOT NULL,
	`notes` text,
	`download_count` integer DEFAULT 0 NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`app_id`) REFERENCES `apps`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE INDEX `idx_app_builds_app` ON `app_builds` (`app_id`);