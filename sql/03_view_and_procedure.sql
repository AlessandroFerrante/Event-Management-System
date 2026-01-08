-- ? ----------------------------
-- ? ------ SPONSORSHIP ---------
-- ? ----------------------------
DELIMITER ;

-- ? visualizzazione di tutti i contratti
CREATE OR REPLACE VIEW View_Sponsorship_Status AS
SELECT 
    S.ID_Sponsor,
    Sp.Sponsor_Name,
    S.ID_Event,
    E.Title AS Event_Title,
    S.Contract_Start_Date,
    S.Contract_End_Date,
    S.Contract_Value,
    S.Sponsor_Level,
    CASE 
        WHEN S.Contract_End_Date < CURDATE() THEN 'Expired'
        WHEN S.Contract_End_Date = CURDATE() THEN 'Expiring today'
        WHEN S.Contract_Start_Date > CURDATE() THEN 'Scheduled'
        ELSE 'Active'
    END AS Current_Status
FROM Sponsorship S
JOIN Sponsor Sp ON S.ID_Sponsor = Sp.ID_Sponsor
JOIN Event E ON S.ID_Event = E.ID_Event;

-- ? ----------------------------

-- ----------------------------
-- --------- USER  ------------
-- ----------------------------
DELIMITER ;

CREATE OR REPLACE VIEW View_User_Tickets AS
SELECT 
    P.ID_User,
    R.ID_Event,
    R.ID_Participant,
    R.ID_Booking,
    E.Title AS Event_Name,
    L.Name AS Location_Name,
    L.Address,
    L.City,
    E.Event_Date,
    E.Event_Start_Time,
    P.Name,
    P.Surname,
    CONCAT(HEX(R.ID_Event), '-', HEX(R.ID_Participant), '-', HEX(UNIX_TIMESTAMP(R.Registration_Date))) AS Ticket_Code,
    R.Purchase_Price,
    R.Registration_Date
FROM Registration R
JOIN Event E ON R.ID_Event = E.ID_Event
JOIN Location L ON E.ID_Location = L.ID_Location
JOIN Participant P ON R.ID_Participant = P.ID_Participant;

DELIMITER //

-- - visualizza il ticket di un partecipante usando la viw
CREATE PROCEDURE Procedure_Get_Single_Ticket(IN p_EventID INT, IN p_ParticipantID INT)
BEGIN
    SELECT 
        Event_Name,
        Location_Name,
        Address,
        City,
        Event_Date,
        Event_Start_Time,
        Name,
        Surname,
        Ticket_Code,     
        Purchase_Price,
        Registration_Date
    FROM View_User_Tickets
    WHERE ID_Event = p_EventID 
      AND ID_Participant = p_ParticipantID;
END //

CREATE PROCEDURE Procedure_Get_User_Tickets_List(IN p_UserID INT)
BEGIN
    SELECT 
        ID_Event,         
        ID_Participant,
        Event_Name,
        Event_Date,
        -- Ticket_Code,
        CONCAT(Name, ' ', Surname) AS Participant
    FROM View_User_Tickets
    WHERE ID_User = p_UserID
    ORDER BY Event_Date DESC;
END //

-- - storico iscrizione di un utente specifico 
CREATE PROCEDURE Procedure_Get_User_Registrations_History(IN p_UserID INT)
BEGIN
    SELECT 
        P.ID_Participant,
        P.Name AS Participant_Name,
        P.Surname AS Participant_Surname,   
        E.ID_Event,
        E.Title AS Event_Title,
        E.Event_Date,
        E.Event_Start_Time    
    FROM Registration R
    JOIN Participant P ON R.ID_Participant = P.ID_Participant
    JOIN Event E ON R.ID_Event = E.ID_Event  
    WHERE P.ID_User = p_UserID   
    ORDER BY 
        P.Surname ASC, 
        P.Name ASC, 
        E.Event_Date DESC; 
END //

-- - partecipanti collegati all'utente specificato
CREATE PROCEDURE Procedure_Get_User_Participants(IN p_UserID INT)
BEGIN
    SELECT 
        ID_Participant, 
        Name, 
        Surname, 
        Birth_Date,
        TIMESTAMPDIFF(YEAR, Birth_Date, CURDATE()) AS Age, 
        Contact_Email
    FROM Participant
    WHERE ID_User = p_UserID
    ORDER BY Surname ASC, Name ASC; 
END //

-- - cambio password user_account 
CREATE PROCEDURE Procedure_Change_Password(IN p_UserID INT, IN p_OldPassword VARCHAR(255), IN p_NewPasswordHash VARCHAR(255))
proc_label: BEGIN
    DECLARE v_CurrentPassword VARCHAR(255);

    SELECT Password_Hash INTO v_CurrentPassword
    FROM User_Account
    WHERE ID_User = p_UserID;

    IF v_CurrentPassword IS NOT NULL AND v_CurrentPassword = p_OldPassword THEN
        UPDATE User_Account
        SET Password_Hash = p_NewPasswordHash
        WHERE ID_User = p_UserID;
        SELECT 'Password aggiornata.' AS Esito;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'la vecchia password non è corretta.';
    END IF;
END //

DELIMITER ;

-- ----------------------------

-- _ ------------------------------
-- _ ---------  EVENT  ------------
-- _ ------------------------------

