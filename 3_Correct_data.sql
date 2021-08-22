--нормализация таблиц
--нормализация таблицы type_oper

Create sequence P_TYPE_seq
Start with 1
increment by 1
NOCYCLE
CACHE 100;

CREATE TABLE P_TYPE
(
ID NUMBER PRIMARY KEY,
NAME VARCHAR2(200) NOT NULL,
OTHER_INFO VARCHAR2(500) NULL
);

--select * from P_TYPE

insert into P_TYPE(ID, NAME, OTHER_INFO)
with val as(
select 'Погашение кредита' as name from dual union all
select  'Погашение процентов'as name from dual union all
select  'Выдача кредита'as name from dual
)
select P_TYPE_seq.nextval, val.name, null from val;

COMMIT;

ALTER TABLE plan_oper
ADD P_TYPE_ID number;
--select * from plan_oper
update plan_oper
SET P_TYPE_ID = CASE TYPE_OPER
                  WHEN 'Погашение кредита' THEN (select id from P_TYPE where name = 'Погашение кредита')
                  WHEN 'Погашение процентов' THEN (select id from P_TYPE where name = 'Погашение процентов')
                  WHEN 'Выдача кредита' THEN (select id from P_TYPE where name = 'Выдача кредита')
                END;

ALTER TABLE plan_oper
DROP COLUMN TYPE_OPER;

ALTER TABLE plan_oper
ADD CONSTRAINT fk_P_TYPE_ID_plan_oper FOREIGN KEY (P_TYPE_ID) REFERENCES P_TYPE (ID);

--нормализация таблицы fact_oper

ALTER TABLE fact_oper
ADD P_TYPE_ID number;

update fact_oper
SET P_TYPE_ID = CASE TYPE_OPER
                  WHEN 'Погашение кредита' THEN (select id from P_TYPE where name = 'Погашение кредита')
                  WHEN 'Погашение процентов' THEN (select id from P_TYPE where name = 'Погашение процентов')
                  WHEN 'Выдача кредита' THEN (select id from P_TYPE where name = 'Выдача кредита')
                END;

ALTER TABLE fact_oper
DROP COLUMN TYPE_OPER;

ALTER TABLE fact_oper
ADD CONSTRAINT fk_P_TYPE_ID_fact_oper FOREIGN KEY (P_TYPE_ID) REFERENCES P_TYPE (ID); 
 
/*  
update pr_cred
set id_client = c.ID
from client
where client.old_id = pr_cred.id_client;
*/

--обновляем связь с client
update pr_cred
SET id_client = ( select c.id 
        from client c
        where c.old_id = pr_cred.id_client)
where id_client is not null;

ALTER TABLE client
DROP COLUMN old_id;

--обновляем связь с таблицей plan_oper
update plan_oper
SET collection_id = ( select pr.id 
        from pr_cred pr
        where pr.collect_plan = plan_oper.collection_id)
where collection_id is not null;

ALTER TABLE pr_cred
DROP COLUMN collect_plan;

--обновляем связь с таблицей fact_oper
update fact_oper
SET collection_id = ( select pr.id 
        from pr_cred pr
        where pr.collect_fact = fact_oper.collection_id)
where collection_id is not null;

ALTER TABLE pr_cred
DROP COLUMN collect_fact;

ALTER TABLE pr_cred
DROP COLUMN old_id;

alter table pr_cred
add proc_year number null;

CREATE INDEX fact_oper_collection_id_idx ON fact_oper(collection_id);
CREATE INDEX plan_oper_collection_id_idx ON plan_oper(collection_id);

--Add CONSTRAINT
ALTER TABLE PR_CRED
ADD CONSTRAINT fk_id_client_client FOREIGN KEY (id_client) REFERENCES client (id);


--создание таблиц для аудита
Create table pr_cred_audit 
(
id number primary key using index 
          (create index pr_cred_audit_id_idx on
          pr_cred_audit (id)),
o_num_dog varchar2(100),
n_num_dog varchar2(100),
o_summa_dog number(18,2),
n_summa_dog number(18,2),
o_date_begin TIMESTAMP,
n_date_begin TIMESTAMP,
o_date_end TIMESTAMP,
n_date_end TIMESTAMP,
o_id_client number,
n_id_client number,
o_proc_year number,
n_proc_year number,
time timestamp(6)
);

Create sequence pr_cred_audit_seq
Start with 1
increment by 1
NOCYCLE
CACHE 100;
