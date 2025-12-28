--1
create table circuitss ( idcircuit number(8) primary key , 
intitule varchar(10) unique  check(substr(intitule,1,1) between 'A' and 'Z') ,
description varchar(80) not null, 
prixcircuit number not null ,
nbplacedisponible number  not null check( nbplacedisponible between 10 and 100) ,
idvol number(5) references vols(idvol)); 

create table reservations ( codeclient number references clients(codeclient), 
idcircuit number references circuits(idcircuit) ,  
datereservation date default sysdate, 
etatreservation varchar(30)  check ( etatreservation in ('confirme','annule')),
nbplacereserve number not null , 
acompte number not null check ( acompte > 500),
constraint pk_res primary key ( codeclient, idcircuit, datereservation)); 
--2
alter table reservations 
modify etatreservation not null; 
--3
insert into vols (idvol, villedepart, villedestination, datedepart, heuredepart, datearrivee) values ( 1024, 'Tunis', 'Istanbul', to_date('20/03/2022','dd/mm/yyyy'), to_date('20/03/2022 15:10','dd/mm/yyyy hh24:mi'),  to_date('20/03/2022','dd/mm/yyyy')); 
--4
select intitule 
from circuits 
where idvol is null; 
--5
select idcircuit
from reservations 
where to_char(datereservation,'q')='1'
and to_char(datereservation,'yyyy')=to_char(sysdate,'yyyy'); 
--6
select nom, prenom , intitule 
from clients c
join reservations r
on r.codeclient=c.codeclient
join circuits cr 
on cr.idcircuit=r.idcircuit
where etatreservation='confirme'; 
--7
select villedepart 
from vols
group by villedepart
having count(idvol)>50; 
--8
select codeclient
from reservations 
group by codeclient
having count(distinct(idcircuit))=( select count(idcircuit) from circuits); 

--9
select count(idcircuit)
from circuits
where idcircuit not in ( select idcircuit from reservations); 