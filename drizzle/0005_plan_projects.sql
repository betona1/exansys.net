CREATE TABLE `plan_projects` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`user_id` integer NOT NULL,
	`app_name` text NOT NULL,
	`stage` text DEFAULT 'IDEA' NOT NULL,
	`status` text DEFAULT 'ACTIVE' NOT NULL,
	`raw_idea` text,
	`target_user_raw` text,
	`problem_raw` text,
	`solution_raw` text,
	`revenue_model_raw` text,
	`distribution_channel_raw` text,
	`target_user` text,
	`payer` text,
	`influencer` text,
	`problem_situation` text,
	`current_solution` text,
	`current_solution_problem` text,
	`core_action` text,
	`expected_result` text,
	`first_success` text,
	`retention_reason` text,
	`revenue_model` text,
	`distribution_channel` text,
	`ai_assisted_at` integer,
	`ai_model` text,
	`created_at` integer NOT NULL,
	`updated_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE INDEX `idx_plan_projects_user` ON `plan_projects` (`user_id`,`status`);--> statement-breakpoint
CREATE TABLE `plan_evidence` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`project_id` integer NOT NULL,
	`user_id` integer NOT NULL,
	`evidence_type` text NOT NULL,
	`title` text NOT NULL,
	`summary` text,
	`source_reference` text,
	`sample_size` integer,
	`confidence_override` real,
	`supports` text DEFAULT '[]' NOT NULL,
	`contradicts` text DEFAULT '[]' NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`project_id`) REFERENCES `plan_projects`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE INDEX `idx_plan_evidence_project` ON `plan_evidence` (`project_id`);--> statement-breakpoint
CREATE TABLE `plan_analyses` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`project_id` integer NOT NULL,
	`user_id` integer NOT NULL,
	`total_score` real NOT NULL,
	`overall_confidence` real NOT NULL,
	`decision` text NOT NULL,
	`would_be_decision` text,
	`engine_version` text NOT NULL,
	`policy_version` text NOT NULL,
	`result_json` text NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`project_id`) REFERENCES `plan_projects`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE INDEX `idx_plan_analyses_project` ON `plan_analyses` (`project_id`,`created_at`);
