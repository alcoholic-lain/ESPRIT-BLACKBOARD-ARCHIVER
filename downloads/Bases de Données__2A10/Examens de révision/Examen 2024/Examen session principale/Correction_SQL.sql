--1) (2 pts)
CREATE TABLE JOUEURS (
    NoJoueur INT PRIMARY KEY,
    NomJoueur VARCHAR2(50) NOT NULL,
    Sexe CHAR(1) CHECK (Sexe IN ('H', 'F')) NOT NULL,
    Age INT,
    Pays VARCHAR2(50) NOT NULL
);

CREATE TABLE DISPUTES (
    NoJoueur INT,
    NoMatch INT,
    PRIMARY KEY (NoJoueur, NoMatch),
    FOREIGN KEY (NoJoueur) REFERENCES JOUEURS(NoJoueur),
    FOREIGN KEY (NoMatch) REFERENCES MATCHS(NoMatch)
);

--2) (0.5 pt)
Alter table JUGES 
modify  paysJuge NOT NULL;

--3) (1 pt)
Insert into MATCHS (noMatch, posMatch, typeMatch) values (100, 'Pr', 'amical');
Insert into MATCHS (noMatch, posMatch) values (200, 'S');

--4) (1 pt)
SELECT noJuge
FROM Arbitrages
WHERE (noMatch IN (100, 400));

--5) (1 pt)
SELECT NoJoueur FROM DISPUTES D
GROUP BY NoJoueur
HAVING COUNT(DISTINCT D.NoMatch) = 2;

--6) (1.5 pt)
SELECT DISTINCT J.NomJuge FROM JUGES J
INNER JOIN ARBITRAGES A ON J.NoJuge = A.NoJuge
INNER JOIN MATCHS M ON A.NoMatch = M.NoMatch
WHERE M.typeMatch = 'amical';

--7) (1.5 pt)
SELECT J.NoJuge, J.NomJuge, paysJuge FROM JUGES J
LEFT JOIN ARBITRAGES A ON J.NoJuge = A.NoJuge
WHERE A.NoJuge IS NULL;

--8) (1.5 pt)  
SELECT J.nomJoueur, COUNT(DISTINCT D.noMatch) AS nombreMatchsDisputes
FROM JOUEURS J
JOIN DISPUTES D ON J.noJoueur = D.noJoueur
GROUP BY J.nomJoueur
ORDER BY nombreMatchsDisputes DESC; 

#Méthode de Mustapha Trabelsi:
SELECT J.nomJoueur FROM JOUEURS J JOIN DISPUTES D ON J.NoJoueur = D.NoJoueur
GROUP BY D.NoJoueur
HAVING COUNT(D.NoMatch) = (SELECT MAX(MatchCount) FROM (
SELECT NoJoueur, COUNT(NoMatch) AS MatchCount FROM D GROUP BY NoJoueur));

