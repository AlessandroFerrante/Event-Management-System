-- inserimento dati statici
USE event_management;

-- inserimento locations (più opzioni)
INSERT INTO Location (Name, Capacity, Address, City) VALUES 
('Sala A', 50, 'via sql 1', 'roma'),
('Arena B', 2000, 'via dei bit 10', 'modica'),
('Saletta C', 20, 'via casa 5', 'Napoli'),
('Parco D', 500, 'piazza 3', 'torino'),
('Teatro E', 100, 'viale date 9', 'Bologna');

-- inserimento eventi (più varietà)
INSERT INTO Event (Title, Event_Date, Event_Start_Time, Event_End_Time, Description, Max_Seats, Ticket_Price, Min_Age, ID_Location) VALUES
('Talk', '2025-05-10', '10:00:00', '13:00:00', 'talk NOsql', 50, 15.00, 18, 1), 
('Concerto', '2025-06-21', '21:00:00', '23:59:00', 'concerto', 2000, 30.00, 14, 2),       
('Corso SQL', '2025-07-15', '09:00:00', '18:00:00', 'database', 20, 50.00, 18, 3),
('Festival', '2025-08-10', '18:00:00', '23:00:00', 'musica', 500, 20.00, 10, 4),
('Gara Auto', '2025-09-01', '10:00:00', '16:00:00', 'motori', 2000, 25.00, 12, 2);

-- inserimento account utenti (più utenti per testare)
INSERT INTO User_Account (Login_Email, Password_Hash) VALUES
('af@alessandroferrante.net', 'pass'),    
('b@email.com', 'pass_b'),                    
('c@email.com', 'pass_c'),                    
('d@email.com', 'pass_d'),                    
('e@email.com', 'pass_e');                    

-- inserimento anagrafica sponsor (più aziende)
INSERT INTO Sponsor (Sponsor_Name, Contact) VALUES
('Bar Sport', 'mario@mail.com'),            
('Pizzeria Gino', 'gino@mail.com'),
('Market Da Pino', 'pino@mail.com'),
('Tech Store', 'paolo@mail.com');

-- gestione sponsorizzazioni (più movimenti)

-- bar sport sponsorizza talk java (poco budget)
CALL Transaction_Add_Sponsorship(1, 1, 300.00, '2025-01-01', '2025-12-31', 'bronze');

-- pizzeria gino punta tutto sul concerto
CALL Transaction_Add_Sponsorship(2, 2, 2000.00, '2025-03-01', '2025-08-01', 'gold');

-- market da lisa sponsorizza festival jazz
CALL Transaction_Add_Sponsorship(3, 4, 1000.00, '2025-05-01', '2025-09-01', 'silver');

-- tech store sponsorizza corso sql
CALL Transaction_Add_Sponsorship(4, 3, 500.00, '2025-06-01', '2025-08-01', 'silver');

-- aggiornamento: la pizzeria aumenta il budget
CALL Transaction_Update_Sponsorship(2, 2, 2500.00, '2025-03-01', '2025-08-01', 'platinum');

-- cancellazione: bar sport si ritira
CALL Transaction_Cancel_Sponsorship(1, 1);


-- gestione iscrizioni (popolamento massiccio)

-- 1. UTENTE PRINCIPALE (Alessandro)

-- iscrizione singolo a talk java
CALL Transaction_Register_Single_New(
    1, -- Evento: Talk Java
    1, -- User: Alessandro
    'Alessandro', 'Ferrante', '2003-04-28', 'af@alessandroferrante.net'
);

-- iscrizione famiglia ferrante al concerto (json)
CALL Transaction_Register_Group_JSON(
    2, -- Evento: Concerto Rock
    1, -- User: Alessandro
    '[
        {"name": "Marco", "surname": "Ferrante", "dob": "2005-01-01", "email": "m@email.com"},
        {"name": "Giovanni", "surname": "Ferrante", "dob": "2010-05-05", "email": "g@email.com"},
        {"name": "Lucia", "surname": "Ferrante", "dob": "1975-03-10", "email": "lucia@email.com"}
    ]'
);

