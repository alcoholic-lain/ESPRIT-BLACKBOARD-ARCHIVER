-----------PARTIE 2 -----------
1-
INSERT INTO MEMBRES VALUES 
('Hello2017','H17test','gharbi','salma' );
INSERT INTO MEMBRES VALUES 
('Ahmed1617','A132bc','ben chaabene ','ali ' );
INSERT INTO MEMBRES VALUES 
('Daddou123','B098tt','Ben mahmoud  ','taoufik  ' );
alter table PRESTATAIRES_SERVICES modify rue_adresse varchar2(50);
alter table PRESTATAIRES_SERVICES modify page_fb varchar2(100);
INSERT INTO PRESTATAIRES_SERVICES VALUES 
(  
   'Square Optical L''Aouina ', 2,
   'Résidence Mesk Jinen Ain zaghouan',
   'ariana',
    2036,
    71100001,
    'Square.optical@hotmail.tn ',
    'http://www.facebook.com/Square-optical396558407144821/?fref=ts' 
);

INSERT INTO PRESTATAIRES_SERVICES VALUES 
(  
    'Le Parador la Goulette', 
     9, 
    'Immeuble Labrise Tour',
    'Tunis', 
     2060, 
     71893425, 
     'Parador.Goulette @gmail.com', 
     'http://www.facebook.com/pages/Parador-La-Goulette Restaurant/725375497514325?fref=ts' 
);
INSERT INTO PRESTATAIRES_SERVICES VALUES 
(  'Forever Beauty ',
    2, 
    'rue Taher el Memmi 1 er étage', 
    'Tunis',
     2091,
     71234098 ,
'Forever.beauty@ Hotmail.com ',
'http://www.facebook.com/foreverbeautycenter/?fref=ts '
);
 select *from members; // afficher tous les enregistrements 
 alter table DEALS modify intitule varchar2(100);
 alter table DEALS modify description_d varchar2(200);
 select * from prestataires_services;
 INSERT INTO DEALS VALUES 
 (  
    'Square Optical L''Aouina : Un bon d''achat de valeur de 250 D',  
    'L''offre comprend : - Un bon d''achat de valeur de 250 DT - 30% de réduction sur tout achat des lentilles de couleur ',
    250,
    60,
    to_date ('12/09/2016 09', 'dd/mm/yyyy hh'),
    5,
 NULL,
    'NON',
   
    NULL,
    'Square Optical L''Aouina '
);

INSERT INTO DEALS VALUES 
(
    'Le Parador la Goulette : un menu de déjeuner ou de dîner à partir de 49 DT Seulement ',
    'L''offre vous propose des mets qui vont vous ouvrir l’appétit et donner à vos papilles de grandes envies! Choisissez l''offre qui vous convient... ',
     131,
     63,
     to_date ('10/10/2016 09','dd/mm/yyyy hh'),
     3,
     NULL,
     'NON',
     NULL,
     'Le Parador la Goulette'
);
INSERT INTO categories VALUES 
(  
    'Restaurant et café', 
    'Deals relatifs aux restaurants et cafés et salons de thé' 
);
INSERT INTO categories VALUES 
(  
    'Beauté', 
    'Deals relatifs aux salons de coiffure et SPA ' 
);
Alter table categories modify nom_c varchar2(100);
INSERT INTO categories VALUES 
(  
    'Life style et accessoires', 
    ' Deals relatifs aux accessoires bijoux lunettes montres ... ' 
);
INSERT INTO categories VALUES 
(  
    ' Hôtel ', 
    'Deals relatifs aux hôtels ' 
);
alter table achats modify intitule varchar2(100);

INSERT INTO Achats VALUES 
(  
    'Square Optical L''Aouina : Un bon d''achat de valeur de 250 D', 
    'Hello2017',
     2,
     to_date ('13/10/2016 15:10','dd/mm/yyyy hh24:mi')    
);
INSERT INTO Achats VALUES 
(  
    'Square Optical L''Aouina : Un bon d''achat de valeur de 250 D', 
    'Ahmed1617',
     4,
     to_date ('14/10/2016 10:03 ','dd/mm/yyyy hh24:mi')    
);
INSERT INTO Achats VALUES 
(  
    'Square Optical L''Aouina : Un bon d''achat de valeur de 250 D', 
    'Daddou123',
     3,
     to_date ('12/10/2016 11:00  ','dd/mm/yyyy hh24:mi')    
);
INSERT INTO Achats VALUES 
(  
    'Le Parador la Goulette : un menu de déjeuner ou de dîner à partir de 49 DT Seulement ', 
    'Hello2017',
     5,
     to_date ('12/10/2016 14:05   ','dd/mm/yyyy hh24:mi')    
);
2-
UPDATE PRESTATAIRES_SERVICES SET tel=71100123 WHERE (NOM_prest='Square Optical L''Aouina ');
UPDATE PRESTATAIRES_SERVICES SET tel=71899425 WHERE (NOM_prest='Le Parador la Goulette');
UPDATE PRESTATAIRES_SERVICES SET email='Parador.Goulette@hotmail.com'  WHERE (NOM_prest='Le Parador la Goulette');
UPDATE MEMBRES SET MDP ='H198test' WHERE (login='Hello2017');
UPDATE MEMBRES SET MDP ='A987Tc' WHERE (login='Ahmed1617');
UPDATE DEALS SET EXPIRE ='OUI' WHERE (intitule='Square Optical L''Aouina : Un bon d''achat de valeur de 250 D');