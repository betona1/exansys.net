-- 앱 문구의 영문판. 기존 데이터는 건드리지 않는다 (ADD COLUMN 만 사용).
ALTER TABLE `apps` ADD `name_en` text;--> statement-breakpoint
ALTER TABLE `apps` ADD `tagline_en` text;--> statement-breakpoint
ALTER TABLE `apps` ADD `description_en` text;
