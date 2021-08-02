-- transaction-specific temp table  (its cleared out on commit or rollback)
DROP TABLE token_gtt
/
CREATE GLOBAL TEMPORARY TABLE token_gtt
(token VARCHAR2(255))-- NOT NULL)
/
--DROP TABLE prediction_performance_history
--/
CREATE TABLE prediction_performance_history
 (call_time         TIMESTAMP NOT NULL,
  end_canonize_time TIMESTAMP,
  end_tokenize_time TIMESTAMP,
  end_lookup_time   TIMESTAMP)
PCTFREE 0  -- logging table never updated
/

-- package to hold prediction functions
CREATE OR REPLACE PACKAGE predictions AS

    FUNCTION get_predicted_titles (
        fi_job_description IN CLOB
    ) RETURN VARCHAR2;

END predictions;
/

-- package body
CREATE OR REPLACE PACKAGE BODY predictions AS

    TYPE token_table IS
        TABLE OF VARCHAR2(255);

    PROCEDURE log_performance (
        pi_call_time           IN prediction_performance_history.call_time%TYPE,
        pi_end_canonize_time   IN prediction_performance_history.end_canonize_time%TYPE,
        pi_end_tokenize_time   IN prediction_performance_history.end_tokenize_time%TYPE,
        pi_end_lookup_time     IN prediction_performance_history.end_lookup_time%TYPE
    ) IS
        PRAGMA autonomous_transaction;
    BEGIN
        INSERT INTO prediction_performance_history (
            call_time,
            end_canonize_time,
            end_tokenize_time,
            end_lookup_time
        ) VALUES (
            pi_call_time,
            pi_end_canonize_time,
            pi_end_tokenize_time,
            pi_end_lookup_time
        );

        COMMIT;
    END log_performance;

    PROCEDURE print_token_table (pi_token_table IN token_table)   -- for debugging only
    IS
    BEGIN
        FOR i IN pi_token_table.FIRST .. pi_token_table.LAST LOOP
            dbms_output.put_line ('Token ' || to_char(i) || ': ' || pi_token_table(i));
        END LOOP;
    END print_token_table;    

    
    FUNCTION tokenize (
        fi_string IN CLOB
    ) RETURN token_table AS

    /* Really, it would be ideal to tokenize using THE SAME process, stoplist, stemming, etc as we used to make
       the data with.  That would be Oracle text indexes in this case.  However, I haven't figured out how to
       use the Oracle Text API packages to do so and hae had to roll my own tokenization.  
       If I can't figure that out, we may eventually want to move this whole process to Python  :-(  */

    /* Room for improvement here - there are better ways to do this!  */
        lv_result           token_table := token_table ();  -- initialize to empty
        lv_working_string   CLOB;
        lv_table_index      NUMBER := 1;
        lv_chunk_text       VARCHAR2(255);
        lv_no_of_chunks     NUMBER;
        lv_pos              NUMBER;
        lc_delimiter        CONSTANT VARCHAR2(1) := ' ';
    BEGIN
        lv_working_string := fi_string;
        lv_no_of_chunks := regexp_count(
            lv_working_string,
            lc_delimiter
        );
        IF lv_no_of_chunks = 0  --check for case where there are no delimiters.  Can we get rid of this and above call?
         THEN
            lv_working_string := lv_working_string || lc_delimiter;
            lv_no_of_chunks := 1;
        END IF;

        lv_result.extend(lv_no_of_chunks + 1);  -- extend the nested table to hold all of the tokens
        lv_pos := instr(lv_working_string, lc_delimiter, 1, 1);
        FOR i IN 1..lv_no_of_chunks LOOP
            lv_chunk_text := substr(lv_working_string, 1, lv_pos - 1);
            IF lv_chunk_text <> lc_delimiter THEN
                lv_result(lv_table_index) := lv_chunk_text;
                lv_table_index := lv_table_index + 1;
            END IF;

            lv_working_string := substr(lv_working_string, lv_pos + 1, length(lv_working_string));
            lv_pos := instr(lv_working_string, lc_delimiter, 1, 1);
            IF lv_pos = 0 THEN
                lv_result(lv_table_index) := lv_working_string;
            END IF;
        END LOOP;

        -- we have a bug here in allowing a final empty token in cases where the input ends with a delimeter.

        lv_result.trim(lv_no_of_chunks - lv_table_index + 1);
        RETURN lv_result;
    END tokenize;

    FUNCTION get_predicted_titles (
        fi_job_description IN CLOB
    ) RETURN VARCHAR2 AS
        lv_canonical_input   CLOB;
        la_token_table       token_table;
        lv_result            VARCHAR2(4000);
        lv_call_time         prediction_performance_history.call_time%TYPE := systimestamp;
        lv_end_canonize_time prediction_performance_history.end_canonize_time%TYPE;
        lv_end_tokenize_time prediction_performance_history.end_tokenize_time%TYPE;
        lv_end_lookup_time   prediction_performance_history.end_lookup_time%TYPE;
    BEGIN

    /* Need to tokenize input and record any tokens we find that also appear in JOB_DESCRIPTION_PREDICTIVE_TOKEN.
       To do that, we HAVE TO to uppercase all text and remove all non-token characters. (alpha, num, and some punct? verify)
       We also COULD remove all stopwords.  This isn't necessary since they wont appear in the predictive token table; but if its easy...
       Then, once we have extracted all the predictive tokens we use those to query the assignment data to find all assignments 
       that contain one or more of those predictive tokens.  We pull the title AND the match score, then group on title and sum the scores.
       Order the titles by total score descending and return the top 10.  */
    
    /* Canonize
       Make all letters uppercase and remove everything but letters, numbers, period, and comma. 
       There is probably a better way to do this using ONLY the regexp replace instead of 3 nested functions... */
        lv_canonical_input := TRANSLATE(
                                  UPPER(
                                      regexp_replace(
                                          fi_job_description,
                                          '[^ -z]',
                                          ''
                                      )
                                  ),
                                  'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!"#=$%&?()''*+<>^@-/',
                                  'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789. '
                              );
        lv_end_canonize_time := systimestamp;
        
    /* tokenize */
        la_token_table := tokenize(lv_canonical_input);
        lv_end_tokenize_time := systimestamp;
        
    /* debug - print the nested table to screen */
       --print_token_table(la_token_table);

    /* Use any "predictive" tokens out of the tokens returned, find common job titles in our data with
       descriptions that also included those predictive tokens.  */
    /* do we need to put this into a temp table, can we use the TABLE function to join to the memory variable instead? */   
        FORALL i IN la_token_table.FIRST .. la_token_table.LAST
            INSERT INTO token_gtt (token) VALUES (la_token_table(i));

    /* turn that resultset into JSON */
        WITH token_title
          AS (SELECT DISTINCT pta.predictive_token, pta.inverse_document_frequency, pta.job_title
                FROM token_gtt tt,
                     predictive_tokens_and_assignments pta
               WHERE tt.token = pta.predictive_token)
      SELECT JSON_ARRAYAGG(JSON_OBJECT('predictedJobTitle' VALUE job_title,
                                       'score'             VALUE score,
                                       'sharedTokenCount'  VALUE shared_tokens
                                       FORMAT JSON)) AS json_out
        INTO lv_result
        FROM (SELECT job_title, 
                     COUNT(*) AS shared_tokens, 
                     SUM(inverse_document_frequency) AS score
                FROM token_title
               GROUP BY job_title
               ORDER BY 3 DESC
               FETCH FIRST 5 ROWS ONLY);

        lv_end_lookup_time := systimestamp;

        COMMIT;  -- no changes have been made to commit; but placing this here to empty temp table.

        log_performance(
            pi_call_time => lv_call_time,
            pi_end_canonize_time => lv_end_canonize_time,
            pi_end_tokenize_time => lv_end_tokenize_time,
            pi_end_lookup_time => lv_end_lookup_time
        );
        
        RETURN lv_result;

    END get_predicted_titles;

