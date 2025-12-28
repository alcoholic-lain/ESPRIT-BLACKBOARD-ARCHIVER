***Partie-1-***
1)select * from Employees where commission_pct is null order by first_name desc ;
2)
**select rank()over (partition by department_id order by salary desc) rang, 
first_name,department_id,salary from employees;
**select row_number()over (partition by department_id order by salary desc) rang, 
first_name,department_id,salary from employees;
**select dense_rank()over (partition by department_id order by salary desc) rang, 
first_name,department_id,salary from employees;
3) 
select first_name||''|| last_name as "nom et prenom", department_id as "num department"
from employees where department_id=30;
4)
select department_id "ID DEPT", substr (department_name,1,3)||'.' "NOM DEPT",
location_id "LOCATION" from departments where department_id<=50;
5)
select last_name nom, case (extract (year from hire_date)) 
when 1998 then 'needs review' 
else 'not this year '
end as review 
from employees;
6)
select employees.*,extract(year from HIRE_DATE)as annee,
to_char(HIRE_DATE,'month')as mois,
to_number(to_char(HIRE_DATE,'q'))as Trimestre
FROM employees order by annee desc ;
7)
select concat(concat((last_NAME),' '),(first_NAME)) as "nom et prenom",
Trunc(Months_Between(sysdate,HIRE_DATE))as "anciennete" from employees where 
DEPARTMENT_ID=30;


***Partie-2-***
1) select MIN (salary)"salaire minimum",MAX(salary)"salaire maximum"from employees;
2) select department_id "ID_department" round(avg(salary),2)"salaire moy" from employees;
3) select department_id as "identifiant", count(*)"nbre d'employees" from employees 
group by department_id;
4) a- on ajoute : order by identifiant ou department_id ou 1 ;
b- select department_id as "identifiant", count(*) "nbre d'employes" from employees 
						group by department_id 
						having count(*) <10 order by 1;


***Partie-3-*** 
1) select E.last_name, E.first_name, D.department_name
from Employees E JOIN departments d 
on E.department_id=D.department_id;
2)select region_name ,country_name,department_name from regions R 
									 join countries c on (c.region_id=R.region_id)
								     join locations l on (l.country_id=c.country_id)
								     join department d on (d.location_id=l.location_id);
order by d.department_name;
3) select Employees.*,job_title from Employees join jobs on employees .job_id=jobs.job_id;
4) select department_name, round(sum(months_between(sysdate,hire_date)),2) "mois travail" 
from departments
join employees 
on departments.department_ID=employees.department_id 
group by department_name;
5)select E.LAST_NAME, E.FIRST_NAME,M.LAST_NAME, M.FIRST_NAME
from EMPLOYEES E
join MANAGERS M
ON E.EMPLOYEE_ID = M.MANAGER_ID;



***Partie-4-***
1) select * from departments where department_id IN
(select department_id from departments 
	MINUS  
 select department_id from employees) ; // sous_interrogation
 2éme méthode==> 
select d.* from departments d  left join employees e 
on e.department_id=d.department_id where e.employee_id is null;	
2) select * from employees where salary = (select min(salary)from employees);
3) select * from employees where manager_id = 
(select manager_id from employees where (employee_id=110) ) 
and employee_id <>110;
4) select null liste,region_name from regions union all 
(select "total" as liste ,to_char(count(region_id)) from regions ;
5) select E.*,(select job_title from jobs J where E.job_id=J.job_id) 
from employees E ;
6) select * from employees where salary > 
(select max_salary from jobs where job_id = 'SA_MAN';
7) select * from employees e where salary < 
(select avg (salary) from employees e1 
group by department_id 
having e1.department_id = e.department_id)
