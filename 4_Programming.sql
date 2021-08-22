create or replace function day_in_year 
(
 x IN number
) 
RETURN number
IS
--c number;
BEGIN
    --Год является високосным, если он кратен 4 и при этом не кратен 100 либо кратен 400.
    IF (MOD(x,4) = 0 and MOD(x,100) <> 0) OR (MOD(x,400) = 0)
        then RETURN 366;
        else RETURN 365;
    END IF;
END day_in_year;
/

--set serveroutput on
Create or replace procedure create_cred(
n in varchar2,
s in number,
begdat in date,
lng in number,
proc in number,
fio in varchar2,
datb in date) 

IS
incorrect_data EXCEPTION;--обьявление исключений
too_young EXCEPTION;
fio_error EXCEPTION;
с_id NUMBER;-- номер карточки субьекта договора
fio_valid BOOLEAN; -- переменная для валидации ФИО
BEGIN
    ----------
    --Блок проверок
    ----------
    --
    IF (begdat   > CURRENT_DATE) OR
       (s        <  1000) OR --
       (lng      <     3) OR --
       (proc     <     5) OR 
       (n        is null) OR 
       (s        is null) OR 
       (begdat   is null) OR 
       (lng      is null) OR
       (proc     is null) OR
       (fio      is null) OR
       (datb     is null)
       THEN
       RAISE incorrect_data;
    END IF;
    --
    IF MONTHS_BETWEEN(begdat, datb) < 216 THEN
        RAISE too_young;
    END IF;
    --
    fio_valid := REGEXP_LIKE(fio, ' ');
        IF fio_valid = FALSE THEN
        RAISE fio_error;
    END IF;
    
    ----------
    --Блок вставки
    ----------
    --
    select count(*) into с_id from client where cl_name = fio and date_birth = datb;
    IF с_id = 0
        then insert INTO client (id, cl_name, date_birth) VALUES(CLIENT_SEQ.nextval, fio, datb);
    end if;
    --
    INSERT INTO pr_cred (id, num_dog, summa_dog, date_begin, date_end, id_client, proc_year)
    SELECT 
    pr_cred_seq.nextval as id
    ,n as num_dog
    ,s as summa_dog
    ,begdat as date_begin
    ,add_months(begdat, lng) as date_end
    ,(select id from client where cl_name = fio and date_birth = datb) as id_client
    ,proc as proc_year--proc
    --,1 as proc_exp--proc_pe
    from dual;
    COMMIT;
    
    create_payment(
                    dog_id => pr_cred_seq.currval,
                    s_all => s,
                    begdat_cred => begdat,
                    lng_cred => lng,
                    proc_cred => proc);
    
    EXCEPTION
    WHEN incorrect_data
    THEN DBMS_OUTPUT.put_line('Ошибка ввода! Проверьте корректность вводимых данных.');
    WHEN too_young
    THEN DBMS_OUTPUT.put_line('Субьекту договора еще нет 18!');
    WHEN DUP_VAL_ON_INDEX
    THEN DBMS_OUTPUT.put_line('Договор с таким именем уже есть в базе!');
    WHEN fio_error
    THEN DBMS_OUTPUT.put_line('Ошибка ФИО!');
    WHEN NO_DATA_FOUND 
    THEN DBMS_OUTPUT.put_line('Ошибка вставки! Обратитесь в службу поддержки');
    
END create_cred;
/

Create or replace procedure create_payment(
dog_id in number,
s_all in number,
begdat_cred in date,
lng_cred in number,
proc_cred in number) 

IS
i number;
j date;
k varchar(10);
sm_pl numeric(18,2);
sm_pr numeric(18,2);
sm_all number;
BEGIN
    i := 1;
    sm_all:= s_all;
    select sm_all/lng_cred into sm_pl from dual;
    
    insert into plan_oper(id, collection_id, p_date, p_summa, p_type_id)
        SELECT 
            plan_oper_seq.nextval as id
            ,dog_id as collection_id
            ,begdat_cred as p_date
            ,sm_all as p_summa
            ,(select id from p_type where name = 'Выдача кредита') as p_type_id
        from dual;
    
    WHILE i <= lng_cred And sm_all <> 0
    LOOP
        select ADD_MONTHS(begdat_cred, i) into j from dual;
        select TO_CHAR (j, 'DY', 'NLS_DATE_LANGUAGE=AMERICAN') into k from dual;
        --DBMS_OUTPUT.put_line(k);
        IF k IN ('SAT', 'SUN') 
            then 
                WHILE k IN ('SAT', 'SUN')
                LOOP 
                    j := j + 1;
                    select TO_CHAR (j, 'DY', 'NLS_DATE_LANGUAGE=AMERICAN') into k from dual;
                END LOOP;
            --DBMS_OUTPUT.put_line(j);
        END IF;
        --DBMS_OUTPUT.put_line(j || ' ');
        select sm_all * (proc_cred/100) * (EXTRACT(DAY FROM LAST_DAY(j))) / day_in_year(EXTRACT(YEAR FROM LAST_DAY(j))) into sm_pr from dual;
        sm_all := sm_all - sm_pl;
        --DBMS_OUTPUT.put_line(j || ' ' || sm_pl || ' ' || sm_pr);
        
        insert into plan_oper(id, collection_id, p_date, p_summa, p_type_id)
        SELECT 
            plan_oper_seq.nextval as id
            ,dog_id as collection_id
            ,j as p_date
            ,sm_pl as p_summa
            ,(select id from p_type where name = 'Погашение кредита') as p_type_id
        from dual;
        
        insert into plan_oper(id, collection_id, p_date, p_summa, p_type_id)
        SELECT 
            plan_oper_seq.nextval as id
            ,dog_id as collection_id
            ,j as p_date
            ,sm_pr as p_summa
            ,(select id from p_type where name = 'Погашение процентов') as p_type_id
        from dual;
        i:=i+1;
    END LOOP;
