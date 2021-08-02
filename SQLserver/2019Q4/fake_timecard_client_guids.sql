--  map client names to their GUIDs (from US prod)  and get a count of distinct reqs created since July 1st.
CREATE TABLE fake_client_guid 
  (id          int, 
   client_name varchar(50),
   client_guid uniqueidentifier,
   job_count   int);

BEGIN TRANSACTION;
INSERT INTO fake_client_guid (id, client_name, client_guid, job_count) VALUES (1, 'MetLife', N'398db1fd-cdd4-6d40-99db-770538caa682', 771);
INSERT INTO fake_client_guid (id, client_name, client_guid, job_count) VALUES (2, 'Uber', N'7fe9927e-ec57-e345-b1f0-5c8bc8d3a05b', 637);
INSERT INTO fake_client_guid (id, client_name, client_guid, job_count) VALUES (3, 'StateStreet', N'38939f69-e584-0b49-8288-1e42e16b50a0', 585);
INSERT INTO fake_client_guid (id, client_name, client_guid, job_count) VALUES (4, 'Exel', N'2d7c6430-6e44-f043-b0f2-b716dfe816a3', 515);
INSERT INTO fake_client_guid (id, client_name, client_guid, job_count) VALUES (5, 'InfoSys', N'98d06b74-ad0f-cf41-828a-2d26807b473a', 422);
INSERT INTO fake_client_guid (id, client_name, client_guid, job_count) VALUES (6, 'CreditSuisse', N'26a0f76a-09f4-6c45-8d4e-1285263cb823', 335);
INSERT INTO fake_client_guid (id, client_name, client_guid, job_count) VALUES (7, 'PWC', N'5bb445c1-f1f4-1c47-a88b-8eeac73f9440', 268);
INSERT INTO fake_client_guid (id, client_name, client_guid, job_count) VALUES (8, 'Target', N'78566dd9-ffb9-654a-8277-f1905089198b', 263);
INSERT INTO fake_client_guid (id, client_name, client_guid, job_count) VALUES (9, 'PNC', N'5dea8f96-2acb-7c40-a5bb-fddf3e69b9fa', 253);
INSERT INTO fake_client_guid (id, client_name, client_guid, job_count) VALUES (10, 'ContractorDepot', N'2d653b4b-de69-f640-84d4-d77a2034d091', 242);
COMMIT TRANSACTION;
