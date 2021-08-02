select * from gv$sql
 where 1=1
--   and executions > 1000000   -- find ones run A LOT
   -- now ones that are run only a few times (or once)
   and executions < 5 
--   and sql_text like '%CAC%' 
--   and sql_text not like '%CACHE%' 
--   and sql_text not like 'SELECT DISTINCT IDENTIFIER, IS_DELETED, VERSION, VALUE, DESCRIPTION, SEGMENT_FK, IS_VALID, OWNING_BUYER_FIRM_FK FROM CAC_VALUE WHERE%'
 order by executions; --desc;

-- we obviouisly have a few problem places in code where we are creating individual SQLs with concatinate 
-- instead of using prepared & bound statements.  
---finding non-bound SQL

-- this one has 4200 copies in the shared pool!!!!
select * from gv$sql 
 where 1=1
--   and sql_text like 'select get_number_available_positions(%) NUM_POS from dual'  -- 5000-6000 copies  IQN-42325
--   and sql_text like 'select count(*)%from job%firm_role%bus_org_lineage%' --1400 copies !!  IQN-42339
;

-- lets get a more systematic way to find these. 
DROP table paul_find_non_bound_sql PURGE;
create  table paul_find_non_bound_sql
 as 
select sql_id, sql_text --, sql_fulltext, CAST (NULL as varchar2(4000)) as sql_without_constants
  from gv$sql
 where EXECUTIONS < 3
;

SELECT COUNT(*) from paul_find_non_bound_sql;  --34K


--now analyze the first (say) 60 chars and group by them
select substr(sql_text,1,80) as sql_header, count(*)
  from paul_find_non_bound_sql
 group by substr(sql_text,1,80)
 order by 2 desc;
-- the results are pretty different from 60 to 40.  Perhaps look into 40 later. 

-- lets look at some specific ones
select *  --count(*) 
  from paul_find_non_bound_sql
 where 1=1
--   and sql_text like 'SELECT RR.report_run_sys_id,RR.job_owner,RR.file_output_type%'  --FO?  scheduled report list page?
--   and sql_text like 'SELECT DISTINCT t1.EVALUATION_ID, t1.IS_SKIPPED, t1.SUBMISSI%'  -- FO evaluation list page
--   and sql_text like 'SELECT DISTINCT IDENTIFIER, IS_DELETED, VERSION, VALUE, DESC%'  --cac info lookup.  reporting?  FO?
--   and sql_text like 'SELECT COUNT(*) AS COUNT FROM REPORT_RUN RR JOIN REPORT_REQU%'   --report scheduler?
--   and sql_text like 'select count(*) as MATCHCOUNT from match m, candidate c, job%'  -- maybe a FO page showing # of matches?? IQN-42339 --IQN-42400
--   and sql_text like 'SELECT DISTINCT ieo.assignment_continuity_fk, ieo.project_ag%'  --invoicing somewhere  MSVC-4788
--   and sql_text like 'SELECT DISTINCT t0.PERSON_ID, t0.IS_MSP_USER, t0.VERSION, t0%'  -- FO person search results
--   and sql_text like 'SELECT listagg(value, '';'') WITHIN GROUP (ORDER BY identifier%'  -- this is the one I fixed in IQN-42082
--   and sql_text like 'select get_number_available_positions(%'  -- from IQPROD DB function - display # of positions  IQN-42325
--   and sql_text like 'SELECT sum(spend_amt) spend_amt FROM assignment_spend WHERE%'  -- fo-domain - work order summary and invoice - IQN-42399
--   and sql_text like 'select  count(distinct decode(ae.ASSIGNMENT_STATE_FK,13, ac.%'  --IQN-42400
--   and sql_text like 'SELECT assignment_continuity_id, sum%'  -- just fixed from hundreds to 12.  Better than before, but not perfect. IQN-42399
--   and sql_text like '%listagg(%'';'')%'  -- this is the one I allegedly fixed in IQN-42082 - why is it still here after Feb 22 release?  filed IQN-43473
--   and sql_text like '%listagg(description, '';'')%'  -- this is the one I allegedly fixed in IQN-42082 - why is it still here after Feb 22 release?  -- fix in prod 19.03!
   
;


-- I should figure out what is issuing those and then file tickets
 
-- For ones where we don't see literals in the sql_text column we'll have to go back to SQL_full_text
select * from gv$sql where sql_id = '1wzmmp9du40zq' --'46cyb19zdn1hd' --'0nbsdnqgj409g' --'a2x93rpza4c7g'  -- random choice of one of the rows
;

