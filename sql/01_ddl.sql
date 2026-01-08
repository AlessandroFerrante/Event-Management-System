-- DDL: Creazione del Database e delle Tabelle
-- DROP DATABASE IF EXISTS event_management;
CREATE DATABASE IF NOT EXISTS event_management;
USE event_management;

-- Tabella Location
CREATE TABLE Location (
    ID_Location INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL UNIQUE,
    Capacity INT UNSIGNED NOT NULL,
    Address VARCHAR(150) NOT NULL,
    City VARCHAR(50) NOT NULL
) ENGINE=InnoDB;

-- Tabella Evento
CREATE TABLE Event (
    ID_Event INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    Title VARCHAR(150) NOT NULL,
    Event_Date DATE NOT NULL,
    Event_Start_Time TIME NOT NULL,
    Event_End_Time TIME NOT NULL,
    Description TEXT NOT NULL,
    Max_Seats INT UNSIGNED NOT NULL,
    Ticket_Price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    Min_Age INT UNSIGNED NOT NULL DEFAULT 0, 
    ID_Location INT UNSIGNED NOT NULL,

    UNIQUE (Title, Event_Date, Event_Start_Time, ID_Location),
    UNIQUE (ID_Location, Event_Date, Event_Start_Time),

    CHECK (Ticket_Price >= 0),
    FOREIGN KEY (ID_Location) REFERENCES Location(ID_Location)
        ON DELETE RESTRICT ON UPDATE CASCADE 
) ENGINE=InnoDB;

-- Tabella User_Account
CREATE TABLE User_Account (
    ID_User INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    Login_Email VARCHAR(100) NOT NULL UNIQUE,
    Password_Hash VARCHAR(255) NOT NULL, 
    Registration_Date DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    CHECK (Login_Email LIKE '%@%')
) ENGINE=InnoDB;

-- Tabella Partecipante 
CREATE TABLE Participant (
    ID_Participant INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(50) NOT NULL,
    Surname VARCHAR(50) NOT NULL, 
    Birth_Date DATE NOT NULL, 
    Contact_Email VARCHAR(100) NOT NULL,
    ID_User INT UNSIGNED NOT NULL,

    CHECK (Contact_Email LIKE '%@%'),
    FOREIGN KEY (ID_User) REFERENCES User_Account(ID_User)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Tabella Sponsor
CREATE TABLE Sponsor (
    ID_Sponsor INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    Sponsor_Name VARCHAR(100) NOT NULL UNIQUE,
    Contact VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

-- Tabella Booking
CREATE TABLE Booking (
    ID_Booking INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    Booking_Date DATETIME DEFAULT CURRENT_TIMESTAMP,
    Total_Amount NUMERIC(10,2) NOT NULL DEFAULT 0.00, 
    ID_User INT UNSIGNED NOT NULL,
    
    FOREIGN KEY (ID_User) REFERENCES User_Account(ID_User)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Tabella Iscrizione 
CREATE TABLE Registration (
    ID_Participant INT UNSIGNED NOT NULL,
    ID_Event INT UNSIGNED NOT NULL,
    ID_Booking INT UNSIGNED NOT NULL,

    Registration_Date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Purchase_Price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    
    PRIMARY KEY (ID_Participant, ID_Event),
    
    FOREIGN KEY (ID_Participant) REFERENCES Participant(ID_Participant)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (ID_Event) REFERENCES Event(ID_Event)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (ID_Booking) REFERENCES Booking(ID_Booking)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Tabella Sponsorizzazione 
CREATE TABLE Sponsorship (
    ID_Sponsor INT UNSIGNED NOT NULL,
    ID_Event INT UNSIGNED NOT NULL,
    Contract_Value NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    Contract_Start_Date DATE NOT NULL,
    Contract_End_Date DATE NOT NULL,
    Sponsor_Level VARCHAR(50), 
    
    PRIMARY KEY (ID_Sponsor, ID_Event),
    
    FOREIGN KEY (ID_Sponsor) REFERENCES Sponsor(ID_Sponsor)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (ID_Event) REFERENCES Event(ID_Event)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CHECK (Contract_End_Date >= Contract_Start_Date)
) ENGINE=InnoDB;