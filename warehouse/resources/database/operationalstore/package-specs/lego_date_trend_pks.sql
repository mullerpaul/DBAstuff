create or replace package lego_date_trend AS

/* *****************************************************************************
   NAME:       lego_date_trend
   PURPOSE:    Universal Trending Table by Month for Ad Hoc Executive and Smartview 2.0 (Spotfire) Queries.

   REVISIONS:
   Jira       Date        Author                Description
   ---------  ----------  ---------------       ------------------------------------
   IQN-40224  09/17/2017  Hassina Majid         Created this package for original Smartview 1.0 Date Trending Requirements. 
   IQN-41440  10/15/2018  Sajni Kalichanda      Refactoring Procedured to not depend upon IQPRODM schema. 
                          & McKay Dunlap        (This was breaking in EMEA as the IQPRODM Schemas was not incomplete). 

   ***************************************************************************** */
   


  procedure populate_dts_by_month (
   pi_object_name   IN operationalstore.lego_object.object_name%TYPE,
   pi_source        IN operationalstore.lego_object.source_name%TYPE
  );
  
end;
/