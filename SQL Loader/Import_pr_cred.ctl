--OPTIONS (SKIP=1)
LOAD DATA
CHARACTERSET UTF8
INFILE './CSV/pr_cred.csv'
BADFILE 'pr_cred.bad'
DISCARDFILE 'pr_cred.dsc'
INSERT
INTO TABLE pr_cred
FIELDS TERMINATED BY ';'
TRAILING NULLCOLS
(
ID "pr_cred_seq.nextval",
OLD_ID "TO_NUMBER(TRIM(:ID), '9999999999999')",
num_dog "CAST(TRIM(:OLD_ID) AS varchar2(100))",
summa_dog "TO_NUMBER(REPLACE(TRIM(:num_dog), ',', '.'), '9999999.99')",
date_begin "TO_DATE(TRIM(:summa_dog), 'dd.mm.yyyy')",
date_end "TO_DATE(TRIM(:date_begin), 'dd.mm.yyyy')",
id_client "TO_NUMBER(TRIM(:date_end), '9999999999999')",
collect_plan "TO_NUMBER(TRIM(:id_client), '9999999999999')",
collect_fact "TO_NUMBER(TRIM(:collect_plan), '9999999999999')"
)