drop table paul_points;
create table paul_points
  (x            number not null,
   y            number not null,
   generator_id number not null)
/

 
	   
DECLARE
    generator_count        CONSTANT NUMBER := 5;
    points_per_generator   CONSTANT NUMBER := 100;
    tau                    CONSTANT NUMBER := 6.283; -- 2*PI
    gen_x                  NUMBER;
    gen_y                  NUMBER;
    theta                  NUMBER;
    distance               NUMBER;

BEGIN
    FOR generator IN 1..generator_count LOOP
        gen_x := dbms_random.value(low => 6,high => 14);
        gen_y := dbms_random.value(low => 6,high => 14);

        FOR i IN 1..points_per_generator LOOP
            theta := tau * dbms_random.value;    -- angle in radians - uniform distribution between 0 and 2*pi
            distance := 4 * dbms_random.normal;  -- distance from center - standard distribution around 0, STDDEV = 4
            INSERT INTO paul_points (
                x,
                y,
                generator_id
            ) VALUES (
                gen_x + distance * sin(theta),
                gen_y + distance * cos(theta),
                generator
            );

        END LOOP;
    END LOOP;

    COMMIT;
END;
/

select round(x, 3) as x, round(y, 3) as y, generator_id 
  from paul_points 
 where 1=1
--   and not (x < 0 or y < 0 or x > 20 or y > 20)
 order by generator_id;

--- possible pure-SQL solution.  (untested)
INSERT INTO paul_points
  WITH constants
    as (select 5 as generator_count,
               100 as points_per_generator
               6.283 as tau
          from dual),
       generators
    as (select level as generator_id, 
	           dbms_random.value(low => 6,high => 14) as gen_x,
			   dbms_random.value(low => 6,high => 14) as gen_y
	      from constants
	   connect by level <= generator_count),
	   point_counter
	as (select level as point_id
	      from constants
	   connect by level <= points_per_generator)
SELECT g.gen_x + 4 * dbms_random.normal * sin(c.tau * dbms_random.value) as x, 
       g.gen_y + 4 * dbms_random.normal * cos(c.tau * dbms_random.value) as y, 
	   g.generator_id as generator_id
  from generators g,
       point_counter p,
	   constants c;  
