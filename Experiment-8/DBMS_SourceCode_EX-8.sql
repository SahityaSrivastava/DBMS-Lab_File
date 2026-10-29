-- ============================================================================
-- EXPERIMENT - 8: Transaction Management & Concurrency Control in PostgreSQL
-- ============================================================================

-- Create the bank_accounts table
CREATE TABLE bank_accounts (
    account_id INT PRIMARY KEY,
    account_holder VARCHAR(50),
    balance NUMERIC(12, 2) CHECK (balance >= 0)
);

-- Insert initial account balances for Rahul (101) and Aman (102)
INSERT INTO bank_accounts
VALUES
(101, 'Rahul', 10000.00),
(102, 'Aman', 5000.00);

-- Display the initial state of the bank_accounts table
SELECT * FROM bank_accounts;


-- Start a new transaction block
BEGIN;

-- Deduct 2000 from Rahul's account
UPDATE bank_accounts
SET balance = balance - 2000
WHERE account_id = 101;

-- Add 2000 to Aman's account
UPDATE bank_accounts
SET balance = balance + 2000
WHERE account_id = 102;

-- Permanently save both updates to the database
COMMIT;

-- Verify the updated account balances after committing
SELECT * FROM bank_accounts;



-- Start a new transaction block
BEGIN;

-- Temporarily deduct 1000 from Rahul's account
UPDATE bank_accounts
SET balance = balance - 1000
WHERE account_id = 101;

-- View the balances inside the active transaction (shows temporary change)
SELECT * FROM bank_accounts;

-- Cancel the transaction and undo all uncommitted changes since BEGIN
ROLLBACK;

-- Verify that the balance has reverted to its state prior to the transaction
SELECT * FROM bank_accounts;


-- Start a new transaction block
BEGIN;

-- Step 1: Deduct 500 from Rahul's account
UPDATE bank_accounts
SET balance = balance - 500
WHERE account_id = 101;

-- Create a savepoint named 'sp1' to mark this valid intermediate state
SAVEPOINT sp1;

-- Step 2: Attempt to deduct 20000 from Rahul's account (unwanted/failing operation)
UPDATE bank_accounts
SET balance = balance - 20000
WHERE account_id = 101;

-- Undo the 20000 deduction by rolling back to savepoint 'sp1' (keeps the 500 deduction)
ROLLBACK TO SAVEPOINT sp1;

-- Step 3: Add the 500 to Aman's account
UPDATE bank_accounts
SET balance = balance + 500
WHERE account_id = 102;

-- Commit the remaining valid operations (the 500 transfer from Rahul to Aman)
COMMIT;

-- Display the final balances after partial rollback and commit
SELECT * FROM bank_accounts;


-- Set the isolation level for the upcoming transaction to SERIALIZABLE
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Start the transaction
START TRANSACTION;

-- Read the current account records under SERIALIZABLE isolation
SELECT * FROM bank_accounts;

-- End and commit the transaction
COMMIT;


-- ========================
-- [Run in Session 1 Window]
-- ========================

-- Start a transaction in Session 1
BEGIN;

-- Update Rahul's balance to 9000, but DO NOT commit yet
UPDATE bank_accounts
SET balance = 9000
WHERE account_id = 101;
-- Do not commit yet.


-- ========================
-- [Run in Session 2 Window]
-- ========================

-- Start a transaction in Session 2 with READ COMMITTED isolation level
BEGIN TRANSACTION
ISOLATION LEVEL READ COMMITTED;

-- Read Rahul's balance (returns the last committed value, preventing a dirty read)
SELECT balance
FROM bank_accounts
WHERE account_id = 101;

-- Commit Session 2's transaction
COMMIT;