select hextoraw('1C392FD9621042D3E0530A62CA0AC690'),
       hextoraw('1c392fd9621042D3e0530A62ca0ac690')
from dual;

--- look at the text of "current-ish" SQL 
select count(*) as total_count, count(CASE WHEN sql_text like '%is_flexrate%' then 'x' END) as IN_count
  from gv$sql 
 where 1=1
--   and sql_text like 'SELECT DISTINCT ieo.assignment_continuity_fk, ieo.project_a%'
   and sql_text like 'SELECT%sum(spend_amt)%WHERE %assignment_continuity_id IN%'
--   and executions / NULLIF(parse_calls,0) > 1000  -- show SQL where the execute to parse ratio is high
;


SELECT DISTINCT ieo.assignment_continuity_fk, ieo.project_agreement_fk FROM invoiceable_expenditure_owner ieo, invoiceable_expenditure ie, invoiceable_expenditure_txn iet WHERE iet.fo_invoiceable_event_fk = 73475762 AND iet.invoiceable_expenditure_fk = ie.invoiceable_expenditure_id AND ie.invoiceable_exp_owner_fk = ieo.invoiceable_exp_owner_id


--- try a slightly different approach - using Tom Kyte's procedure to remove string literals from SQL
CREATE OR REPLACE FUNCTION paul_remove_constants (
    p_query IN VARCHAR2
) RETURN VARCHAR2 AS
    l_query       CLOB;  --VARCHAR2(4000);  --LONG;
    l_char        VARCHAR2(1);
    l_in_quotes   BOOLEAN DEFAULT false;
