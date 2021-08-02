--- make and load a table to hold 50 reference locations
create table fake_job_locations
 (id            int,
  location_name varchar(100));

BEGIN TRANSACTION;
INSERT INTO fake_job_locations (id, location_name) VALUES (1, 'New York, New York');
INSERT INTO fake_job_locations (id, location_name) VALUES (2, 'Los Angeles, California');
INSERT INTO fake_job_locations (id, location_name) VALUES (3, 'Chicago, Illinois');
INSERT INTO fake_job_locations (id, location_name) VALUES (4, 'Houston, Texas');
INSERT INTO fake_job_locations (id, location_name) VALUES (5, 'Phoenix, Arizona');
INSERT INTO fake_job_locations (id, location_name) VALUES (6, 'Philadelphia, Pennsylvania');
INSERT INTO fake_job_locations (id, location_name) VALUES (7, 'San Antonio, Texas');
INSERT INTO fake_job_locations (id, location_name) VALUES (8, 'San Diego, California');
INSERT INTO fake_job_locations (id, location_name) VALUES (9, 'Dallas, Texas');
INSERT INTO fake_job_locations (id, location_name) VALUES (10, 'San Jose, California');
INSERT INTO fake_job_locations (id, location_name) VALUES (11, 'Austin, Texas');
INSERT INTO fake_job_locations (id, location_name) VALUES (12, 'Jacksonville, Florida');
INSERT INTO fake_job_locations (id, location_name) VALUES (13, 'Fort Worth, Texas');
INSERT INTO fake_job_locations (id, location_name) VALUES (14, 'Columbus, Ohio');
INSERT INTO fake_job_locations (id, location_name) VALUES (15, 'San Francisco, California');
INSERT INTO fake_job_locations (id, location_name) VALUES (16, 'Charlotte, North Carolina');
INSERT INTO fake_job_locations (id, location_name) VALUES (17, 'Indianapolis, Indiana');
INSERT INTO fake_job_locations (id, location_name) VALUES (18, 'Seattle, Washington');
INSERT INTO fake_job_locations (id, location_name) VALUES (19, 'Denver, Colorado');
INSERT INTO fake_job_locations (id, location_name) VALUES (20, 'Washington, District of Columbia');
INSERT INTO fake_job_locations (id, location_name) VALUES (21, 'Boston, Massachusetts');
INSERT INTO fake_job_locations (id, location_name) VALUES (22, 'El Paso, Texas');
INSERT INTO fake_job_locations (id, location_name) VALUES (23, 'Detroit, Michigan');
INSERT INTO fake_job_locations (id, location_name) VALUES (24, 'Nashville, Tennessee');
INSERT INTO fake_job_locations (id, location_name) VALUES (25, 'Portland, Oregon');
INSERT INTO fake_job_locations (id, location_name) VALUES (26, 'Memphis, Tennessee');
INSERT INTO fake_job_locations (id, location_name) VALUES (27, 'Oklahoma City, Oklahoma');
INSERT INTO fake_job_locations (id, location_name) VALUES (28, 'Las Vegas, Nevada');
INSERT INTO fake_job_locations (id, location_name) VALUES (29, 'Louisville, Kentucky');
INSERT INTO fake_job_locations (id, location_name) VALUES (30, 'Baltimore, Maryland');
INSERT INTO fake_job_locations (id, location_name) VALUES (31, 'Milwaukee, Wisconsin');
INSERT INTO fake_job_locations (id, location_name) VALUES (32, 'Albuquerque, New Mexico');
INSERT INTO fake_job_locations (id, location_name) VALUES (33, 'Tucson, Arizona');
INSERT INTO fake_job_locations (id, location_name) VALUES (34, 'Fresno, California');
INSERT INTO fake_job_locations (id, location_name) VALUES (35, 'Mesa, Arizona');
INSERT INTO fake_job_locations (id, location_name) VALUES (36, 'Sacramento, California');
INSERT INTO fake_job_locations (id, location_name) VALUES (37, 'Atlanta, Georgia');
INSERT INTO fake_job_locations (id, location_name) VALUES (38, 'Kansas City, Missouri');
INSERT INTO fake_job_locations (id, location_name) VALUES (39, 'Colorado Springs, Colorado');
INSERT INTO fake_job_locations (id, location_name) VALUES (40, 'Miami, Florida');
INSERT INTO fake_job_locations (id, location_name) VALUES (41, 'Raleigh, North Carolina');
INSERT INTO fake_job_locations (id, location_name) VALUES (42, 'Omaha, Nebraska');
INSERT INTO fake_job_locations (id, location_name) VALUES (43, 'Long Beach, California');
INSERT INTO fake_job_locations (id, location_name) VALUES (44, 'Virginia Beach, Virginia');
INSERT INTO fake_job_locations (id, location_name) VALUES (45, 'Oakland, California');
INSERT INTO fake_job_locations (id, location_name) VALUES (46, 'Minneapolis, Minnesota');
INSERT INTO fake_job_locations (id, location_name) VALUES (47, 'Tulsa, Oklahoma');
INSERT INTO fake_job_locations (id, location_name) VALUES (48, 'Arlington, Texas');
INSERT INTO fake_job_locations (id, location_name) VALUES (49, 'Tampa, Florida');
INSERT INTO fake_job_locations (id, location_name) VALUES (50, 'New Orleans, Louisiana');
COMMIT TRANSACTION;

