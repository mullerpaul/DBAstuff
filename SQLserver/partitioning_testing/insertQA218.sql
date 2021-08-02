-- transaction management commented out at first
--BEGIN TRANSACTION

INSERT INTO [Stage] (ClientSiteID, EnvironmentName, Attr1)
VALUES ('00000000-4444-5555-6666-000000000000', 'QA218', 1);

--COMMIT 
