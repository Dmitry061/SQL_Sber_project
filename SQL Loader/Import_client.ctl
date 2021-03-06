--OPTIONS (SKIP=1)
LOAD DATA
CHARACTERSET UTF8
INFILE './CSV/client.csv'
BADFILE 'client.bad'
DISCARDFILE 'client.dsc'
INSERT
INTO TABLE client
FIELDS TERMINATED BY ';'
TRAILING NULLCOLS
(
ID "client_seq.nextval",
OLD_ID "TO_NUMBER(:ID)",
CL_NAME "cast(:OLD_ID as varchar2(150))",
DATE_BIRTH "TO_DATE(TRIM(:CL_NAME), 'dd.mm.yyyy')"
)