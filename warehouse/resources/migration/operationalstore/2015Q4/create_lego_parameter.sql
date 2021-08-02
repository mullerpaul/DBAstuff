CREATE TABLE lego_parameter
 (parameter_name        VARCHAR2(40),
  number_value          NUMBER,
  text_value            VARCHAR2(40),
  date_value            DATE,
  parameter_description VARCHAR2(2000))
/

ALTER TABLE lego_parameter
ADD CONSTRAINT lego_parameter_pk
PRIMARY KEY (parameter_name)
/

ALTER TABLE lego_parameter
ADD CONSTRAINT lego_parameter_values_ck
CHECK ((number_value IS NOT NULL AND text_value IS NULL     AND date_value IS NULL)
    OR (number_value IS NULL     AND text_value IS NOT NULL AND date_value IS NULL)
    OR (number_value IS NULL     AND text_value IS NULL     AND date_value IS NOT NULL))
/

