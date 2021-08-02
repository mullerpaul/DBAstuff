--IQN-37732
--05/30/2017
--Joe Pullifrone
--Remove compress at the request of DBA team to be in compliance for licensing with Oracle

ALTER TABLE dm_date_dim MOVE NOCOMPRESS
/