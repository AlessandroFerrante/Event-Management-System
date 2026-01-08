
# 🎟️ Event Management System

![MySQL](https://img.shields.io/badge/mysql-4479A1.svg?style=for-the-badge&logo=mysql&logoColor=white)
![SQL](https://img.shields.io/badge/Language-SQL-orange?style=for-the-badge)
![MySQL Workbench](https://img.shields.io/badge/MySQL%20Workbench-4479A1?style=for-the-badge&logo=mysql&logoColor=white)

![Status](https://img.shields.io/badge/STATUS-COMPLETED-success?style=for-the-badge)
![Course](https://img.shields.io/badge/Course-Database-lightgrey?style=for-the-badge)
![License](https://img.shields.io/badge/LICENSE-MIT-green?style=for-the-badge)


A comprehensive relational database designed to manage **Events**, **Electronic Ticketing**, **Participants**, and **Sponsorships**.
The project was developed with a strong focus on **Privacy by Design (GDPR)**, **Data Integrity (ACID)**, and automation through advanced **Stored Procedures**.

---

## 📋 Index

- [🎟️ Event Management System](#️-event-management-system)
  - [📋 Index](#-index)
  - [🚀 Main Features](#-main-features)
    - [1. Registration Management](#1-registration-management)
    - [2. Sponsor Management](#2-sponsor-management)
    - [3. Monitoring \& Reporting](#3-monitoring--reporting)
  - [🏗️ Database Architecture](#️-database-architecture)
    - [Privacy by Design \& GDPR](#privacy-by-design--gdpr)
    - [E-R Schema](#e-r-schema)
    - [Relational Logical Diagram](#relational-logical-diagram)
  - [🛠️ Technical Features](#️-technical-features)
  - [📡 List of Operations (Database API)](#-list-of-operations-database-api)
    - [🎟️ Registrations](#️-registrations)
    - [🤝 Sponsor](#-sponsor)
    - [📊 Utilities \& Reports](#-utilities--reports)
  - [📓 Report](#-report)
    - [🧑🏻‍💻 Author](#-author)


```
event-management-system/
│
├── 📄 README.md                
├── 📄 Report.pdf               
│
├── 📂 schema/                 
│   ├── SchemaER.svg
│   └── Table.svg
│   └── ...
│
└── 📂 sql/                    
    ├── 01_ddl.sql              <-- Database and Table Creation
    ├── 02_triggers.sql         <-- Triggers
    ├── 03_view_and_procedure.sql   <-- Views (View_Sponsorship_Status, etc.)
    ├── 04_transactions.sql   <-- Transactions (Transaction_Register_Single_New, etc.)
    └── 05_dml.sql         <-- (Optional) insert dummy data for testing
```
---

## 🚀 Main Features

The system manages the entire lifecycle of an event, from creation to post-event reporting.

### 1. Registration Management

* **User/Participant Distinction:** A single user account can manage and register multiple participants (e.g., family, friends), maintaining a personal "Address Book."
* **Group Registration:** Support for bulk registration via **JSON** input, allowing dozens of people to register in a single call.
* **Capacity Controls:** Automatic overbooking prevention via triggers.

### 2. Sponsor Management

* **Contract Lifecycle:** Creation, modification, and cancellation of advertising contracts.
* **Dynamic Status:** Automatic status calculation (Active, Expired, Scheduled) based on dates.

### 3. Monitoring & Reporting

* **Staff Dashboard:** Real-time guest list with ticket codes.
* **Manager Dashboard:** Aggregated financial report (ticket revenue + sponsor revenue).
* **User Dashboard:** Order history and participant directory management.

---

## 🏗️ Database Architecture

### Privacy by Design & GDPR

Unlike traditional systems, **the Tax Code is not used as a Primary Key**.

* Surrogate IDs (INT AUTO_INCREMENT) are used for all entities.
* The Tax Code is not exposed in URLs or foreign keys to prevent *Data Leakage*.
* Logical and physical deletion of data according to the principle of data minimization ("Right to be forgotten").

### E-R Schema
![](./schema/SchemaER.svg)

### Relational Logical Diagram

![](./schema/RelationalLogicalDiagram.svg)

---

## 🛠️ Technical Features

The project makes extensive use of advanced MySQL 8.0 features:

* ✅ **ACID transactions:** Used for all critical operations (e.g., `Transaction_Register_Single_New`) to ensure that Booking and Registration occur atomically.
* ✅ **JSON Management:** Procedures such as `Transaction_Register_Group_JSON` parse JSON arrays directly into SQL for bulk imports.
* ✅ **Triggers:** Business-side integrity checks (e.g., End Date > Start Date, minimum age check, location capacity).
* ✅ **Views:** Abstraction for calculating financial statistics and sponsor status.
* ✅ **Stored Procedures:** All business logic is encapsulated in the DB, exposing a clean interface to the backend.

---

## 📡 List of Operations (Database API)

Here are the main Stored Procedures implemented:

### 🎟️ Registrations

| Procedure | Description |
| --- | --- |
| `Transaction_Register_Single_New` | Creates a new participant and registers it (Atomic). |
| `Transaction_Register_Existing` | Registers a participant already in the user directory. |
| `Transaction_Register_Group_JSON` | Bulk registration from JSON array (New profiles). |
| `Transaction_Register_Existing_Group_JSON` | Bulk registration from JSON array (Existing profiles). |
| `Transaction_Swap_Event_Date` | Moves a registration while maintaining the payment. |
| `Transaction_Unregister` | Unregisters and removes the participant if it is "orphaned." |

### 🤝 Sponsor

| Procedure | Description |
| --- | --- |
| `Transaction_Add_Sponsorship` | Signs a new sponsorship contract. |
| `Transaction_Cancel_Sponsorship` | Terminates a contract early. |
| `Procedure_Get_Sponsor_Sponsorships` | Views a company's investment history. |

### 📊 Utilities & Reports

| Subject | Description |
| --- | --- |
| `Procedure_Change_Password` | Secure password change with prior verification. |
| `Procedure_Get_User_Participants` | Returns the logged-in user's "Address Book." |
| `Report_Event_Revenue_Stats` | Calculate event ROI (Tickets + Sponsors). |
| `View_Event_Stats` | Operational Tracking (Seats Sold / Remaining). |

---


## 📓 Report

For a detailed analysis of the design choices and conceptual modeling, please refer to the full documentation:

[📄 Read the Full Report (Report.pdf)](https://github.com/AlessandroFerrante/Event-Management-System/blob/main/Report.pdf)

---

### 🧑🏻‍💻 Author

Project developed for the Databases course.

**[Alessandro Ferrante](https://alessandroferrante.net)** - Database Design & Implementation