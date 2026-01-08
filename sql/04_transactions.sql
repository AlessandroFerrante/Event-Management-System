-- Transaction

DELIMITER //

-- Atomicità Ordine + (Partecipante + Iscrizione)
CREATE PROCEDURE Transaction_Register_Single_New (IN p_EventID INT, IN p_UserID INT, IN p_Name VARCHAR(50), IN p_Surname VARCHAR(50), IN p_Birth_Date DATE, IN p_ContactEmail VARCHAR(100))
proc_label:BEGIN
    DECLARE v_BookingID INT;
    DECLARE v_ParticipantID INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL; 
    END;

    START TRANSACTION; 

    -- cerco se esite l'identico partecipante
    SELECT ID_Participant INTO v_ParticipantID
    FROM Participant
    WHERE ID_User = p_UserID       
      AND Name = p_Name            
      AND Surname = p_Surname       
      AND Birth_Date = p_Birth_Date; 


    INSERT INTO Booking (ID_User) VALUES (p_UserID);
    SET v_BookingID = LAST_INSERT_ID();

    -- controllo se esite 
    IF v_ParticipantID IS NOT NULL THEN
        INSERT INTO Registration (ID_Participant, ID_Event, ID_Booking) 
        VALUES (v_ParticipantID, p_EventID, v_BookingID);
        
        COMMIT;
        SELECT CONCAT('Partecipante già presente iscrizione completata') AS Esito;
    
    ELSE
        INSERT INTO Participant (Name, Surname, Birth_Date, Contact_Email, ID_User) 
        VALUES (p_Name, p_Surname, p_Birth_Date, p_ContactEmail, p_UserID);
        SET v_ParticipantID = LAST_INSERT_ID();

        INSERT INTO Registration (ID_Participant, ID_Event, ID_Booking) 
        VALUES (v_ParticipantID, p_EventID, v_BookingID);

        COMMIT;
        SELECT CONCAT('nuovo Partecipante creato, iscrizione completata.') AS Esito;
    END IF;

END //

-- Atomicità Boking + Iscrizione per Partecipante esistente
CREATE PROCEDURE Transaction_Register_Existing (IN p_EventID INT, IN p_UserID INT, IN p_ParticipantID INT)
proc_label: BEGIN
    DECLARE v_BookingID INT;
    DECLARE v_OwnerID INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    SELECT ID_User INTO v_OwnerID FROM Participant WHERE ID_Participant = p_ParticipantID;
    
    IF v_OwnerID != p_UserID THEN
        ROLLBACK;
        -- SELECT 'partecipante non collegato allo stesso account' AS Status; -- non potrebbe accadere
        LEAVE proc_label;
    END IF;

    INSERT INTO Booking (ID_User) VALUES (p_UserID);
    SET v_BookingID = LAST_INSERT_ID();

    INSERT INTO Registration (ID_Participant, ID_Event, ID_Booking) 
    VALUES (p_ParticipantID, p_EventID, v_BookingID);

    COMMIT;
    SELECT 'Iscrizione effettuata.' AS Status;

END //

-- Atomicità Iscrizione Multipla
CREATE PROCEDURE Transaction_Register_Group_JSON(IN p_EventID INT, IN p_UserID INT, IN p_JSON_Data JSON)
proc_label: BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE prenotation_count INT;    
    DECLARE v_BookingID INT;
    
    DECLARE v_Name VARCHAR(50);
    DECLARE v_Surname VARCHAR(50);
    DECLARE v_Birth_Date DATE; 
    DECLARE v_Email VARCHAR(100);
    
    DECLARE new_participant_id INT; 
    DECLARE existing_participant_id INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK; 
        SELECT 'Transazione fallita. Rollback totale.' AS Status;
    END;

    START TRANSACTION;

    INSERT INTO Booking (ID_User) VALUES (p_UserID);
    SET v_BookingID = LAST_INSERT_ID(); 

    SET prenotation_count = JSON_LENGTH(p_JSON_Data);

    WHILE i < prenotation_count DO
        SET v_Name = JSON_UNQUOTE(JSON_EXTRACT(p_JSON_Data, CONCAT('$[', i, '].name')));
        SET v_Surname = JSON_UNQUOTE(JSON_EXTRACT(p_JSON_Data, CONCAT('$[', i, '].surname')));
        SET v_Birth_Date = JSON_UNQUOTE(JSON_EXTRACT(p_JSON_Data, CONCAT('$[', i, '].dob'))); 
        SET v_Email = JSON_UNQUOTE(JSON_EXTRACT(p_JSON_Data, CONCAT('$[', i, '].email')));

        SET existing_participant_id = NULL;

        -- cerco se esiste già 
        SELECT ID_Participant INTO existing_participant_id
        FROM Participant
        WHERE ID_User = p_UserID
          AND Name = v_Name
          AND Surname = v_Surname
          AND Birth_Date = v_Birth_Date;

        
        IF existing_participant_id IS NOT NULL THEN
            -- esiste 
            SET new_participant_id = existing_participant_id;
        ELSE
            -- se non esiste
            INSERT INTO Participant (Name, Surname, Birth_Date, Contact_Email, ID_User) 
            VALUES (v_Name, v_Surname, v_Birth_Date, v_Email, p_UserID);
            SET new_participant_id = LAST_INSERT_ID();
        END IF;

        INSERT INTO Registration (ID_Participant, ID_Event, ID_Booking) 
        VALUES (new_participant_id, p_EventID, v_BookingID);

        SET i = i + 1;
    END WHILE;

    COMMIT; 
    SELECT CONCAT('Gruppo iscritto, Booking ID: ', v_BookingID) AS Status;
