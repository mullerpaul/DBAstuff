-- how many timecards per job??  lets make it 2 months worth.  make and load table
CREATE TABLE fake_timecard_week
  (week_id int,
   timecard_date datetime2);

begin transaction;
insert into fake_timecard_week (week_id, timecard_date) values (1, '20190805');
insert into fake_timecard_week (week_id, timecard_date) values (2, '20190812');
insert into fake_timecard_week (week_id, timecard_date) values (3, '20190819');
insert into fake_timecard_week (week_id, timecard_date) values (4, '20190826');
insert into fake_timecard_week (week_id, timecard_date) values (5, '20190902');
insert into fake_timecard_week (week_id, timecard_date) values (6, '20190909');
insert into fake_timecard_week (week_id, timecard_date) values (7, '20190916');
insert into fake_timecard_week (week_id, timecard_date) values (8, '20190923');
commit transaction;
