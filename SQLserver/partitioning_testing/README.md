# Introduction 
Goals of this project:
- Understand our partition swap methodology by recreating it with very small tables hosted in a local DB.
- Simulate the three stpes in our PL_PROCUREMENT_REQUEST and PL_PROCUREMENT_REQUEST_PIPELINE pipelines: insert, swap, set cycle time metrics.
- Attempt to reproduce the same table locks as we occasionally see in produciton.


# How to use
1.  Have a SQL server DB available.  I'm using one in my local SQLserver install called paul_test
2.	Run the SQL in the setup directory in this order:
    1. PartitionFunction.sql
    2. PartitionScheme.sql
    3. tableCreates.sql
3.  Have a admin SQL window handy to run the SQL in examinePartitions.sql
4.  Open two command windows, one will be the "QA217" process amd the other will be "QA218"
5.  Use these sqlcmd commands to execute the SQL:

```
sqlcmd -S localhost -d paul_test -e -i insertQA217.sql
sqlcmd -S localhost -d paul_test -e -i partSwapQA217.sql
sqlcmd -S localhost -d paul_test -e -i updateQA217.sql

sqlcmd -S localhost -d paul_test -e -i insertQA218.sql
sqlcmd -S localhost -d paul_test -e -i partSwapQA218.sql
sqlcmd -S localhost -d paul_test -e -i updateQA218.sql
```