END //

-- Atomicità Iscrizione Multipla per Partecipanti esistente
CREATE PROCEDURE Transaction_Register_Existing_Group_JSON(
    IN p_EventID INT,
    IN p_UserID INT,
    IN p_JSON_ParticipantIDs JSON 
)
proc_label: BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE count_ids INT;
    DECLARE v_BookingID INT;
    
    DECLARE v_ParticipantID INT;
    DECLARE v_OwnerID INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Rollback totale.' AS Status;
    END;

    START TRANSACTION;

    INSERT INTO Booking (ID_User) VALUES (p_UserID);
    SET v_BookingID = LAST_INSERT_ID(); 

    SET count_ids = JSON_LENGTH(p_JSON_ParticipantIDs);

    WHILE i < count_ids DO
        SET v_ParticipantID = JSON_EXTRACT(p_JSON_ParticipantIDs, CONCAT('$[', i, ']'));

        -- sontrollo che questo ID esiste, associato allo stesso utente
        SELECT ID_User INTO v_OwnerID FROM Participant WHERE ID_Participant = v_ParticipantID;

        IF v_OwnerID IS NULL OR v_OwnerID != p_UserID THEN
            ROLLBACK;
            -- SELECT CONCAT('Il partecipante ID ', v_ParticipantID, 'non eiste') AS Status; -- non può succedere
            LEAVE proc_label;
        END IF;

        INSERT INTO Registration (ID_Participant, ID_Event, ID_Booking) 
        VALUES (v_ParticipantID, p_EventID, v_BookingID);

        SET i = i + 1;
    END WHILE;

    COMMIT;
    SELECT CONCAT('Gruppo esistente iscritto. Booking ID: ', v_BookingID) AS Status;
END //


CREATE PROCEDURE Transaction_Swap_Event_Date (IN p_ParticipantID INT, IN p_OldEventID INT, IN p_NewEventID INT)
proc_label: BEGIN
    DECLARE v_OldTitle VARCHAR(150);
    DECLARE v_NewTitle VARCHAR(150);
    DECLARE v_OldPrice NUMERIC(10,2);
    DECLARE v_NewPrice NUMERIC(10,2);
    
    DECLARE v_UserID INT; 
    DECLARE v_NewBookingID INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Transazione annullata.' AS StatusSwapEventDate;
    END;

    START TRANSACTION;

    -- vecchio evnto
    SELECT Title, Ticket_Price INTO v_OldTitle, v_OldPrice FROM Event WHERE ID_Event = p_OldEventID;
    -- nuovo evento 
    SELECT Title, Ticket_Price INTO v_NewTitle, v_NewPrice FROM Event WHERE ID_Event = p_NewEventID;

    IF v_OldTitle != v_NewTitle THEN
        ROLLBACK;
        SELECT 'Evento diverso. (Titolo)' AS StatusSwapEventDate;
        LEAVE proc_label;
    END IF;

    IF v_OldPrice != v_NewPrice THEN
        ROLLBACK;
        SELECT 'Prezzo diverso.' AS StatusSwapEventDate;
        LEAVE proc_label;
    END IF;

    -- creazione ordine+iscrizione
    SELECT ID_User INTO v_UserID FROM Participant WHERE ID_Participant = p_ParticipantID;

    INSERT INTO Booking (ID_User) VALUES (v_UserID);
    SET v_NewBookingID = LAST_INSERT_ID();
    
    INSERT INTO Registration (ID_Participant, ID_Event, ID_Booking) VALUES (p_ParticipantID, p_NewEventID, v_NewBookingID);

    -- cancella ordine vecchio
    DELETE FROM Registration 
    WHERE ID_Participant = p_ParticipantID AND ID_Event = p_OldEventID;

    COMMIT;
    SELECT 'SUCCESSO: Cambio data effettuato.' AS StatusSwapEventDate;

