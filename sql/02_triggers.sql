-- --------------------
-- ---- Trigger  -----
-- --------------------
DELIMITER //

-- -----------
-- -- PRICE --
-- -----------

-- Salva Prezzo Automatico in Registration
CREATE TRIGGER Set_Registration_Price
BEFORE INSERT ON Registration
FOR EACH ROW
BEGIN
    DECLARE current_price NUMERIC(10,2);
    SELECT Ticket_Price INTO current_price FROM Event WHERE ID_Event = NEW.ID_Event;
    SET NEW.Purchase_Price = current_price;
END //

-- Aggiornamento Totale Ordine in Booking
CREATE TRIGGER Update_Booking_Total_Insert
AFTER INSERT ON Registration
FOR EACH ROW
BEGIN
    UPDATE Booking 
    SET Total_Amount = Total_Amount + NEW.Purchase_Price
    WHERE ID_Booking = NEW.ID_Booking;
END //

-- aggiornamento Booking
CREATE TRIGGER Update_Booking_Total_Delete
AFTER DELETE ON Registration
FOR EACH ROW
BEGIN
    UPDATE Booking 
    SET Total_Amount = Total_Amount - OLD.Purchase_Price
    WHERE ID_Booking = OLD.ID_Booking;
END //

-- -----------
-- -- Seats --
-- -----------

-- - Controllo Sold Out (Max_Seats dell'evento)
CREATE TRIGGER Check_Max_Seats
BEFORE INSERT ON Registration
FOR EACH ROW
BEGIN
    DECLARE current_count INT;
    DECLARE max_capacity INT;
    SELECT COUNT(*) INTO current_count FROM Registration WHERE ID_Event = NEW.ID_Event;
    SELECT Max_Seats INTO max_capacity FROM Event WHERE ID_Event = NEW.ID_Event;
    IF current_count >= max_capacity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Evento SOLD OUT.';
    END IF;
END //

-- - Controllo posti in Location, INSERT
CREATE TRIGGER Check_Event_Location_Limit
BEFORE INSERT ON Event
FOR EACH ROW
BEGIN
    DECLARE loc_cap INT;
    -- controllo in base alla capieza della location scelta per l'evento 
    SELECT Capacity INTO loc_cap FROM Location WHERE ID_Location = NEW.ID_Location;
    IF NEW.Max_Seats > loc_cap THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Max_Seats supera la capienza fisica della Location!';
    END IF;
END //

-- - Controllo posti in Location, UPDATE
CREATE TRIGGER Check_Event_Location_Limit_Update
BEFORE UPDATE ON Event
FOR EACH ROW
BEGIN
    DECLARE loc_cap INT;
    -- controllo in base alla capieza della location scelta per l'aggiornamento dell'evento 
    SELECT Capacity INTO loc_cap FROM Location WHERE ID_Location = NEW.ID_Location;
    
    IF NEW.Max_Seats > loc_cap THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ERRORE UPDATE: Max_Seats supera la capienza della Location!';
    END IF;
END //

-- - Controllo (inverso) capienza della Location, se ci sono già eventi programmati che richiedono più posti.
CREATE TRIGGER Check_Location_Capacity_Update
BEFORE UPDATE ON Location
FOR EACH ROW
BEGIN
    DECLARE conflict_count INT;

    IF NEW.Capacity < OLD.Capacity THEN
        
        SELECT COUNT(*) INTO conflict_count
        FROM Event
        WHERE ID_Location = NEW.ID_Location
          AND Max_Seats > NEW.Capacity
          AND Event_Date >= CURDATE(); -- per ignorare eventi passati
        
        IF conflict_count > 0 THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Impossibile ridurre la capienza. Ci sono eventi associati che richiedono più posti!';
        END IF;
        
    END IF;
END //

-- ----------------------
-- -- Date Sponsorship --
-- ----------------------

-- Controllo Date Sponsor INSERT
CREATE TRIGGER Check_Sponsorship_Dates
BEFORE INSERT ON Sponsorship
FOR EACH ROW
BEGIN
    DECLARE event_day DATE;
    SELECT Event_Date INTO event_day FROM Event WHERE ID_Event = NEW.ID_Event;
    IF NEW.Contract_End_Date < event_day THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contratto scade prima dell\'evento';
    END IF;
END //

-- Controllo Date Sponsor UPDATE
CREATE TRIGGER Check_Sponsorship_Dates_Update
BEFORE UPDATE ON Sponsorship
FOR EACH ROW
BEGIN
    DECLARE event_day DATE;
    SELECT Event_Date INTO event_day FROM Event WHERE ID_Event = NEW.ID_Event;
    IF NEW.Contract_End_Date < event_day THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Contratto scade prima dell\'evento';
    END IF;
END //

-- -------------------
-- -- Birth_Date --
-- -------------------

-- controllo data di nascita
CREATE TRIGGER Check_Participant_DOB
BEFORE INSERT ON Participant
FOR EACH ROW
BEGIN
    IF NEW.Birth_Date > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La data di nascita non può essere nel futuro!';
    END IF;
END //

-- controllo età minima per l'evento
CREATE TRIGGER Check_Minimum_Age_Limit
BEFORE INSERT ON Registration
FOR EACH ROW
BEGIN
    DECLARE required_age INT;
    DECLARE participant_dob DATE;
    DECLARE actual_age INT;

    SELECT Min_Age INTO required_age FROM Event WHERE ID_Event = NEW.ID_Event;

    SELECT Birth_Date INTO participant_dob FROM Participant WHERE ID_Participant = NEW.ID_Participant;

    SET actual_age = TIMESTAMPDIFF(YEAR, participant_dob, CURDATE());

    IF actual_age < required_age THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Partecipante non soddisfa l\'età minima richiesta per questo evento.';
    END IF;
END //

-- controllo aggiornamento data di nascita 
CREATE TRIGGER Check_Participant_Update_Logic
BEFORE UPDATE ON Participant
FOR EACH ROW
BEGIN
    DECLARE invalid_registrations INT;
    DECLARE actual_age INT;

    IF NEW.Birth_Date > CURDATE() THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'La data di nascita non può essere nel futuro!';
    END IF;

    SET actual_age = TIMESTAMPDIFF(YEAR, NEW.Birth_Date, CURDATE());

    SELECT COUNT(*) INTO invalid_registrations
    FROM Registration R
    JOIN Event E ON R.ID_Event = E.ID_Event
    WHERE R.ID_Participant = NEW.ID_Participant
      AND E.Min_Age > actual_age; 

    IF invalid_registrations > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Impossibile cambiare data di nascita. L\'utente è iscritto a eventi che richiedono un\'età maggiore!';
    END IF;

END //



DELIMITER ;