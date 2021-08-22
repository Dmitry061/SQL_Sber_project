--Create table in schema bank
create table client
(
id number primary key using index 
          (create index client_id_idx on
          client (id)),
old_id number,
cl_name varchar2(150) not null,
date_birth TIMESTAMP not null
);

create table plan_oper
(
id number primary key using index 
          (create index plan_oper_id_idx on
          plan_oper (id)),
collection_id number not null,
p_date timestamp not null,
p_summa number(18,2) not null,
type_oper varchar2(100) not null
);

create table fact_oper
(
id number primary key using index 
          (create index fact_oper_id_idx on
          fact_oper (id)),
collection_id number not null,
f_date timestamp not null,
f_summa number(18,2) not null,
type_oper varchar2(100) not null
);
 
Create table pr_cred 
(
id number primary key using index 
          (create index pr_cred_id_idx on
          pr_cred (id)),
old_id number,
num_dog varchar2(100) not null UNIQUE,
summa_dog number(18,2) not null,
date_begin TIMESTAMP not null,
date_end TIMESTAMP not null,
id_client number not null,
collect_plan number,
collect_fact number
);
/*
--Add CONSTRAINT
ALTER TABLE PR_CRED
ADD CONSTRAINT fk_id_client_client FOREIGN KEY (id_client) REFERENCES client (id);
*/
--Add SEQUENCE
Create sequence client_seq
Start with 1
increment by 1
NOCYCLE
CACHE 100;

Create sequence fact_oper_seq
Start with 1
increment by 2
NOCYCLE
CACHE 100;

Create sequence plan_oper_seq
Start with 2
increment by 2
NOCYCLE
CACHE 100;

Create sequence pr_cred_seq
Start with 1
increment by 1
NOCYCLE
CACHE 100;