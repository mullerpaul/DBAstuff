-- we want db links pointing to ALL remote sources - UP prod, EMEA prod, and Wachovia prod 

CREATE DATABASE LINK fo_us_production
CONNECT TO iqprodd
IDENTIFIED BY IQPRODD
--USING 'IQPCO'
USING 'IQPD03'   --DEV db for now
/

CREATE DATABASE LINK fo_emea_production
CONNECT TO iqprodd
IDENTIFIED BY IQPRODD
USING 'FRKP'
/

CREATE DATABASE LINK fo_wf_production
CONNECT TO waprodd
IDENTIFIED BY WAPRODD
USING 'WAPCO'
/



