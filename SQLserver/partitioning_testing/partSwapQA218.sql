-- find partition number for 'QA218'
SELECT $partition.EnvironmentNamePf('QA218');

TRUNCATE TABLE [Target] WITH (PARTITIONS(2));

ALTER TABLE [Stage] SWITCH PARTITION 2 TO [Target] PARTITION 2;