-- _ STATISTICHE eventi utilizzabile con le condizioni
-- _ Max_Seats, Tickets_Sold, Seats_Remaining, Total_Revenue, Occupancy_Rate
CREATE OR REPLACE VIEW View_Event_Stats AS
SELECT 
    E.ID_Event,
    E.Title,
    E.Event_Date,
    E.Max_Seats,
    COUNT(R.ID_Participant) AS Tickets_Sold,
    (E.Max_Seats - COUNT(R.ID_Participant)) AS Seats_Remaining,
    COALESCE(SUM(R.Purchase_Price), 0) AS Total_Revenue,
    CONCAT(ROUND((COUNT(R.ID_Participant) / E.Max_Seats * 100), 1), '%') AS Occupancy_Rate
FROM Event E
LEFT JOIN Registration R ON E.ID_Event = R.ID_Event
GROUP BY E.ID_Event, E.Title, E.Event_Date, E.Max_Seats;

DELIMITER //

-- _ validazione bigietto attraverso il codice
CREATE PROCEDURE Procedure_Validate_Ticket_Code(IN p_TicketCode VARCHAR(100))
BEGIN
    SELECT 
        'VALID' AS Status,
        Event_Name,
        Event_Date,
        Name,
        Surname,
        Ticket_Code
    FROM View_User_Tickets
    WHERE Ticket_Code = p_TicketCode;
END //

--  _ STATISTICHE Event (Registration + Sponsorship) 
--  _ BILANCIO TOTALE (contabilità)
CREATE PROCEDURE Report_Event_Revenue_Stats(IN p_EventID INT)
BEGIN
    SELECT 
        E.ID_Event,
        E.Title AS Event_Title,
        E.Event_Date,
        
        -- statistiche Partecipazione
        COUNT(R.ID_Participant) AS Tickets_Sold,
        E.Max_Seats AS Total_Capacity,
        CONCAT(ROUND((COUNT(R.ID_Participant) / E.Max_Seats * 100), 1), '%') AS Occupancy_Rate,
        
        -- incasso totale biglietti
        COALESCE(SUM(R.Purchase_Price), 0.00) AS Revenue_Tickets,
        
        -- incasso totale Sponsor
        COALESCE(
            (SELECT SUM(S.Contract_Value) 
             FROM Sponsorship S 
             WHERE S.ID_Event = E.ID_Event), 0.00
        ) AS Revenue_Sponsorship,

        -- totale
        (COALESCE(SUM(R.Purchase_Price), 0.00) + COALESCE(
                (SELECT SUM(S.Contract_Value) 
                 FROM Sponsorship S 
                 WHERE S.ID_Event = E.ID_Event), 0.00)
        ) AS Total_Revenue

    FROM Event E
    LEFT JOIN Registration R ON E.ID_Event = R.ID_Event
    
    -- se p_EventID passato è NULL mostra tutto, altrimenti lo specifico evento richiesto
    WHERE (p_EventID IS NULL OR E.ID_Event = p_EventID)
    
    GROUP BY E.ID_Event, E.Title, E.Event_Date, E.Max_Seats
    ORDER BY Total_Revenue DESC;

END //

--  _ sponsorship di un evento sepicifico
CREATE PROCEDURE Procedure_Get_Event_Sponsorships(IN p_EventID INT)
BEGIN
    SELECT 
        Sponsor_Name, 
        Contract_Value, 
        Contract_Start_Date, 
        Contract_End_Date, 
        Current_Status,
        Sponsor_Level
    FROM View_Sponsorship_Status
    WHERE ID_Event = p_EventID
    ORDER BY Contract_Value DESC; 
END //

--  _ lista partecipanti a un evtno specifico (Registration + Participant + User_Account)
--  _ Ticket_Code, Age, Buyer_Email
CREATE PROCEDURE Procedure_Get_Event_Participants_List(IN p_EventID INT)
BEGIN
    SELECT 
        P.Name,
        P.Surname,
        P.Birth_Date,
        TIMESTAMPDIFF(YEAR, P.Birth_Date, CURDATE()) AS Age, 
        CONCAT(HEX(R.ID_Event), '-', HEX(R.ID_Participant), '-', HEX(UNIX_TIMESTAMP(R.Registration_Date))) AS Ticket_Code,
        R.Registration_Date,
        U.Login_Email AS Buyer_Email 
    FROM Registration R
    JOIN Participant P ON R.ID_Participant = P.ID_Participant
    JOIN User_Account U ON P.ID_User = U.ID_User 
    WHERE R.ID_Event = p_EventID
    ORDER BY P.Surname ASC, P.Name ASC;
END //

DELIMITER ;

--  _ ------------------------------

-- | ------------------------------
-- | ---------- SPONSOR  ----------
-- | ------------------------------

DELIMITER //

-- | sponsorship di uno sponsor specifico
CREATE PROCEDURE Procedure_Get_Sponsor_Sponsorships(IN p_SponsorID INT)
BEGIN
    SELECT 
        Event_Title,
        Contract_Value,
        Contract_Start_Date,
        Contract_End_Date,
        Current_Status,
        Sponsor_Level
    FROM View_Sponsorship_Status
    WHERE ID_Sponsor = p_SponsorID
    ORDER BY Contract_End_Date DESC;
END //

DELIMITER ;

-- | ------------------------------
