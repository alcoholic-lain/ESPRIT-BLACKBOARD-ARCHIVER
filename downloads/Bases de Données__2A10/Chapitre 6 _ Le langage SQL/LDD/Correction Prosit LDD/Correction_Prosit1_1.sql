create table membres 
(
login  varchar2(15) constraint pk_membres primary key,
mdp varchar2(50),
nom varchar2(50) not null,
prenom varchar2(50) not null,
constraint ck_mdp1 check (regexp_like (mdp, '[[:lower:]]')),
constraint ck_mdp2 check (regexp_like (mdp, '[[:upper:]]')),
constraint ck_mdp3 check (regexp_like (mdp, '[[:digit:]]'))
);

create table categories
(
nom_categorie varchar2(20) constraint pk_categories primary key,
descriptionC varchar2(80)
);

create table prestataires_services
(
nom_prest varchar2(50) constraint pk_prest_services primary key,
num_adresse number,
rue_adresse varchar2(20),
ville varchar2(20) not null,
CP number,
tel number not null,
email varchar2(50) constraint ck_email check(email like '%@%.%'),
page_fb varchar2(50) UNIQUE constraint ck_page_fb check(page_fb like 'http://%')
);

create table deals
(
intitule varchar2(50) constraint pk_deals primary key,
description_D varchar2(50) not null,
prix_i number,
prix_d number,
reduction number not null,
date_d date not null,
period_v number not null,
noteD number constraint ck_noted check(noted between 0 and 5),
expire varchar2(3) default 'NON' constraint ck_expire check(expire='OUI' OR expire='NON'),
nom_catg varchar2(20) constraint fk_deals_categories references categories(nom_categorie),
nom_prestataire varchar2(50) constraint fk_deals_prestServices references prestataires_services(nom_prest)
);

create table achats
(
intitule varchar2(50) constraint fk_achats_deals references deals(intitule),
login varchar2(15) constraint fk_achats_membres references membres(login),
nbcoupon number not null,
constraint pk_achats primary key(intitule, login)
); 

