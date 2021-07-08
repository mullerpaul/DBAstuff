BEGIN TRAN  
SELECT ClientName FROM analytics.DimClient WITH (TABLOCKX)  --any available table 
WAITFOR DELAY '00:02:00' 
ROLLBACK TRAN   
GO 
