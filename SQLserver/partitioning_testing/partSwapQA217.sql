-- find partition number for 'QA217'
SELECT $partition.EnvironmentNamePf('QA217'); 

TRUNCATE TABLE [Target] WITH (PARTITIONS(1));

ALTER TABLE [Stage] SWITCH PARTITION 1 TO [Target] PARTITION 1;
