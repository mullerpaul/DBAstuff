INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (1, 'Y', 'N', 'Y', 'Person')
/
INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (2, 'Y', 'N', 'Y', 'Slot security')
/
INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (3, 'Y', 'N', 'Y', 'Business Org')
/
INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (4, 'Y', 'N', 'Y', 'Currency conversion rates')
/
INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (5, 'Y', 'N', 'Y', 'Address')
/
INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (6, 'Y', 'N', 'Y', 'Cac Collection')
/
INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (7, 'Y', 'N', 'Y', 'Localization (java constant lookup)')
/
INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (8, 'N', 'N', 'Y', 'Job')
/
INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (9, 'N', 'N', 'Y', 'Ratecard')
/
INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (10, 'N', 'N', 'N', 'RFX')
/
INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (11, 'N', 'N', 'N', 'Assignments')
/
INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (12, 'N', 'N', 'Y', 'Match and Time to fill')
/
INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (13, 'N', 'N', 'Y', 'Evaluation')
/
INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (14, 'N', 'N', 'Y', 'Expense reports')
/
INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (15, 'N', 'N', 'Y', 'Supplier Scorecard')
/
INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (16, 'N', 'N', 'Y', 'Timecards')
/
INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (17, 'N', 'N', 'Y', 'CDFs on firstpass legos')  -- these could have been in the 1st pass groups with their parent legos; but we pulled them into this 2nd pass
/                                                      -- group since errors in 1st pass legos prevent 2nd pass from running and the fewer 1st pass legos the better.
INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (18, 'N', 'N', 'Y', 'Calendar')
/
INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (19, 'N', 'N', 'Y', 'Approvals')
/
INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (20, 'N', 'N', 'N', 'Project agreement')
/
INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (21, 'N', 'N', 'Y', 'Request to Buy')
/
INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (22, 'N', 'N', 'Y', 'Invoice')
/
INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (23, 'N', 'N', 'Y', 'PA change request')
/
INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (24, 'N', 'N', 'Y', 'Remittance')
/
INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (25, 'N', 'N', 'Y', 'Interview')
/
INSERT INTO lego_refresh_group 
(refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES (26, 'N', 'N', 'N', 'Candidate search')
/


COMMIT
/

