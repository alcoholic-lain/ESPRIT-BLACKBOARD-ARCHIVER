1- select concat(upper(nom),concat(' ',prenom)) as "nom et prenom" from members ;   
ou bien   select upper (nom)||' '||prenom
2- 
//case (<fonction> ou <col>) | case 
when val1 then val11;        | when condition1 then val1
....		                 | when condition2 then val2
else ........                | else ..
end as Alias                 | end as.....

select  prix_i ,to_char (date_d,'q'),
case when (to_char (date_d,'q')=<2) then '1' else '2' end as "semestre",
extract(year from date_d ) as "year"from deals ;  

3- select concat (num_adresse,concat(' ',concat(rue_adresse,concat(' ',concat (upper(ville),concat(' ',cp)))))) as "adresse" from prestataires_services;
4- select min(noted)as "minimum",max(noted)as"maximum",avg(noted)as "moyenne"from deals;
5- select count (*)from deals where lower(expire)='non';
6- select count (*)from prestataires_services group by(ville);
7- select sum(nb_coupon) as "somme" from achats group by (intitule);

8- select intitule,nom,prenom from achats join members on (achats.login)=(members.login);
9- select intitule,nom,prenom,prix_i from achats join members on (achats.login)=(members.login) 
												 join deals   on (deals.intitule=achats.intitule) ;
10-select intitule,deals.NOM_PREST,e_mail from prestataires_services 
     join deals on(deals.NOM_PREST=prestataires_services.NOM_PREST) ;
11-select categories.nom_categories, descriptionC,count(*) from categories  
     join deals on (categories.nom_categories=deals.nom_categories)  
	 group by(categories.nom_categories, descriptionC);	