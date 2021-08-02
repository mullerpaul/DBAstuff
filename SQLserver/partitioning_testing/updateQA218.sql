-- transaction management commented out at first
--BEGIN TRANSACTION

UPDATE [Target]
   SET Attr1 = 2
 WHERE EnvironmentName = 'QA218';
 
--COMMIT 
