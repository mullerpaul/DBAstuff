CREATE OR REPLACE PACKAGE dm_botimecard_rate_event
AS

c_regexp_rule      VARCHAR2(64) := '[\|]|[^_,:\.\(\)\[\]@#=\*\?\-\+[:alnum:]]';

PROCEDURE extract_bo_rate_events
(
    p_source_code IN VARCHAR2
  , p_from_date   IN VARCHAR2 -- YYYYMMDD
  , p_to_date     IN VARCHAR2 -- YYYYMMDD
  , p_start_date  IN VARCHAR2 -- YYYYMMDD
  , p_batch_id    IN NUMBER
);

PROCEDURE extract_all_bo_rate_events;

END dm_botimecard_rate_event;
/