END create_payment;
/
--select round(MOD(dbms_random.value*1000,1000)) from dual;


CREATE OR REPLACE VIEW dog_list AS
select 
pr.num_dog as "Номер договора"
,to_char(pr.date_begin, 'DD.MM.YYYY') as "Дата начала"
,to_char(pr.date_end, 'DD.MM.YYYY') as "Дата погашения"
,pr.summa_dog || ' руб.' as "Сумма договора"
,c.cl_name as "Заемщик"
,COALESCE((select sum(p.p_summa) from plan_oper p where p.collection_id = pr.id 
                                       and p.p_type_id = 2--погашение процентов
                                       and p.p_date <= CURRENT_DATE),0)
-
COALESCE((select sum(f.f_summa) from fact_oper f where f.collection_id = pr.id 
                                      and f.p_type_id = 2 --погашение процентов
                                      and f.f_date <= CURRENT_DATE),0)
as "Задолженность по процентам"
,COALESCE((select sum(p.p_summa) from plan_oper p where p.collection_id = pr.id 
                                       and p.p_type_id = 1--погашение кредита 
                                       and p.p_date <= CURRENT_DATE),0)
- COALESCE((select sum(f.f_summa) from fact_oper f where f.collection_id = pr.id 
                                                  and f.p_type_id = 1 --погашение кредита 
                                                  and f.f_date <= CURRENT_DATE),0) 
                                  
as "Задолженность по кредиту"
,(select LISTAGG('Не найден платеж (' || p_type.name ||') за ' || to_char(p.p_date, 'DD.MM.YYYY') || ' на сумму ' || p.p_summa || ' руб.', CHR(10)) 
WITHIN GROUP (ORDER BY p.p_date) "Посрочка"
from plan_oper p
    join p_type on p_type.id = p.p_type_id
    left join fact_oper f on f.collection_id = p.collection_id 
                         and to_char(f.f_date, 'DD.MM.YYYY') = to_char(p.p_date, 'DD.MM.YYYY')
                         and f.p_type_id = p.p_type_id
where p.collection_id = pr.id
  and f.id is null--не найдено в платежах
  and p.p_type_id <> 3 /*Выдача кредита*/
  and p.p_date <= CURRENT_DATE) as "Просрочка по платежам" 

from pr_cred pr
    join client c on c.id = pr.id_client;
    
--Триггеры   
Create or replace trigger tr_pr_cred_audit
AFTER 
    INSERT OR
    UPDATE OR
    DELETE
ON pr_cred
FOR EACH ROW
BEGIN
CASE
    WHEN INSERTING THEN
    INSERT INTO pr_cred_audit
    (ID, n_num_dog, n_summa_dog, n_date_begin,
    n_date_end, n_id_client, n_proc_year, time)
    VALUES(pr_cred_audit_seq.nextval, :new.num_dog, :new.summa_dog, :new.date_begin, 
    :new.date_end, :new.id_client, :new.proc_year, systimestamp);
    
    WHEN UPDATING THEN
    INSERT INTO pr_cred_audit
    (ID, 
    o_num_dog, n_num_dog, 
    o_summa_dog, n_summa_dog, 
    o_date_begin, n_date_begin, 
    o_date_end, n_date_end, 
    o_id_client, n_id_client,
    o_proc_year, n_proc_year, 
    time)
    VALUES(pr_cred_audit_seq.nextval, 
    :old.num_dog, :new.num_dog, 
    :old.summa_dog, :new.summa_dog, 
    :old.date_begin, :new.date_begin, 
    :old.date_end, :new.date_end,
    :old.id_client, :new.id_client,
    :old.proc_year, :new.proc_year,
    systimestamp);
    
    WHEN DELETING THEN
    INSERT INTO pr_cred_audit
    (ID, 
    o_num_dog, o_summa_dog,
    o_date_begin, o_date_end,
    o_id_client, o_proc_year,
    time)
    VALUES (pr_cred_audit_seq.nextval,
    :old.num_dog, :old.summa_dog,
    :old.date_begin, :old.date_end,
    :old.id_client, :old.proc_year,
    systimestamp);
    END CASE;
END;
/