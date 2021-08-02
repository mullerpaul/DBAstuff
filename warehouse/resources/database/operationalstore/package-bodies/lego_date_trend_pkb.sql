CREATE OR REPLACE PACKAGE BODY lego_date_trend
AS

 gc_logging_source                CONSTANT VARCHAR2(27) := 'LEGO_DATE_TREND';

 ------------------------------------------------------------------------------------  
    -- populate_dts_by_month
    -- 
    -- Input:  Start and end dates
    -- Inserts the dates into dts_by_month if date is not present.
    -- If date is present in the table,  columns yr, mo, day are inserted
    --
	-- Removed user defined dates and used auotmated version using hard coded start date 
	-- and end date based on sysdate + 3 years - we don't want to have a person updating this
	-- but rather every time it runs check the date and populate out into the future. 

    PROCEDURE populate_dts_by_month (
   pi_object_name   IN operationalstore.lego_object.object_name%TYPE,
   pi_source        IN operationalstore.lego_object.source_name%TYPE
  ) IS
    
       lc_proc_name   VARCHAR2(30) := 'populate_dts_by_month';
       lc_user        VARCHAR2(30);
       ln_count       PLS_INTEGER;
       ln_table_count PLS_INTEGER;
       lc_sql         VARCHAR2(4000) := NULL; 
       ln_column_count PLS_INTEGER;
	               ln_newdate_flag PLS_INTEGER;
	               ln_day_flag PLS_INTEGER;
	               ln_mo_flag PLS_INTEGER;
	               ln_yr_flag PLS_INTEGER;
		-- check start and end dates: Both in 'YYYY-MM-DD' format
		in_start_date VARCHAR2(10) := '1995-01-01'; 
		in_end_date VARCHAR2(10) := TO_CHAR(TRUNC(sysdate+(365*3), 'YEAR'), 'YYYY-MM-DD');
    
    BEGIN
       
        logger_pkg.set_source(gc_logging_source);
        logger_pkg.set_code_location(lc_proc_name);       
        logger_pkg.info('Check current user.', TRUE);
       
        SELECT user 
          INTO lc_user
          FROM dual;
       
        logger_pkg.info('Check if table DTS_BY_MONTH exists and is defined correctly', TRUE);       
       
	SELECT COUNT(*)           AS column_count, 
	       SUM(newdate_count) AS newdate_flag, 
	       SUM(day_count)     AS day_flag, 
	       SUM(mo_count)      AS mo_flag, 
	       SUM(yr_count)      AS yr_flag
	  INTO 
	       ln_column_count,
	       ln_newdate_flag,
	       ln_day_flag,
	       ln_mo_flag,
	       ln_yr_flag
	 FROM (
	        SELECT
	              CASE WHEN tab_newdate.column_name = 'NEWDATE' 
	                    AND tab_newdate.data_type   = 'DATE' 
	                 -- AND tab_newdate.data_length = 7 
	                   THEN 1 
	                   ELSE 0
	                   END 
	               AS newdate_count,
	              --	        
	              CASE  WHEN tab_newdate.column_name = 'DAY' 
	                     AND tab_newdate.data_type   = 'NUMBER' 
	                     AND tab_newdate.data_length >= 2 
	                    THEN 1 
	                    ELSE 0
	                    END  
	                 AS day_count,
	              --	        
	              CASE WHEN tab_newdate.column_name = 'MO' 
	                    AND tab_newdate.data_type   = 'NUMBER' 
	                    AND tab_newdate.data_length >= 2
	                   THEN 1 
	                   ELSE 0
	                   END  
	                AS mo_count,
	              --
	              CASE WHEN tab_newdate.column_name = 'YR' 
	                    AND tab_newdate.data_type   = 'NUMBER' 
	                    AND tab_newdate.data_length >= 4 
	                   THEN 1 
	                   ELSE 0
	                   END  
	                AS yr_count
	        FROM 
	              all_tab_columns  tab_newdate
	       WHERE  tab_newdate.owner       = lc_user
	         AND  tab_newdate.table_name  = 'DTS_BY_MONTH'
              );
               
              -- Either table doesn't exist, or column parameters are incorrect
              --
             
        --1: Table exists, has 4 columns but one or more columns is absent or incorrectly defined 
        --2: Table exists, has <4 columns 
        --2: Table exists, has > 4 columns 
        --3: Table doesn't exist
      
        IF NOT(     ln_column_count = 4 
                AND ln_newdate_flag = 1 
                AND ln_day_flag     = 1 
                AND ln_mo_flag      = 1 
                AND ln_yr_flag      = 1 
               )
        THEN
             -- Table exists, so drop it before recreating
             IF (ln_column_count <> 0)
             THEN                 
                 logger_pkg.info('DROP table DTS_BY_MONTH');
                 EXECUTE IMMEDIATE ('DROP TABLE ' || lc_user || '.DTS_BY_MONTH');
                 logger_pkg.info('DTS_BY_MONTH dropped', TRUE);
             END IF;
        
             -- Create table
             logger_pkg.info('Create table DTS_BY_MONTH');
             EXECUTE IMMEDIATE ('CREATE TABLE ' || lc_user ||
                                 '.DTS_BY_MONTH (YR NUMBER,MO NUMBER,DAY NUMBER,NEWDATE DATE)');
             logger_pkg.info('DTS_BY_MONTH created', TRUE);
        END IF;
     
    
       logger_pkg.info('MERGE INTO operationalstore.dts_by_month target - BEGIN', TRUE);

       lc_sql :=
             'MERGE INTO operationalstore.dts_by_month target '  || 
           ' USING ( WITH '  || 
           '         boundaries AS ( '  || 
                                 -- select date '2000-01-01' start_date,date '2020-12-31' end_date from dual)
                                 -- Above statement is not PL/SQL compatible 
           -- 
           '                         SELECT TO_DATE(''' || in_start_date || ''', ''YYYY-MM-DD'') AS start_date, '  || 
           '                                TO_DATE(''' || in_end_date   || ''', ''YYYY-MM-DD'') AS end_date  '  || 
           '                           FROM dual '  || 
           '                       ),   '  || 
           --
           '         dates     AS ( '  || 
           '                         SELECT ADD_MONTHS(TRUNC(start_date,''mm''),LEVEL - 1) AS newdate '  || 
           '                           FROM boundaries '  || 
           '                        CONNECT BY TRUNC(end_date,''mm'') >= ADD_MONTHS(TRUNC(start_date,''mm''),LEVEL - 1) '  || 
           '                      )  '  || 
           -- 
           '        SELECT TO_CHAR(newdate,''yyyy'') year, '  || 
           '               TO_CHAR(newdate,''mm'')   month, '  || 
           '               TO_CHAR(newdate,''dd'')   day, '  || 
           '               newdate '  || 
           '          FROM dates )  source    '  || 
           ' ON ( source.newdate = target.newdate   ) '  || 
           ' WHEN MATCHED THEN  '  || 
           '       UPDATE SET target.yr  = source.year, '  || 
           '                  target.mo  = source.month, '  || 
           '                  target.day = source.day '  || 
           '            WHERE target.yr <> source.year or '  || 
           '                  target.mo <> source.month or '  || 
           '                  target.day<> source.day '  || 
           ' WHEN NOT MATCHED THEN '  || 
           '                INSERT (target.yr,  '  || 
           '                        target.mo,  '  || 
           '                        target.day,  '  || 
           '                        target.newdate) '  || 
           '                VALUES (source.year,  '  || 
           '                        source.month,  '  || 
           '                        source.day,  '  || 
           '                        source.newdate) ' ;
                              
        EXECUTE IMMEDIATE (lc_sql);                       
       
        COMMIT;
             
              
        logger_pkg.info('MERGE INTO operationalstore.dts_by_month target - COMPLETE' );
        logger_pkg.unset_source(gc_logging_source);

    EXCEPTION
        WHEN OTHERS THEN
            logger_pkg.fatal(
                pi_transaction_result   => NULL,
                pi_error_code           => SQLCODE,
                pi_message              => SQLERRM
            );

            logger_pkg.unset_source(gc_logging_source);
            RAISE;
    
    
    END populate_dts_by_month;
END;
/

