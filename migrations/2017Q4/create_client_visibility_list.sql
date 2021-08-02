CREATE TABLE client_visibility_list
  (log_in_client_guid  RAW(16) NOT NULL,
   visible_client_guid RAW(16) NOT NULL,
   CONSTRAINT client_visibility_list_pk 
      PRIMARY KEY (log_in_client_guid, visible_client_guid))
ORGANIZATION INDEX
/

COMMENT ON TABLE client_visibility_list 
IS 'Stores rows for which client_guids are visible to a given client_guid passed from the VMS. Modeled as an "Adjacency List", stored as an Index-organized table. Beeline VMS data is currently just a "pass-through".'
/
COMMENT ON COLUMN client_visibility_list.log_in_client_guid
IS 'The client_guid which SSC recieves from the VMS.'
/
COMMENT ON COLUMN client_visibility_list.visible_client_guid
IS 'Any Client_guids which are visible to the logged in client_guid.'
/

