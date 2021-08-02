BEGIN
  lego_tools.refresh_mv(pi_mv_name => 'BUYER_INVD_ASSIGN_SPND_MON_MV',
                        pi_method  => 'COMPLETE');
END;
/

