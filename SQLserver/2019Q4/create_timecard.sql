create table timecard
  (client_id         uniqueidentifier  not null,
   timecard_id       uniqueidentifier  not null,
   create_timestamp  datetime2         not null,
   job_id            uniqueidentifier,
   status            varchar(12),
   client_name       varchar(50),
   work_location     varchar(100),
   contractor_name   varchar(60)
  );
