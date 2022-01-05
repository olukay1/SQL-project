--- Create a database
CREATE DATABASE sales_transactions;

-- To select the database you want to work with if you have several Databases
USE sales_transactions;

--- Create table
CREATE TABLE transactions (
Transaction_ID varchar (100) PRIMARY KEY NOT NULL,
Time_stamp datetime2,
Customer_ID varchar (100) NOT NULL,
Firstname nvarchar (100),
Surname nvarchar (100),
Shipping_State nvarchar (100),
Item_ID varchar (100) NOT NULL,
[Description] nvarchar (150),
Retail_Price float,
Loyalty_Discount float (50),
);

---Copy table data from csv file after importing as flat file
INSERT INTO [dbo].[transactions]
SELECT *
FROM [dbo].[RAW_Online_Sales]; -- 3455 rows was copied

-- DATA EXPLORATION
SELECT *
FROM transactions
-- The table have 3,455 rows which means all rows are copied

-- LET'S CHECK (count) FOR UNIQUE VALUES IN EACH COLUMN
SELECT COUNT (DISTINCT transaction_ID)
FROM transactions	
WHERE transaction_ID IS NOT NULL
--3,455 rows. It's obvious there no duplicates and no missing row

SELECT COUNT (DISTINCT Time_stamp) 
FROM transactions	
WHERE Time_stamp IS NOT NULL -- to check for missing rows, delete 'NOT' from 'NOT NULL'
--2368 unique rows. It's obvious there are duplicates but no missing row

SELECT [Description], COUNT ([Description]) AS Product_count, SUM(Retail_Price) AS Amount
FROM transactions
GROUP BY [Description]
ORDER BY Product_count, Amount DESC
-- Total of 68 unique products were sold. COAT recorded the highest sales (174) while SLIPPERS recorded least sales (19)
-- COAT generated highest revenue $17,558.41 while Underwear generated the least revenue $158.76

SELECT Transaction_ID, Time_stamp
FROM transactions
ORDER BY time_stamp
-- I found out that multiple transactions were made at the exact same timestamp, each with unique Transactio_ID. e.g. 2016-12-10 18:22:00

SELECT Shipping_State, count (Shipping_State) State_count
FROM  transactions
Group By Shipping_State
ORDER BY State_count DESC
-- The State with the highest purchase is TEXAS while state with least purchase is Tennessee

SELECT Firstname, Surname, count (Firstname) counts--,   --Transaction_ID,firstname, ,
FROM  transactions
Group By Firstname, Surname
ORDER BY  counts DESC;

SELECT Firstname, Surname, Shipping_State
FROM  transactions
Where Firstname = 'Zoe' AND Surname = 'Johnston'
-- Customer with the highest purchase (11) is Zoe Johnston from Illinoi


-- ============NORMALISATION - TABLE REDESIGN ===============

-- 1NF CHECKED
SELECT *
FROM transactions
-- 3455 rows were recorded

SELECT COUNT (*)
FROM (
	SELECT DISTINCT *
	FROM transactions
) AS AAA
-- The non-prime attributes depnd on the candidate key Transaction_ID, it have no duplicates which satisfy 1NF (First Normal Form)
--Also, no column must have two values in a cell which is true of all columns
-- 1NF CONFIRMED

-- 2NF CHECK
--The transaction table does not conform to 2NF due to the non-prime attributes that does not depend on each of the candidate keys (transaction_ID and Time_stamp-Customer_ID)
-- To make this conform to 2NF, we have to separate the table.
-- Copy customer specific columns into a new table.

SELECT *
FROM transactions

-- Copy customer specific columns into a new table.
SELECT Customer_ID,
		Firstname,
		Surname,
		Shipping_State,
		Loyalty_Discount
INTO temp_table
FROM transactions

-- Get unique data and insert it into a new CUSTOMER_TABLE
SELECT DISTINCT *
INTO customer_table
FROM temp_table
-- 942 rows affected. 942 unique customers

SELECT *
FROM customer_table
-- In this table, we have only one one candidate (CUSTOMER_ID) key whey all the non-prime attributes depends on.
-- With this condition met, 2NF is CONFIRMED.

-- Let's clean the transaction table. 
ALTER TABLE transactions
DROP COLUMN Firstname, Surname, Shipping_State, Loyalty_Discount

SELECT *
FROM transactions
-- With the cleanup, transactions table now conform to 2NF


-- CHECK 3NF
-- Checking Customer_table...
SELECT *
FROM customer_table
-- 3NF CONFIRMED because the table is already in 2NF and Every non-prime attributes is not transitively dependent on every candidate key

-- Checking transactions table...
SELECT *
FROM transactions
-- 1, Item is transitivily dependent on the transaction_Id which obeys 3NF
-- 2, Description does not directly depend on transaction_Id but on Item_Id... Does not obey 3NF. Same goes for Retail_Price
-- Hence we need to separate the table

SELECT Item_ID,
		[Description],
		Retail_Price
INTO temp
FROM transactions
-- 3,455 rows affected

SELECT DISTINCT *
INTO Items_table
FROM temp
-- 126 rows of unique data were copied

-- CLEAN UP
DROP TABLE temp
DROP TABLE temp_table
DROP TABLE [dbo].[RAW_Online_Sales]

ALTER TABLE transactions
DROP COLUMN [Description], Retail_Price

SELECT *
FROM Items_table

SELECT *
FROM customer_table

SELECT *
FROM transactions
-- 3NF CONFIRMED

-- ====================================== --