END predictions;
/

-- test via anon block
set serveroutput on
begin
  dbms_output.put_line(
      predictions.get_predicted_titles(
--          q'{manages a small team of developers. Must gather requirements from business team and then create development stories in JIRA. }'
          q'{Install, upgrade, and administer Oracle databases}'
--          q'{}'
      )
  );
end;
/

  with elapsed_seconds
    as (select call_time,
               extract(second from (end_canonize_time - call_time))         as canonization_elapsed,
               extract(second from (end_tokenize_time - end_canonize_time)) as tokenization_elapsed,
               extract(second from (end_lookup_time - end_tokenize_time))   as result_lookup_elapsed,
               extract(second from (end_lookup_time - call_time))           as total_elapsed
          from prediction_performance_history)
select call_time, total_elapsed,
       ROUND(100 * canonization_elapsed / total_elapsed, 3) as canonize_time_pct,
       ROUND(100 * tokenization_elapsed / total_elapsed, 3) as tokenize_time_pct,
       ROUND(100 * result_lookup_elapsed / total_elapsed, 3) as resut_lookup_time_pct
  from elapsed_seconds
 order by 1 ;
 

select distinct pta.predictive_token, pta.inverse_document_frequency, pta.job_title
       --count(*), count(distinct assignment_id), count(distinct job_title)
  from token_gtt tt,
       predictive_tokens_and_assignments pta
 where tt.token = pta.predictive_token
-- group by pta.predictive_token, inverse_document_frequency
-- order by 2 desc;
 order by 3;

  with token_title
    as (select distinct pta.predictive_token, pta.inverse_document_frequency, pta.job_title
          from token_gtt tt,
               predictive_tokens_and_assignments pta
         where tt.token = pta.predictive_token)
select json_object('predictedJobTitle' VALUE job_title,
                   'score'             VALUE score,
                   'sharedTokenCount'  VALUE shared_tokens
                FORMAT JSON) as json_out
  from (select job_title, 
               count(*) as shared_tokens, 
               sum(inverse_document_frequency) as score
          from token_title
         group by job_title
         order by 3 desc
         fetch first 5 rows only);

  with token_title
    as (select distinct pta.predictive_token, pta.inverse_document_frequency, pta.job_title
          from token_gtt tt,
               predictive_tokens_and_assignments pta
         where tt.token = pta.predictive_token)
select json_arrayagg(json_object('predictedJobTitle' VALUE job_title,
                   'score'             VALUE score,
                   'sharedTokenCount'  VALUE shared_tokens
                FORMAT JSON)) as json_out
  from (select job_title, 
               count(*) as shared_tokens, 
               sum(inverse_document_frequency) as score
          from token_title
         group by job_title
         order by 3 desc
         fetch first 5 rows only);

-- build out combo of  predictive token-level and document-level
CREATE TABLE predictive_tokens_and_assignments
as
select pt.token as predictive_token, --pt.inverse_document_frequency, 
       a.assignment_id, a.job_title
  from job_description_predictive_token pt,
       job_description_document_token dt,
       assignment a
 where pt.token = dt.token
   and dt.assignment_id = a.assignment_id
 order by 1;  
--   and pt.token = 'ORACLE'
   ;
-- 14,942,190 rows!
select blocks * 8 / (1024*1024) as gb from useR_segments where segment_name like 'PREDICT%';

