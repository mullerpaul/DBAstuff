 --- numeric vs decimal vs float
drop table datatype_test;
create table datatype_test
 (id int,
  c_numeric numeric,
  c_decimal decimal,
  c_float   float,
  c_real    real);

insert into datatype_test (id, c_numeric, c_decimal, c_float, c_real) values (1, 1,1,1,1);
insert into datatype_test (id, c_numeric, c_decimal, c_float, c_real) values (2, 1.0,1.0,1.0,1.0);
insert into datatype_test (id, c_numeric, c_decimal, c_float, c_real) values (3, 1.5,1.5,1.5,1.5);
insert into datatype_test (id, c_numeric, c_decimal, c_float, c_real) values (4, 0.5,0.5,0.5,0.5);

select * from datatype_test;  -- what good is "decimal" if it doesn't store fractional values?!?!?
-- just found this in the doc: Decimal and numeric are synonyms and can be used interchangeably.



