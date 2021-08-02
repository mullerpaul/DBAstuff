-- Allow longer text in the metric_name column.  Going from 30 to 40.
ALTER TABLE metric MODIFY (metric_name VARCHAR2(40))
/

