-- transaction management commented out at first
--BEGIN TRANSACTION

INSERT INTO [Stage] (ClientSiteID, EnvironmentName, Attr1)
VALUES ('00000000-1111-2222-3333-000000000000', 'QA217', 1);

--COMMIT 
