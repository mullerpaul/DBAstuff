-- set the metric coefficients for each metric in a category to be the same.
-- the coefficients ACROSS categories may not be the same; but we want the
-- categories to have the same relative weight as each other.

-- Running this query:
--select metric_category, count(*) from metric group by metric_category;

-- Gives these results:
--   candidate quality	12
--   cost	4
--   efficiency	6

-- Picking each new coefficient so all categories have the same relative max value of 12 
-- (which is just an aribitrary value I picked since the numbers work out nicely)

UPDATE metric
   SET default_coefficient = CASE metric_category
                               WHEN 'candidate quality' THEN 12/12
                               WHEN 'cost' THEN 12/4
                               WHEN 'efficiency' THEN 12/6
                             END
/

COMMIT
/

