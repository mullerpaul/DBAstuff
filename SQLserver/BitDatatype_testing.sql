use dataedo;  --putting my junk here to not mess up cycle!

DROP TABLE paul_dropme_bit_testing;
CREATE TABLE paul_dropme_bit_testing
  (id             int,
   notes          varchar(100),
   Bit_column     bit,
   Varchar_column varchar(5));

--- inserting "correctly" 
insert into paul_dropme_bit_testing (id,notes,Bit_column,Varchar_column) values (1,'known good input - true',1,'true');
insert into paul_dropme_bit_testing (id,notes,Bit_column,Varchar_column) values (2,'known good input - false',0,'false');

--- inserting with lowercase text into bit - works!
insert into paul_dropme_bit_testing (id,notes,Bit_column,Varchar_column) values (3,'lowercase text input to bit - true','true','true');
insert into paul_dropme_bit_testing (id,notes,Bit_column,Varchar_column) values (4,'lowercase text input to bit - false','false','false');

--- inserting with uppercase text into bit - works!
insert into paul_dropme_bit_testing (id,notes,Bit_column,Varchar_column) values (5,'uppercase text input to bit - true','TRUE','TRUE');
insert into paul_dropme_bit_testing (id,notes,Bit_column,Varchar_column) values (6,'uppercase text input to bit - false','FALSE','FALSE');

-- inserting bit data into varchar - doesn't insert "true" or "false".  Inserts "0" or "1"
insert into paul_dropme_bit_testing (id,notes,Bit_column,Varchar_column) 
select 7 as id, 'bit data to varchar - true' as notes, CAST(1 as bit) as Bit_column, CAST(1 as bit) as Varchar_column;
insert into paul_dropme_bit_testing (id,notes,Bit_column,Varchar_column) 
select 8 as id, 'bit data to varchar - false' as notes, CAST(0 as bit) as Bit_column, CAST(0 as bit) as Varchar_column;

select * from paul_dropme_bit_testing;


-- FROM : https://docs.microsoft.com/en-us/sql/t-sql/data-types/bit-transact-sql?view=sql-server-ver15
--        "The string values TRUE and FALSE can be converted to bit values: TRUE is converted to 1 and FALSE is converted to 0."

--- does that work for reads too?  will string compares work on bit columns?
select * from paul_dropme_bit_testing where Bit_column = 'true';
--- returns 4 rows.  Works!

select * from paul_dropme_bit_testing where Bit_column = 'TRUE';
--- returns 4 rows.  Works!

select * from paul_dropme_bit_testing where Bit_column = 'TruE';
-- also for 4 rows

