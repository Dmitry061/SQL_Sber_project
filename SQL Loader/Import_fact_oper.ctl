--OPTIONS (SKIP=1)
LOAD DATA
CHARACTERSET UTF8
INFILE './CSV/fact_oper.csv'
BADFILE 'fact_oper.bad'
DISCARDFILE 'fact_oper.dsc'
INSERT
INTO TABLE fact_oper
FIELDS TERMINATED BY ';'
TRAILING NULLCOLS
(
ID "fact_oper_seq.nextval",
collection_id "TO_NUMBER(TRIM(:ID), '9999999999999')",
f_date "TO_DATE(TRIM(:collection_id), 'dd.mm.yyyy')",
f_summa "TO_NUMBER(REPLACE(TRIM(:f_date), ',', '.'), '9999999.99')",
type_oper "CAST(TRIM(:f_summa) AS varchar2(100))"
)