BEGIN
    FOR i IN 1..length(p_query) LOOP
        l_char := substr(p_query, i, 1);
        IF ( l_char = '''' AND l_in_quotes ) THEN
            l_in_quotes := false;
        ELSIF ( l_char = '''' AND NOT l_in_quotes ) THEN
            l_in_quotes := true;
            l_query := l_query || '''#';
        END IF;

        IF ( NOT l_in_quotes ) THEN
            l_query := l_query || l_char;
        END IF;
    END LOOP;

    l_query := translate(l_query, '0123456789', '@@@@@@@@@@');
    FOR i IN 0..8 LOOP
        l_query := replace(l_query, lpad('@', 10 - i, '@'), '@');
        l_query := replace(l_query, lpad(' ', 10 - i, ' '), ' ');

    END LOOP;

    RETURN upper(substr(l_query,1,3000));
END;
/

--- i haven't been able to get this to work, plus that update below is very resource intensive...
DROP table paul_find_non_bound_sql PURGE;
create table paul_find_non_bound_sql as select sql_text from v$sqlarea;

alter table paul_find_non_bound_sql add sql_text_wo_constants varchar2(4000);
alter table paul_find_non_bound_sql add (row_sample_id number);

update  paul_find_non_bound_sql set row_sample_id = mod(rownum,3);  --only update a sample of the SQLs in shared pool

update paul_find_non_bound_sql
   set sql_text_wo_constants = paul_remove_constants(substr(sql_text,1,2400))
 where row_sample_id =1 -- only update one third of rows.   Thats probably enough for a good analysis  and should cut the time down to 3-4 min.
  ;
commit; 

select count(*),count(sql_text_wo_constants) from paul_find_non_bound_sql;

drop function paul_remove_constants;


---- how can we determine if all these tickets are helping???
select count(*) from gv$sqlarea;  --66K

-- of course, even if we eliminate tens of thousands of statments from the sql area, the database will use that space for 
-- OTHER statements which are being very quickly aged out today.  So we can't go by a count of statements...
-- I guess the REAL metric is the DB-wide ratio of hard parses to executes - or the cache-hit ratio.
-- we can see a per-session display of this in the "top sessions" page when ordered by hard parses.
-- but to get a DB-wide count, we can use a query like this:
  WITH data
    AS (SELECT inst_id, namespace,
               gets, gethits,
               pins, pinhits
          FROM gv$librarycache
         WHERE ( namespace = 'TABLE/PROCEDURE'  OR namespace LIKE 'SQL%' )
       )
SELECT round(100 * sum(gethits)/sum(gets), 4) AS get_hit_percent,
       round(100 * sum(pinhits)/sum(pins), 4) AS pin_hit_percent
  FROM data;
-- as of today - Feb 5th - we have 95.8% and 101.67%
-- I don't know what the deal is with pin_hit_percent being greater than 100.  

--  Also, it would be important to know the DB uptime.  These ratios don't mean much 
--  until after the DB has been running for "a while".

  


--- I can't find the 'SELECT DISTINCT IDENTIFIER, IS_DELETED, VERSION, VALUE, DESCRIPTION, SEGMENT_FK, IS_VALID, OWNING_BUYER_FIRM_FK FROM CAC_VALUE WHERE ((VALUE = '1723781') AND (((IS_DELETED = 0) AND (IS_VALID = 1)) AND ((SEGMENT_FK = 26316) OR ((OWNING_BUYER_FIRM_FK IS NOT NULL) AND (SEGMENT_FK = 26314))))) ORDER BY VALUE ASC'
--- perhaps its created by toplink?
--- or lets look in database code in production.

-----
SELECT DISTINCT IDENTIFIER, IS_DELETED, VERSION, VALUE, DESCRIPTION, SEGMENT_FK, IS_VALID, OWNING_BUYER_FIRM_FK 
  FROM CAC_VALUE 
 WHERE ((VALUE = '1101') AND (((IS_DELETED = 0) AND (IS_VALID = 1)) AND ((SEGMENT_FK = 47859) OR ((OWNING_BUYER_FIRM_FK IS NOT NULL) AND (SEGMENT_FK = 47858))))) 
 ORDER BY VALUE ASC
-----
SELECT DISTINCT IDENTIFIER, IS_DELETED, VERSION, VALUE, DESCRIPTION, SEGMENT_FK, IS_VALID, OWNING_BUYER_FIRM_FK 
  FROM CAC_VALUE 
 WHERE ((VALUE = '1729457') AND ((SEGMENT_FK = 26316) OR ((OWNING_BUYER_FIRM_FK IS NOT NULL) AND (SEGMENT_FK = 26314)))) 
 ORDER BY IS_DELETED ASC, IS_VALID DESC, VALUE ASC
-----
SELECT DISTINCT IDENTIFIER, IS_DELETED, VERSION, VALUE, DESCRIPTION, SEGMENT_FK, IS_VALID, OWNING_BUYER_FIRM_FK 
  FROM CAC_VALUE 
 WHERE ((VALUE = 'Not Applicable') AND ((SEGMENT_FK = 31142) OR ((OWNING_BUYER_FIRM_FK IS NOT NULL) AND (SEGMENT_FK = 31150)))) 
 ORDER BY IS_DELETED ASC, IS_VALID DESC, VALUE ASC
-----
;
select * from dba_dependencies 
 where referenced_name = 'CAC_VALUE'
   and type not in ('VIEW','SYNONYM','MATERIALIZED VIEW')
 order by owner, type, name  ;

  with object_list
    as (select owner, name, type
          from dba_dependencies 
         where referenced_name = 'CAC_VALUE'
           and type not in ('VIEW','SYNONYM','MATERIALIZED VIEW')
       )
select S.* --distinct s.owner, s.type, s.name
  from dba_source s,
       object_list l
 where s.owner = l.owner 
   and s.type = l.type
   and s.name = l.name
--   and s.text like '%FROM%CAC_VALUE%'  --relying on the CASE of text in the SQL and the FROM clause being one line
--   and s.text like '%IDENTIFIER,%' --, IS_DELETED%'
--   and s.text like '%IS_DELETED ASC, IS_VALID DESC, VALUE%'  --order by clause
--   and s.text like '%IS_DELETED%'  --order by clause
   and upper(s.text) like '%IS_DELETED%'  --order by clause
 order by s.owner, s.name, s.line
-- order by 1,2,3
 ;
 
-- I really don't think its in the DB.
-- "issued from toplink" is now my #1 theory.
 
 
 select * from dbA_source where 1=0;

---- why do we still have queries like:
-- 'SELECT listagg(value, ';') WITHIN GROUP (ORDER BY identifier asc)           FROM  cac_value        WHERE  identifier in  ( select regexp_substr( '8694141','[^,]+', 1, level) from dual          connect by regexp_substr( '8694141', '[^,]+', 1, level) is not null ) '
-- even after the 19.02 release??
-- look for where that might be coming from

select * from dba_source
where owner = 'IQPRODR'
and name ='RPT_UTIL_CAC'
and type <> 'PACKAGE';