END //

-- Atomictà per eliminazione Register+Partecipant
CREATE PROCEDURE Transaction_Unregister(IN p_ParticipantID INT, IN p_EventID INT)
BEGIN
    DECLARE v_RemainingTickets INT;
    DECLARE v_Exists INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Errore durante la cancellazione. Rollback effettuato.' AS Status;
    END;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_Exists 
    FROM Registration 
    WHERE ID_Participant = p_ParticipantID AND ID_Event = p_EventID;
    -- se esiste l'evento da da eliminare
    IF v_Exists > 0 THEN

        DELETE FROM Registration 
        WHERE ID_Participant = p_ParticipantID AND ID_Event = p_EventID;

        -- se ci sono altre registrazioni lo stesso partecipante
        SELECT COUNT(*) INTO v_RemainingTickets
        FROM Registration
        WHERE ID_Participant = p_ParticipantID;

       -- cntrollo se il biglietto esistete
        IF v_RemainingTickets = 0 THEN
            DELETE FROM Participant WHERE ID_Participant = p_ParticipantID;
            SELECT 'Biglietto cancellato. Partecipante rimosso.' AS Status;
        ELSE
            SELECT 'Biglietto cancellato. Il partecipante ha ancora altri eventi.' AS Status;
        END IF;

    ELSE
        SELECT 'Biglietto non trovato.' AS Status;
    END IF;

    COMMIT;
END //

-- s
CREATE PROCEDURE Transaction_Cancel_Sponsorship(
    IN p_SponsorID INT,
    IN p_EventID INT
)
BEGIN
    DECLARE v_Exists INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Errore cacncellazione sponsorship.' AS Status;
    END;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_Exists 
    FROM Sponsorship 
    WHERE ID_Sponsor = p_SponsorID 
      AND ID_Event = p_EventID
      AND Contract_End_Date >= CURDATE(); 

    IF v_Exists > 0 THEN
        UPDATE Sponsorship 
        SET Contract_End_Date = CURDATE()
        WHERE ID_Sponsor = p_SponsorID AND ID_Event = p_EventID;
        
        COMMIT;
        SELECT 'Contratto annulato in data odierna' AS Status;
    ELSE
        ROLLBACK;
        SELECT 'Contratto attivo non trovato' AS Status;
    END IF;

END //


CREATE PROCEDURE Transaction_Add_Sponsorship(
    IN p_SponsorID INT,
    IN p_EventID INT,
    IN p_Value NUMERIC(10,2),
    IN p_StartDate DATE,
    IN p_EndDate DATE,
    IN p_SponsorLevel VARCHAR(50)
)
proc_label: BEGIN
    DECLARE v_Exists INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- se esiste contratto evento-sponsor
    SELECT COUNT(*) INTO v_Exists 
    FROM Sponsorship 
    WHERE ID_Sponsor = p_SponsorID AND ID_Event = p_EventID;

    IF v_Exists > 0 THEN
        ROLLBACK;
        SELECT 'Lo Sponsor ha già un contratto attivo per questo evento' AS Status;
        LEAVE proc_label;
    END IF;

    INSERT INTO Sponsorship (ID_Sponsor, ID_Event, Contract_Value, Contract_Start_Date, Contract_End_Date, Sponsor_Level) 
    VALUES (p_SponsorID, p_EventID, p_Value, p_StartDate, p_EndDate, p_SponsorLevel);

    COMMIT;
    SELECT 'Sponsorship registrata' AS Status;

END //


CREATE PROCEDURE Transaction_Update_Sponsorship(IN p_SponsorID INT, IN p_EventID INT, IN p_NewValue NUMERIC(10,2), IN p_NewStartDate DATE, IN p_NewEndDate DATE, IN p_NewLevel VARCHAR(50))
BEGIN
    DECLARE v_Exists INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- se esiste contratto evento-sponsor
    SELECT COUNT(*) INTO v_Exists 
    FROM Sponsorship 
    WHERE ID_Sponsor = p_SponsorID AND ID_Event = p_EventID;

    IF v_Exists = 0 THEN
        ROLLBACK;
        SELECT 'Lo Sponsor non ha un contratto attivo per questo evento' AS Status;
    ELSE
        UPDATE Sponsorship
        SET Contract_Value = p_NewValue,
            Contract_Start_Date = p_NewStartDate,
            Contract_End_Date = p_NewEndDate,
            Sponsor_Level = p_NewLevel
        WHERE ID_Sponsor = p_SponsorID AND ID_Event = p_EventID;

        COMMIT;
        SELECT 'Dati Sponsorship aggiornati' AS Status;
    END IF;

END //

DELIMITER ;