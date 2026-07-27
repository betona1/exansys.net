-- 갤러리용 컬럼 추가. 기존 데이터는 건드리지 않는다 (ADD COLUMN 만 사용).
ALTER TABLE `apps` ADD `thumb_url` text;--> statement-breakpoint
ALTER TABLE `apps` ADD `video_url` text;--> statement-breakpoint
ALTER TABLE `apps` ADD `category` text;--> statement-breakpoint
ALTER TABLE `apps` ADD `featured` integer DEFAULT false NOT NULL;--> statement-breakpoint
ALTER TABLE `apps` ADD `sort` integer DEFAULT 0 NOT NULL;
