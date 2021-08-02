-- The new new default for this per-metric multiplier is 10.
  
-- Since clients have not entered anything of their own into this 
-- table yet, we are fine updating all client data to the new default.

UPDATE client_metric_coefficient
   SET metric_coefficient = 10
/
COMMIT
/