-- iscrizione alessandro (esistente) al concerto rock con la famiglia
CALL Transaction_Register_Existing(
    2, -- Evento: Concerto Rock
    1, -- User: Alessandro
    1  -- ID Partecipante Alessandro
);


-- 2. ALTRI UTENTI (Per fare volume)

-- utente b porta amici alla gara auto
CALL Transaction_Register_Group_JSON(
    5, -- Evento: Gara Auto
    2, -- User: b@email.com
    '[
        {"name": "Luca", "surname": "Bianchi", "dob": "1990-01-01", "email": "l@email.com"},
        {"name": "Sara", "surname": "Neri", "dob": "1992-02-02", "email": "s@email.com"}
    ]'
);

-- utente c si iscrive da solo al corso sql
CALL Transaction_Register_Single_New(
    3, -- Evento: Corso SQL
    3, -- User: c@email.com
    'Carlo', 'Verdi', '1988-10-10', 'c@email.com'
);

-- utente d iscrive un gruppo numeroso al festival jazz
CALL Transaction_Register_Group_JSON(
    4, -- Evento: Festival Jazz
    4, -- User: d@email.com
    '[
        {"name": "Anna", "surname": "Gialli", "dob": "2000-01-01", "email": "a@test.com"},
        {"name": "Piero", "surname": "Gialli", "dob": "1999-05-05", "email": "p@test.com"},
        {"name": "Marta", "surname": "Blu", "dob": "2001-07-07", "email": "m@test.com"}
    ]'
);

-- utente e si iscrive al concerto rock (aumenta incasso evento 2)
CALL Transaction_Register_Single_New(
    2, -- Evento: Concerto Rock
    5, -- User: e@email.com
    'Elena', 'Rosa', '1995-12-12', 'e@email.com'
);


-- operazioni modifica e cancellazione

-- cambio data: alessandro non può andare al talk java, va al corso sql
CALL Transaction_Swap_Event_Date(1, 1, 3);

-- cancellazione: luca bianchi non va più alla gara auto
-- id partecipante ipotetico, controlla post inserimento
-- CALL Transaction_Unregister(5, 5);

-- cambio password, fallisce la password era pass
-- CALL Procedure_Change_Password(1, 'pass_a', 'new_pass');


-- query standard (controllo inserimenti)

-- lista locations
SELECT * FROM Location;

-- lista utenti
SELECT ID_User, Login_Email, Registration_Date FROM User_Account;

-- lista sponsor
SELECT * FROM Sponsor;

-- controllo incassi grezzi booking
SELECT * FROM Booking ;

-- controllo spesa utente
SELECT * FROM Booking WHERE ID_User=1; 

-- query tramite viste

-- statistiche eventi
SELECT * FROM View_Event_Stats;

-- stato sponsor
SELECT * FROM View_Sponsorship_Status;

-- lista biglietti utente
CALL Procedure_Get_User_Tickets_List(1);

-- dettaglio biglietto concerto per marco ferrante (id ipotetico 2)
CALL Procedure_Get_Single_Ticket(2, 2);

-- validazione biglietto (da testare col codice generato sopra)
-- CALL Procedure_Validate_Ticket_Code('...');


-- query tramite procedure (report finali)

-- bilancio totale (classifica eventi più ricchi)
CALL Report_Event_Revenue_Stats(NULL);

-- lista partecipanti concerto rock (ci sarà la famiglia ferrante + elena)
CALL Procedure_Get_Event_Participants_List(2);

-- storico iscrizioni alessandro
CALL Procedure_Get_User_Registrations_History(1);

-- partecipanti gestiti da alessandro (lui + marco + giovanni + lucia)
CALL Procedure_Get_User_Participants(1);

-- contratti pizzeria gino
CALL Procedure_Get_Sponsor_Sponsorships(2);

-- sponsor del festival jazz
CALL Procedure_Get_Event_Sponsorships(4);