UPDATE lego_refresh
   SET storage_clause = REPLACE(REPLACE(REPLACE(storage_clause,
                                                'STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH'),
                                        'STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY LOW'),
                                'STORAGE (CELL_FLASH_CACHE KEEP)')
 WHERE storage_clause LIKE '%STORAGE (CELL_FLASH_CACHE KEEP)%'
/

COMMIT
/

