SELECT d.tablespace_name,
       ROUND (NVL (a.bytes / (1024*1024), 0),2) as allocated_mb,
       ROUND (NVL (a.bytes - NVL (f.bytes, 0), 0) / (1024*1024),2) as used_mb,
       ROUND (NVL (f.bytes, 0) / (1024*1024),2) as free_mb,
       ROUND (NVL (100 * (a.bytes - NVL (f.bytes, 0)) / a.bytes, 0),1) as pct_used,
       a.extendable
FROM dba_tablespaces d,
    (SELECT tablespace_name, SUM(bytes) AS bytes,
            MAX(CASE WHEN (autoextensible = 'YES' AND bytes < maxbytes)
                     THEN 'Yes' ELSE NULL END) AS extendable
     FROM dba_data_files
     GROUP BY tablespace_name) a,
    (SELECT tablespace_name, SUM(bytes) AS bytes
     FROM dba_free_space
     GROUP BY tablespace_name) f
WHERE d.tablespace_name = a.tablespace_name(+)
AND d.tablespace_name = f.tablespace_name(+)
AND NOT (d.extent_management LIKE 'LOCAL' AND d.CONTENTS LIKE 'TEMPORARY')
-- AND ROUND (NVL (100 * (a.bytes - NVL (f.bytes, 0)) / a.bytes, 0),1) > 85
-- ORDER BY 4 DESC
ORDER by d.tablespace_name;
