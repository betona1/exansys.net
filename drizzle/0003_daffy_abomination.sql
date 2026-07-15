CREATE TABLE `review_caches` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`store` text NOT NULL,
	`app_id` text NOT NULL,
	`region` text NOT NULL,
	`title` text NOT NULL,
	`icon_url` text,
	`score` real,
	`ratings` integer,
	`installs` text,
	`real_installs` integer,
	`review_count` integer DEFAULT 0 NOT NULL,
	`fetched_at` integer NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `idx_review_caches_key` ON `review_caches` (`store`,`app_id`,`region`);--> statement-breakpoint
CREATE TABLE `review_items` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`cache_id` integer NOT NULL,
	`score` integer DEFAULT 0 NOT NULL,
	`content` text NOT NULL,
	`at` integer,
	`thumbs_up` integer DEFAULT 0 NOT NULL,
	`user_name` text,
	`version` text,
	FOREIGN KEY (`cache_id`) REFERENCES `review_caches`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE INDEX `idx_review_items_cache` ON `review_items` (`cache_id`);