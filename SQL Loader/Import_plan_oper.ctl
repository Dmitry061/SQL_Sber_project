--OPTIONS (SKIP=1)
LOAD DATA
CHARACTERSET UTF8
INFILE './CSV/plan_oper.csv'
BADFILE 'plan_oper.bad'
DISCARDFILE 'plan_oper.dsc'
INSERT
INTO TABLE plan_oper
FIELDS TERMINATED BY ';'
TRAILING NULLCOLS
(
ID "plan_oper_seq.nextval",
collection_id "TO_NUMBER(TRIM(:ID), '9999999999999')",
p_date "TO_DATE(TRIM(:collection_id), 'dd.mm.yyyy')",
p_summa "TO_NUMBER(REPLACE(TRIM(:p_date), ',', '.'), '9999999.99')",
type_oper "CAST(TRIM(:p_summa) AS varchar2(100))"
)