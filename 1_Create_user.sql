/*Непонятная настройка без которой ниченго не работает*/
alter session set "_ORACLE_SCRIPT"=true;
--Создание пользователя с необходимыми привилегиями


-- USER SQL
CREATE USER bank IDENTIFIED BY bank ACCOUNT UNLOCK;
--drop user bank cascade
GRANT CREATE SESSION TO bank ;
GRANT CREATE SESSION TO bank WITH ADMIN OPTION;
GRANT CONNECT,RESOURCE,DBA TO bank;
GRANT UNLIMITED TABLESPACE TO bank;

