cd C:\Users\Oracle\Desktop\Temp
sqlldr userid=bank/bank control=./Import_client.ctl
sqlldr userid=bank/bank control=./Import_fact_oper.ctl
sqlldr userid=bank/bank control=./Import_plan_oper.ctl
sqlldr userid=bank/bank control=./Import_pr_cred.ctl
