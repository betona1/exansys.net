CREATE TABLE `visit_logs` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`date` text NOT NULL,
	`visitor_hash` text NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `idx_visit_logs_dedupe` ON `visit_logs` (`date`,`visitor_hash`);--> statement-breakpoint
CREATE TABLE `visit_stats` (
	`date` text PRIMARY KEY NOT NULL,
	`pageviews` integer DEFAULT 0 NOT NULL,
	`visitors` integer DEFAULT 0 NOT NULL
);
