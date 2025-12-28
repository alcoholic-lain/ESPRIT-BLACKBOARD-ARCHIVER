--1
CREATE VIEW V_MAINTENANCES AS
SELECT T.ID_terrain, T.Nom, T.Adresse, T.Capacite
FROM TERRAINS T
LEFT JOIN MAINTENANCES M ON T.ID_terrain = M.ID_terrain#
WHERE M.ID_maintenance IS NULL;

--2
DECLARE
  max_reservations NUMBER;
  max_year NUMBER;
BEGIN
  SELECT COUNT(*) AS reservations_count, EXTRACT(YEAR FROM Date_reservation) AS reservation_year
  INTO max_reservations, max_year
  FROM RESERVATIONS
  GROUP BY EXTRACT(YEAR FROM Date_reservation)
  ORDER BY reservations_count DESC
  FETCH FIRST 1 ROW ONLY;

  DBMS_OUTPUT.PUT_LINE('L année avec le nombre maximum de réservations est : ' || max_year);
END;

--3
DECLARE
  terrain_nom VARCHAR2(50);
  disponibilite VARCHAR2(50);
BEGIN
  FOR terrain IN (SELECT T.Nom AS terrain_nom, M.ID_maintenance
                  FROM TERRAINS T
                  LEFT JOIN MAINTENANCES M ON T.ID_terrain = M.ID_terrain#)
  LOOP
    IF terrain.ID_maintenance IS NULL THEN
      disponibilite := 'Le terrain est disponible';
    ELSE
      disponibilite := 'En cours de maintenance';
    END IF;

    DBMS_OUTPUT.PUT_LINE('Terrain : ' || terrain.terrain_nom || ' - ' || disponibilite);
  END LOOP;
END;


--4
--A
CREATE OR REPLACE PROCEDURE PROC_TOP5_CLIENTS
IS
BEGIN
  FOR client IN (SELECT P.Nom, P.Prenom, COUNT(*) AS nb_reservations
                 FROM PERSONNES P
                 INNER JOIN CLIENTS C ON P.Id_Personne = C.ID_client#
                 INNER JOIN RESERVATIONS R ON C.ID_client# = R.ID_client#
                 GROUP BY P.Nom, P.Prenom
                 ORDER BY nb_reservations DESC
                 FETCH FIRST 5 ROWS ONLY)
  LOOP
    DBMS_OUTPUT.PUT_LINE('Client : ' || client.Nom || ' ' || client.Prenom);
    DBMS_OUTPUT.PUT_LINE('Nombre de réservations : ' || client.nb_reservations);
    DBMS_OUTPUT.PUT_LINE('------------------------------------');
  END LOOP;
END;
/

--B
BEGIN
  PROC_TOP5_CLIENTS;
END;


--5
--A
CREATE OR REPLACE FUNCTION FN_CALCUL_BONUS(p_ID_employe IN EMPLOYES.ID_employe#%TYPE)
  RETURN NUMBER
IS
  v_bonus NUMBER;
  v_nb_operations NUMBER;
BEGIN
  -- Vérification de l'existence de l'employé
  SELECT COUNT(*) INTO v_nb_operations
  FROM EMPLOYES
  WHERE ID_employe# = p_ID_employe;

  IF v_nb_operations = 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'L''employé n''existe pas.');
  END IF;

  -- Calcul du bonus
  SELECT COUNT(*) INTO v_nb_operations
  FROM MAINTENANCES
  WHERE EXTRACTM(ONTH FROM Date_maintenance) = EXTRACT(MONTH FROM SYSDATE)
    AND ID_employe# = p_ID_employe;

  v_bonus := v_nb_operations * 10;

  RETURN v_bonus;
END;
/

--B
DECLARE
  bonus_sal NUMBER;
BEGIN
  bonus_sal := FN_CALCUL_BONUS(p_ID_employe => 15);
  DBMS_OUTPUT.PUT_LINE('Le bonus salarial est : ' || bonus_sal);
END;


--6
CREATE OR REPLACE PROCEDURE PROC_INSERTION(
  p_ID_reservation IN RESERVATIONS.ID_reservation%TYPE,
  p_Date_reservation IN RESERVATIONS.Date_reservation%TYPE,
  p_Heure_debut IN RESERVATIONS.Heure_debut%TYPE,
  p_Heure_fin IN RESERVATIONS.Heure_fin%TYPE,
  p_ID_terrain IN RESERVATIONS.ID_terrain#%TYPE,
  p_ID_client IN RESERVATIONS.ID_client#%TYPE
)
IS
  v_terrain_exists NUMBER;
  v_reservation_exists NUMBER;
  v_maintenance_exists NUMBER;
BEGIN
  -- Vérification de l'existence du terrain
  SELECT COUNT(*) INTO v_terrain_exists
  FROM TERRAINS
  WHERE ID_terrain = p_ID_terrain;

  IF v_terrain_exists = 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Le terrain n''existe pas.');
  END IF;

  -- Vérification de l'existence de la réservation
  SELECT COUNT(*) INTO v_reservation_exists
  FROM RESERVATIONS
  WHERE ID_reservation = p_ID_reservation;

  IF v_reservation_exists > 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'La réservation existe déjà.');
  END IF;

  -- Vérification de la disponibilité du terrain
  SELECT COUNT(*) INTO v_maintenance_exists
  FROM MAINTENANCES
  WHERE ID_terrain# = p_ID_terrain
    AND TRUNC(Date_maintenance) = TRUNC(p_Date_reservation)
    AND (
      (p_Heure_debut >= Heure_debut AND p_Heure_debut < Heure_fin)
      OR (p_Heure_fin > Heure_debut AND p_Heure_fin <= Heure_fin)
      OR (p_Heure_debut <= Heure_debut AND p_Heure_fin >= Heure_fin)
    );

  IF v_maintenance_exists > 0 THEN
    RAISE_APPLICATION_ERROR(-20003, 'Le terrain est indisponible à cette heure en raison de la maintenance.');
  END IF;

  -- Insertion de la réservation
  INSERT INTO RESERVATIONS (
    ID_reservation,
    Date_reservation,
    Heure_debut,
    Heure_fin,
    ID_terrain#,
    ID_client#
  ) VALUES (
    p_ID_reservation,
    p_Date_reservation,
    p_Heure_debut,
    p_Heure_fin,
    p_ID_terrain,
    p_ID_client
  );

  COMMIT;

  DBMS_OUTPUT.PUT_LINE('La réservation a été ajoutée avec succès.');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Une erreur s''est produite lors de l''ajout de la réservation.');
    DBMS_OUTPUT.PUT_LINE('Erreur : ' || SQLERRM);
END;
/


--7
CREATE OR REPLACE TRIGGER TRIG_INSERTION
BEFORE INSERT ON RESERVATIONS
FOR EACH ROW
BEGIN
  IF :NEW.Heure_debut >= :NEW.Heure_fin THEN
    RAISE_APPLICATION_ERROR(-20001, 'L''heure de début doit être inférieure à l''heure de fin.');
  END IF;
END;
/


--8
CREATE OR REPLACE TRIGGER TRIG_FIDELITE
AFTER INSERT OR DELETE ON RESERVATIONS
FOR EACH ROW
BEGIN
  -- Mise à jour des points de fidélité pour le client de la réservation
  IF INSERTING THEN
    UPDATE CLIENTS
    SET point_fidelite = point_fidelite + ROUND(point_fidelite * 0.10)
    WHERE ID_client# = :NEW.ID_client#;
  ELSIF DELETING THEN
    UPDATE CLIENTS
    SET point_fidelite = point_fidelite - ROUND(point_fidelite * 0.10)
    WHERE ID_client# = :OLD.ID_client#;
  END IF;
END;
/

