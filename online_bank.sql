ALTER ROLE postgres WITH PASSWORD 'SCRAM-SHA-256$4096:gqxolfd6HK9v3oACViTiIw==$dkXeMym0KplMhx52Yeou1etQzLtLX5I++0Z83KiB6sQ=:HpEcsfpkfIpto7iZ9MIJK0GJc2scjLwAv7SYyAbwbUg=';

-- Creating roles for the database system
CREATE ROLE l1 WITH CREATEDB CREATEROLE SUPERUSER;
CREATE ROLE l2 WITH CREATEROLE;
CREATE ROLE l3 WITH CREATEROLE;
CREATE ROLE l4;
CREATE ROLE l5;

-- Creating users for application access
CREATE ROLE unauthenticated WITH LOGIN PASSWORD 'unauthenticated';
CREATE ROLE user_banking WITH LOGIN PASSWORD 'mobile_banking';
CREATE ROLE user_banking_protection;
CREATE ROLE employee WITH LOGIN PASSWORD 'employee';
CREATE ROLE manager WITH LOGIN PASSWORD 'manager';

-- Granting role based access to users
GRANT l1 TO postgres;
GRANT l1 TO user_banking_protection;
GRANT l2 TO manager;
GRANT l3 TO employee;
GRANT l4 TO user_banking;
GRANT l5 TO unauthenticated;

-- Dropping tables if they already exist
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS online_account;
DROP TABLE IF EXISTS user_login;
DROP TABLE IF EXISTS user_login_security_question;
DROP TABLE IF EXISTS security_question_option;
DROP TABLE IF EXISTS security_question_answer;
DROP TABLE IF EXISTS savings_account;
DROP TABLE IF EXISTS credit_account;
DROP TABLE IF EXISTS debit_account;
DROP TABLE IF EXISTS loan;
DROP TABLE IF EXISTS savings_statement;
DROP TABLE IF EXISTS credit_account_application;
DROP TABLE IF EXISTS credit_statement;
DROP TABLE IF EXISTS debit_statement;
DROP TABLE IF EXISTS debit_overdraft;
DROP TABLE IF EXISTS transaction;
DROP TABLE IF EXISTS loan_application;
DROP TABLE IF EXISTS loan_statement;
DROP TABLE IF EXISTS external_account;
DROP TABLE IF EXISTS authentication_log;
DROP TABLE IF EXISTS management_log;

-- Creating customer table
CREATE TABLE IF NOT EXISTS customer (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    date_of_birth DATE,
    phone_number VARCHAR(255),
    email_address VARCHAR(255),
    address_street VARCHAR(255),
    address_city VARCHAR(255),
    address_county VARCHAR(255),
    address_postcode VARCHAR(255),
    is_verified BOOLEAN DEFAULT FALSE
);

-- Creating online_account table
CREATE TABLE IF NOT EXISTS online_account (
    id SERIAL PRIMARY KEY,
    date_opened DATE,
    sort_code INT,
    customer_id INT REFERENCES customer(id)
);

-- Creating user_login table
CREATE TABLE IF NOT EXISTS user_login (
    id SERIAL PRIMARY KEY,
    account_id INT REFERENCES online_account(id),
    username VARCHAR(255),
    password VARCHAR(255)
);

-- Creating security_question_option table
CREATE TABLE IF NOT EXISTS security_question_option (
    id SERIAL PRIMARY KEY,
    question_description VARCHAR(255)
);

-- Creating user_login_security_question table
CREATE TABLE IF NOT EXISTS user_login_security_question (
    id SERIAL PRIMARY KEY,
    question_choice_id INT REFERENCES security_question_option(id),
    login_id INT REFERENCES user_login(id)
);

-- Creating security_question_answer table
CREATE TABLE IF NOT EXISTS security_question_answer (
    id SERIAL PRIMARY KEY,
    question_answer VARCHAR(255),
    question_id INT REFERENCES user_login_security_question(id)
);

-- Creating account table
CREATE TABLE IF NOT EXISTS account (
    account_number SERIAL PRIMARY KEY,
    account_id INT REFERENCES online_account(id),
    CONSTRAINT account_number_8_digits CHECK (account_number::text ~ '^[0-9]{8}$')
);

-- Creating savings_account table
CREATE TABLE IF NOT EXISTS savings_account (
    current_balance NUMERIC(15, 2),
    interest_rate NUMERIC(5,2),
    PRIMARY KEY (account_number)
) INHERITS (account);

-- Creating credit_account table
CREATE TABLE IF NOT EXISTS credit_account (
    outstanding_balance NUMERIC(15, 2),
    credit_limit NUMERIC(15, 2),
    interest_rate NUMERIC(5,2),
    PRIMARY KEY (account_number)
) INHERITS (account);

-- Creating debit_account table
CREATE TABLE IF NOT EXISTS debit_account (
    current_balance NUMERIC(15, 2),
    interest_rate NUMERIC(5,2),
    PRIMARY KEY (account_number)
) INHERITS (account);

-- Creating loan table
CREATE TABLE IF NOT EXISTS loan (
    id SERIAL PRIMARY KEY,
    amount NUMERIC(15, 2),
    end_date DATE,
    loan_type VARCHAR,
    interest_rate NUMERIC(5,2),
    account_id INT REFERENCES online_account(id)
);

-- Creating savings_statement table
CREATE TABLE IF NOT EXISTS savings_statement (
    id SERIAL PRIMARY KEY,
    starting_date DATE,
    end_date DATE,
    amount NUMERIC(15,2),
    account_number INT REFERENCES savings_account(account_number)
);

-- Creating credit_account_application table
CREATE TABLE IF NOT EXISTS credit_account_application (
    id SERIAL PRIMARY KEY,
    application_status VARCHAR,
    account_number INT REFERENCES credit_account(account_number)
);

-- Creating credit_statement table
CREATE TABLE IF NOT EXISTS credit_statement (
    id SERIAL PRIMARY KEY,
    starting_date DATE,
    end_date DATE,
    amount NUMERIC(15,2),
    minimum_payment NUMERIC(15,2),
    minimum_payment_due_date DATE,
    account_number INT REFERENCES credit_account(account_number)
);

-- Creating debit_statement table
CREATE TABLE IF NOT EXISTS debit_statement (
    id SERIAL PRIMARY KEY,
    starting_date DATE,
    end_date DATE,
    amount NUMERIC(15,2),
    account_number INT REFERENCES debit_account(account_number)
);

-- Creating debit_overdraft table
CREATE TABLE IF NOT EXISTS debit_overdraft (
    id SERIAL PRIMARY KEY,
    overdraft_usage NUMERIC(15, 2),
    overdraft_limit NUMERIC(15, 2),
    interest_rate NUMERIC(5,2),
    approved BOOLEAN,
    account_number INT REFERENCES debit_account(account_number)
);

-- Creating transaction table
CREATE TABLE IF NOT EXISTS transaction (
    id SERIAL PRIMARY KEY,
    origin_account_id INT,
    dest_account_id INT,
    dest_account_sort_code INT,
    amount NUMERIC(15, 2),
    date DATE,
    savings_statement_id INT REFERENCES savings_statement(id),
    credit_statement_id INT REFERENCES credit_statement(id),
    debit_statement_id INT REFERENCES debit_statement(id),
    approved BOOLEAN
);

-- Creating pending_transaction table
CREATE TABLE IF NOT EXISTS pending_transaction (
    id SERIAL PRIMARY KEY REFERENCES transaction(id),
    account_id INT,
    is_transfer BOOLEAN,
    is_loan_payment BOOLEAN
);

-- Creating loan_application table
CREATE TABLE IF NOT EXISTS loan_application (
    id SERIAL PRIMARY KEY,
    application_status VARCHAR,
    loan_id INT REFERENCES loan(id),
    amount NUMERIC(15,2)
);

-- Creating loan_statement table
CREATE TABLE IF NOT EXISTS loan_statement (
    id SERIAL PRIMARY KEY,
    starting_date DATE,
    amount NUMERIC(15,2),
    loan_id INT REFERENCES loan(id)
);

-- Creating loan_payment table
CREATE TABLE IF NOT EXISTS loan_payment (
    id SERIAL PRIMARY KEY,
    amount NUMERIC(15,2),
    date DATE,
    approved BOOLEAN,
    loan_id INT REFERENCES loan(id)
);

-- Creating authentication_log table
CREATE TABLE IF NOT EXISTS authentication_log (
    id SERIAL PRIMARY KEY,
    log_description VARCHAR,
    log_date DATE,
    account_id INT REFERENCES online_account(id)
);

-- Creating management_log table
CREATE TABLE IF NOT EXISTS management_log (
    id SERIAL PRIMARY KEY,
    log_description VARCHAR,
    log_date DATE,
    account_id INT REFERENCES online_account(id)
);

-- Creating staff_log table
CREATE TABLE IF NOT EXISTS staff_log (
    id SERIAL PRIMARY KEY,
    log_description VARCHAR,
    log_date DATE,
    staff_name VARCHAR
);

-- Creating triggers for the necessary tables

-- Creating a trigger function to mimic a foreign key constraint for the account table inheritence system
CREATE OR REPLACE FUNCTION pseudo_fk_account_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM account WHERE account_number = NEW.account_id) THEN
        RAISE NOTICE 'account_id % does not exist', NEW.account_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Creating a trigger to call the pseudo_fk_account_id function
CREATE TRIGGER pseudo_fk_account_id
BEFORE INSERT OR UPDATE ON pending_transaction
FOR EACH ROW EXECUTE PROCEDURE pseudo_fk_account_id();


-- Creating a trigger function to begin the automated bank verification system
CREATE OR REPLACE FUNCTION transaction_verification()
RETURNS TRIGGER AS $$
DECLARE passed BOOLEAN;
BEGIN
    IF NEW.id IS NOT NULL THEN
        SELECT * FROM bank.verify_transaction(NEW.id) INTO passed;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a trigger to call the transaction_verification function whenever a new transaction is added to the pending_transaction table
CREATE TRIGGER transaction_verification
AFTER INSERT OR UPDATE ON pending_transaction
FOR EACH ROW EXECUTE PROCEDURE transaction_verification();

-- Creating a function to return the next valid account number for the account table
CREATE OR REPLACE FUNCTION get_next_account_number()
RETURNS INT AS $$
DECLARE next_account_number INT;
BEGIN
    SELECT MAX(account_number) INTO next_account_number FROM account;
    IF next_account_number IS NULL THEN
        next_account_number = 10000000;
    ELSE
        next_account_number = next_account_number + 1;
    END IF;
    RETURN next_account_number;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a function to return the account type as a text data type for a given account id
CREATE OR REPLACE FUNCTION get_account_type(account_number_identifier INT)
RETURNS TEXT AS $$
DECLARE account_type TEXT;
BEGIN
    SELECT CASE WHEN EXISTS (SELECT * FROM debit_account WHERE account_number = account_number_identifier) THEN 'DEBIT'
                WHEN EXISTS (SELECT * FROM credit_account WHERE account_number = account_number_identifier) THEN 'CREDIT'
                WHEN EXISTS (SELECT * FROM savings_account WHERE account_number = account_number_identifier) THEN 'SAVINGS'
                ELSE 'UNKNOWN' END INTO account_type;
    RETURN account_type;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE EXTENSION pgcrypto;



-- Creating a function to return a valid customer id for a given username
CREATE OR REPLACE FUNCTION policy_customer_client_check(user_fullname TEXT)
RETURNS INT AS $$
DECLARE
    allowed_customer_id INT;
BEGIN
    SELECT customer_id INTO allowed_customer_id FROM customer
    INNER JOIN online_account ON customer.id = online_account.customer_id
    INNER JOIN user_login ON online_account.id = user_login.account_id
    WHERE user_login.username = user_fullname;
    RETURN allowed_customer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a policy to restrict access to the customer table for select statements
CREATE POLICY policy_customer_client ON customer
    FOR SELECT TO user_banking_protection USING (id = policy_customer_client_check(session_user));

-- Creating a policy to restrict access to the customer table for update statements
CREATE POLICY policy_customer_client_update ON customer
    FOR UPDATE TO user_banking_protection USING (id = policy_customer_client_check(session_user));

-- Enabling row level security for the customer table
ALTER TABLE customer ENABLE ROW LEVEL SECURITY;

-- Creating a function to return a valid online account id for a given username
CREATE OR REPLACE FUNCTION policy_online_account_client_check(user_fullname TEXT)
RETURNS INT AS $$
DECLARE
    allowed_online_account_id INT;
BEGIN
    SELECT online_account.id INTO allowed_online_account_id FROM online_account
    INNER JOIN user_login ON online_account.id = user_login.account_id
    WHERE user_login.username = user_fullname;
    RETURN allowed_online_account_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a policy to restrict access to the online_account table for select statements
CREATE POLICY policy_online_account_client ON online_account
    FOR SELECT TO user_banking_protection USING (id = policy_online_account_client_check(session_user));

-- Enabling row level security for the online_account table
ALTER TABLE online_account ENABLE ROW LEVEL SECURITY;

-- Creating a function to return a valid user login id for a given username
CREATE OR REPLACE FUNCTION policy_user_login_client_check(user_fullname TEXT)
RETURNS INT AS $$
DECLARE
    allowed_user_login_id INT;
BEGIN
    SELECT id INTO allowed_user_login_id FROM user_login
    WHERE user_login.username = user_fullname;
    RETURN allowed_user_login_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a policy to restrict access to the user_login table for select statements
CREATE POLICY policy_user_login_client ON user_login
    FOR SELECT TO user_banking_protection USING (id = policy_user_login_client_check(session_user));

-- Enabling row level security for the user_login table
ALTER TABLE user_login ENABLE ROW LEVEL SECURITY;

-- Creating a function to return a valid account id for a given username
CREATE OR REPLACE FUNCTION policy_account_client_check(user_fullname TEXT)
RETURNS INT AS $$
DECLARE
    allowed_account_id INT;
BEGIN
    SELECT account_id INTO allowed_account_id FROM online_account
    INNER JOIN user_login ON online_account.id = user_login.account_id
    WHERE user_login.username = user_fullname;
    RETURN allowed_account_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a policy to restrict access to the account table for select statements
CREATE POLICY policy_account_client ON account
    FOR SELECT TO user_banking_protection USING (account_id = policy_account_client_check(session_user));

-- Enabling row level security for the account table
ALTER TABLE account ENABLE ROW LEVEL SECURITY;

-- Creating a policy to restrict access to the savings_account table for select statements
CREATE POLICY policy_savings_account_client ON savings_account
    FOR SELECT TO user_banking_protection USING (account_id = policy_account_client_check(session_user));

-- Enabling row level security for the savings_account table
ALTER TABLE savings_account ENABLE ROW LEVEL SECURITY;

-- Creating a policy to restrict access to the current_account table for select statements
CREATE POLICY policy_credit_account_client ON credit_account
    FOR SELECT TO user_banking_protection USING (account_id = policy_account_client_check(session_user));

-- Enabling row level security for the current_account table
ALTER TABLE credit_account ENABLE ROW LEVEL SECURITY;

-- Creating a policy to restrict access to the debit_account table for select statements
CREATE POLICY policy_debit_account_client ON debit_account
    FOR SELECT TO user_banking_protection USING (account_id = policy_account_client_check(session_user));

-- Enabling row level security for the debit_account table
ALTER TABLE debit_account ENABLE ROW LEVEL SECURITY;


-- Creating a schema for the bank automated functions and views
CREATE SCHEMA IF NOT EXISTS bank;
SET search_path TO public, bank, client;

-- Creating a view to return all accounts with their online account sort code
CREATE OR REPLACE VIEW bank.accounts AS
    SELECT account.account_number, account.account_id, online_account.sort_code
    FROM account
    INNER JOIN online_account ON account.account_id = online_account.id;

-- Creating a view to return all pending transactions
CREATE OR REPLACE VIEW bank.pending_transactions AS
    SELECT pending_transaction.id, pending_transaction.is_transfer, pending_transaction.is_loan_payment, transaction.origin_account_id, transaction.dest_account_id, transaction.dest_account_sort_code as sort_code, transaction.amount, transaction.date, get_account_type(transaction.origin_account_id) AS origin_account_type
    FROM pending_transaction
    INNER JOIN transaction ON pending_transaction.id = transaction.id;

-- Creating a function to update balance amounts for a given loan id and payment amount
CREATE OR REPLACE FUNCTION bank.update_loan_amounts(loan_id INT, payment_amount NUMERIC)
RETURNS BOOLEAN AS $$
DECLARE loan_updated BOOLEAN;
BEGIN
    IF EXISTS (SELECT * FROM loan WHERE id = loan_id AND amount - payment_amount < 0) THEN
        RAISE NOTICE 'LOAN OVERPAID';
        loan_updated = FALSE;
    ELSE
        UPDATE loan SET amount = amount - payment_amount WHERE id = loan_id;
        loan_updated = TRUE;
    END IF;
    RETURN loan_updated;
END;
$$ LANGUAGE plpgsql;

-- Creating a function to update balance amounts for a given account number and amount
CREATE OR REPLACE FUNCTION bank.update_balance_amounts(account_number_identifier INT, amount NUMERIC)
RETURNS BOOLEAN AS $$
DECLARE balances_updated BOOLEAN;
DECLARE account_type TEXT;
DECLARE current_balance_v NUMERIC;
BEGIN
    --checks the account type using the get account type function
    SELECT get_account_type(account_number_identifier) INTO account_type;
    IF account_type = 'DEBIT' THEN

        --checks whether for the given account type, sufficient funds are available
        IF EXISTS (SELECT * FROM debit_account WHERE account_number = account_number_identifier AND (current_balance + (SELECT COALESCE(0, (SELECT overdraft_limit - overdraft_usage FROM debit_overdraft WHERE account_number = account_number_identifier AND approved = TRUE)))) - amount >= 0) THEN
            RAISE NOTICE 'SUFFICIENT FUNDS';
            UPDATE debit_account SET current_balance = current_balance - amount WHERE account_number = account_number_identifier;
            UPDATE debit_overdraft SET overdraft_usage = overdraft_usage - (SELECT SUM(current_balance*-1) FROM debit_account WHERE account_number = account_number_identifier) WHERE account_number = account_number_identifier AND approved = TRUE;
            UPDATE debit_account SET current_balance = 0 WHERE account_number = account_number_identifier AND current_balance < 0;
            balances_updated = TRUE;
        ELSE
        --raises a notice if insufficient funds are available
            RAISE NOTICE 'INSUFFICIENT FUNDS';
            RAISE NOTICE 'AMOUNT REQUESTED: %', amount;
            balances_updated = FALSE;
        END IF;

    ELSIF account_type = 'CREDIT' THEN
        IF EXISTS (SELECT credit_account.* FROM credit_account INNER JOIN credit_account_application ON credit_account.account_number = credit_account_application.account_number WHERE credit_account.account_number = account_number_identifier AND credit_account.outstanding_balance + amount < credit_account.credit_limit AND credit_account_application.application_status = 'APPROVED') THEN
            RAISE NOTICE 'SUFFICIENT CREDIT';
            UPDATE credit_account SET outstanding_balance = outstanding_balance - amount WHERE account_number = account_number_identifier;
            balances_updated = TRUE;
        ELSE
            RAISE NOTICE 'CREDIT LIMIT EXCEEDED';
            balances_updated = FALSE;
        END IF;
    ELSIF account_type = 'SAVINGS' THEN
        IF EXISTS (SELECT * FROM savings_account WHERE account_number = account_number_identifier AND current_balance - amount < 0) THEN
            RAISE NOTICE 'INSUFFICIENT FUNDS';
            
            balances_updated = FALSE;
        ELSE
            RAISE NOTICE 'SUFFICIENT FUNDS';
            UPDATE savings_account SET current_balance = current_balance - amount WHERE account_number = account_number_identifier;
            balances_updated = TRUE;
        END IF;
    END IF;
    RETURN balances_updated;
END;
$$ LANGUAGE plpgsql;

-- Creating a function to verify and update transaction amounts
CREATE OR REPLACE FUNCTION bank.verify_and_update_transaction_amounts(pending_transaction_id INT, is_transfer BOOLEAN, is_loan_payment BOOLEAN)
RETURNS BOOLEAN AS $$
DECLARE transaction_approved BOOLEAN;
DECLARE account_type TEXT;
DECLARE statement_id INT;
BEGIN

    -- checks if the destination account number is contained within the online account system or it is external
    IF EXISTS (SELECT * FROM bank.accounts WHERE account_number = (SELECT dest_account_id FROM bank.pending_transactions WHERE id = pending_transaction_id) AND sort_code = (SELECT sort_code FROM bank.pending_transactions WHERE id = pending_transaction_id)) OR is_loan_payment THEN
        RAISE NOTICE 'INTERNAL TRANSFER OCCURING';

        -- checks if the transaction is a loan payment
        IF is_loan_payment = TRUE THEN
            IF bank.update_balance_amounts((SELECT origin_account_id FROM transaction WHERE id = pending_transaction_id), (SELECT amount FROM bank.pending_transactions WHERE id = pending_transaction_id)) = TRUE THEN
                IF bank.update_loan_amounts((SELECT dest_account_id FROM transaction WHERE id = pending_transaction_id), (SELECT amount FROM bank.pending_transactions WHERE id = pending_transaction_id)) THEN
                    transaction_approved = TRUE;
                END IF;
            ELSE
                transaction_approved = FALSE;
            END IF;

            DELETE FROM pending_transaction WHERE id = pending_transaction_id;

        -- checks if the transaction is a transfer
        ELSIF is_transfer = TRUE THEN
            IF bank.update_balance_amounts((SELECT origin_account_id FROM transaction WHERE id = pending_transaction_id), (SELECT amount FROM bank.pending_transactions WHERE id = pending_transaction_id)) = TRUE THEN
                IF bank.update_balance_amounts((SELECT dest_account_id FROM transaction WHERE id = pending_transaction_id), (SELECT SUM(amount*-1) FROM bank.pending_transactions WHERE id = pending_transaction_id)) THEN
                    transaction_approved = TRUE;
                END IF;
            ELSE
                transaction_approved = FALSE;
            END IF;

            DELETE FROM pending_transaction WHERE id = pending_transaction_id;

        -- otherwise a simple transaction is occuring
        ELSE
            IF bank.update_balance_amounts((SELECT origin_account_id FROM transaction WHERE id = pending_transaction_id), (SELECT amount FROM bank.pending_transactions WHERE id = pending_transaction_id)) = TRUE THEN
                transaction_approved = TRUE;
            ELSE
                transaction_approved = FALSE;
            END IF;

            DELETE FROM pending_transaction WHERE id = pending_transaction_id;
        END IF;
    ELSE
        -- checks if the transaction is external
        RAISE NOTICE 'EXTERNAL TRANSFER OCCURING';
        IF bank.update_balance_amounts((SELECT origin_account_id FROM transaction WHERE id = pending_transaction_id), (SELECT amount FROM bank.pending_transactions WHERE id = pending_transaction_id)) THEN
            transaction_approved = TRUE;
        ELSE
            transaction_approved = FALSE;
        DELETE FROM pending_transaction WHERE id = pending_transaction_id;
        END IF;
    END IF;


    RETURN transaction_approved;
END;
$$ LANGUAGE plpgsql;

-- Creating a function to verify the type of transaction occuring
CREATE OR REPLACE FUNCTION bank.verify_transaction_type(pending_transaction_id INT)
RETURNS BOOLEAN AS $$
DECLARE transaction_approved BOOLEAN;
BEGIN
    -- check pending transaction exists
    IF EXISTS (SELECT * FROM bank.pending_transactions) THEN
        
        -- checks if the transaction is a transfer
        IF EXISTS (SELECT * FROM bank.pending_transactions WHERE id = pending_transaction_id AND is_transfer = TRUE AND is_loan_payment = FALSE) THEN
            RAISE NOTICE 'Transfer transaction';
            SELECT * FROM bank.verify_and_update_transaction_amounts(pending_transaction_id, TRUE, FALSE) INTO transaction_approved;
        --checks if the transaction is a loan payment
        ELSIF EXISTS (SELECT * FROM bank.pending_transactions WHERE id = pending_transaction_id AND is_loan_payment = TRUE) THEN
            RAISE NOTICE 'Loan payment transaction';
            SELECT * FROM bank.verify_and_update_transaction_amounts(pending_transaction_id, FALSE, TRUE) INTO transaction_approved;
        -- checks if the transaction is a simple payment
        ELSIF EXISTS (SELECT * FROM bank.pending_transactions WHERE id = pending_transaction_id AND is_transfer = FALSE) THEN
            RAISE NOTICE 'Payment transaction';
            SELECT * FROM bank.verify_and_update_transaction_amounts(pending_transaction_id, FALSE, FALSE) INTO transaction_approved;
        ELSE
            RAISE NOTICE 'Unknown transaction type';
            transaction_approved = FALSE;
        END IF;
    ELSE
        RAISE NOTICE 'Transaction does not exist';
        transaction_approved = FALSE;
    END IF;
    RETURN transaction_approved;
END;
$$ LANGUAGE plpgsql;

-- Creating a function to begin the transaction verification process
CREATE OR REPLACE FUNCTION bank.verify_transaction(pending_transaction_id INT)
RETURNS BOOLEAN AS $$
DECLARE transaction_approved BOOLEAN;
DECLARE account_type TEXT;
BEGIN
    -- check pending transaction exists
    IF bank.verify_transaction_type(pending_transaction_id) = TRUE THEN
        RAISE NOTICE 'Transaction approved';
        transaction_approved = TRUE;
    ELSE
        RAISE NOTICE 'Transaction not approved';
        transaction_approved = FALSE;
    END IF;
    RETURN transaction_approved;
END;
$$ LANGUAGE plpgsql;

-- Creating a schema for the staff to include employee specfic functions and views
CREATE SCHEMA IF NOT EXISTS staff;
SET search_path TO public, staff, client;

-- Creating a view which gives a comprehesive outlook on the accounts that exist for each client
CREATE OR REPLACE VIEW staff.accounts AS
    SELECT customer.first_name, customer.last_name, account.account_number, account.account_id, online_account.sort_code,
    COALESCE(debit_account.current_balance, credit_account.outstanding_balance, savings_account.current_balance) AS balance,
    COALESCE(debit_account.interest_rate, credit_account.interest_rate, savings_account.interest_rate) AS interest_rate,
    get_account_type(account.account_number) AS account_type
    FROM customer
    LEFT JOIN online_account ON online_account.customer_id = customer.id
    LEFT JOIN account ON account.account_id = online_account.id
    LEFT JOIN credit_account ON account.account_number = credit_account.account_number
    LEFT JOIN debit_account ON account.account_number = debit_account.account_number
    LEFT JOIN savings_account ON account.account_number = savings_account.account_number;

-- Creating a view which provides all credit account applications
CREATE OR REPLACE VIEW staff.credit_account_applications AS
    SELECT credit_account_application.id, credit_account_application.application_status, credit_account.account_number, credit_account.outstanding_balance, credit_account.credit_limit, credit_account.interest_rate
    FROM credit_account_application
    INNER JOIN credit_account ON credit_account_application.account_number = credit_account.account_number;

-- Creating a view which provides all loan applications
CREATE OR REPLACE VIEW staff.loan_applications AS
    SELECT loan_application.id, loan_application.application_status, loan.id as loan_id, loan.amount, loan.end_date, loan.loan_type, loan.interest_rate, loan.account_id
    FROM loan_application
    INNER JOIN loan ON loan_application.loan_id = loan.id;

-- Creating a view which provides details on all online accounts for the bank
CREATE OR REPLACE VIEW staff.customers AS
    SELECT online_account.id as account_id, customer.first_name, customer.last_name
    FROM online_account
    INNER JOIN customer ON customer.id = online_account.customer_id;

-- Creating a view which provides details for all personal information for each client
CREATE OR REPLACE VIEW staff.customer_personal_information AS
    SELECT * FROM customer;

-- Creating a view which provides all debit overdrafts
CREATE OR REPLACE VIEW staff.overdrafts AS
    SELECT customers.first_name, customers.last_name, debit_overdraft.id, debit_overdraft.account_number, debit_overdraft.overdraft_usage, debit_overdraft.overdraft_limit, debit_overdraft.interest_rate
    FROM debit_overdraft
    INNER JOIN staff.accounts ON staff.accounts.account_number = debit_overdraft.account_number
    INNER JOIN staff.customers ON staff.customers.account_id = staff.accounts.account_id;

-- Creating a function which returns all customers details who are unverified
CREATE OR REPLACE FUNCTION staff.review_unverified_customer_personal_information()
RETURNS TABLE(id INT,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    date_of_birth DATE,
    phone_number VARCHAR(255),
    email_address VARCHAR(255),
    address_street VARCHAR(255),
    address_city VARCHAR(255),
    address_county VARCHAR(255),
    address_postcode VARCHAR(255),
    verified BOOLEAN) AS $$
BEGIN
    INSERT INTO staff_log(log_description, log_date, staff_name) VALUES ('Reviewing unverified customer personal information', NOW(), CURRENT_USER);

    RETURN QUERY SELECT *
    FROM staff.customer_personal_information
    WHERE is_verified = FALSE
    ORDER BY id;
END;
$$ LANGUAGE plpgsql;

-- Creating a function which verified a customer's personal information for a given customer id
CREATE OR REPLACE FUNCTION staff.verify_customer_personal_information(customer_id INT)
RETURNS BOOLEAN AS $$
DECLARE customer_verified BOOLEAN;
BEGIN
    INSERT INTO staff_log(log_description, log_date, staff_name) VALUES ('Verifying customer personal information for customer', NOW(), CURRENT_USER);

    IF EXISTS (SELECT * FROM staff.customer_personal_information WHERE id = customer_id) THEN
        UPDATE customer
        SET is_verified = TRUE
        WHERE id = customer_id;
        customer_verified = TRUE;
    ELSE
        customer_verified = FALSE;
    END IF;
    RETURN customer_verified;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a function which returns all credit applications which are pending
CREATE OR REPLACE FUNCTION staff.view_outstanding_credit_applications()
RETURNS TABLE(first_name TEXT, last_name TEXT, account_number INT) AS $$
BEGIN
    INSERT INTO staff_log(log_description, log_date, staff_name) VALUES ('Viewing outstanding credit applications', NOW(), CURRENT_USER);

    RETURN QUERY SELECT customers.first_name, customers.last_name, credit_account_applications.account_number
    FROM staff.customers
    INNER JOIN staff.accounts ON customers.account_id = accounts.account_id
    INNER JOIN staff.credit_account_applications ON accounts.account_number = credit_card_applications.account_number
    WHERE credit_card_applications.application_status = 'PENDING';
END;
$$ LANGUAGE plpgsql;

-- Creating a function which allows a member of staff to approve or deny a credit application
CREATE OR REPLACE FUNCTION staff.approve_or_deny_credit_application(account_number_p INT, application_approved_p BOOLEAN)
RETURNS BOOLEAN AS $$
DECLARE application_approved BOOLEAN;
BEGIN
    INSERT INTO staff_log(log_description, log_date, staff_name) VALUES ('Approving or denying credit application', NOW(), CURRENT_USER);

    IF EXISTS (SELECT * FROM staff.credit_account_applications WHERE account_number = account_number_p) THEN
        IF application_approved_p = TRUE THEN
            UPDATE credit_account_application
            SET application_status = 'APPROVED'
            WHERE account_number = account_number_p;
            application_approved = TRUE;
        ELSE
            UPDATE credit_account_application
            SET application_status = 'DENIED'
            WHERE account_number = account_number_p;
            application_approved = FALSE;
        END IF;
    ELSE
        application_approved = FALSE;
    END IF;
    RETURN application_approved;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a function which returns all loan applications which are pending
CREATE OR REPLACE FUNCTION staff.view_outstanding_loan_applications()
RETURNS TABLE(first_name TEXT, last_name TEXT, loan_id INT) AS $$
BEGIN
    INSERT INTO staff_log(log_description, log_date, staff_name) VALUES ('Viewing outstanding loan applications', NOW(), CURRENT_USER);

    RETURN QUERY SELECT customers.first_name, customers.last_name, loan_applications.id
    FROM staff.customers
    INNER JOIN staff.loan_applications ON loan_applications.account_id = customers.account_id
    WHERE loan_applications.application_status = 'PENDING';
END;
$$ LANGUAGE plpgsql;

-- Creating a function which allows a member of staff to approve or deny a loan application
CREATE OR REPLACE FUNCTION staff.approve_or_deny_loan_application(loan_id_p INT, application_approved_p BOOLEAN)
RETURNS BOOLEAN AS $$
DECLARE application_approved BOOLEAN;
BEGIN
    INSERT INTO staff_log(log_description, log_date, staff_name) VALUES ('Approving or denying loan application', NOW(), CURRENT_USER);

    IF EXISTS (SELECT * FROM staff.loan_applications WHERE id = loan_id_p) THEN
        IF application_approved_p = TRUE THEN
            UPDATE loan_application
            SET application_status = 'APPROVED'
            WHERE id = loan_id_p;
            application_approved = TRUE;
        ELSE
            UPDATE loan_application
            SET application_status = 'DENIED'
            WHERE id = loan_id_p;
            application_approved = FALSE;
        END IF;
    ELSE
        application_approved = FALSE;
    END IF;
    RETURN application_approved;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a function which returns all overdraft applications which are pending
CREATE OR REPLACE FUNCTION staff.view_outstanding_overdraft_applications()
RETURNS TABLE(first_name TEXT, last_name TEXT, overdraft_id INT, account_number INT, overdraft_usage NUMERIC, overdraft_limit NUMERIC, interest_rate NUMERIC) AS $$
BEGIN
    INSERT INTO staff_log(log_description, log_date, staff_name) VALUES ('Viewing outstanding overdraft applications', NOW(), CURRENT_USER);

    SELECT * FROM staff.overdrafts
    WHERE overdraft_approved = FALSE;
END;
$$ LANGUAGE plpgsql;

-- Creating a function which allows a member of staff to approve or deny an overdraft application
CREATE OR REPLACE FUNCTION staff.approve_or_deny_overdraft_application(overdraft_id INT, application_approved BOOLEAN)
RETURNS BOOLEAN AS $$
DECLARE application_approved BOOLEAN;
BEGIN
    INSERT INTO staff_log(log_description, log_date, staff_name) VALUES ('Approving or denying overdraft application', NOW(), CURRENT_USER);

    IF EXISTS (SELECT * FROM staff.overdrafts WHERE id = overdraft_id) THEN
        IF application_approved = TRUE THEN
            UPDATE debit_overdraft
            SET approved = TRUE
            WHERE id = overdraft_id;
            application_approved = TRUE;
        ELSE
            UPDATE debit_overdraft
            SET approved = FALSE
            WHERE id = overdraft_id;
            application_approved = FALSE;
        END IF;
    ELSE
        application_approved = FALSE;
    END IF;
    RETURN application_approved;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a function which allows a member of staff to update a customer's personal information
CREATE OR REPLACE FUNCTION staff.update_personal_information(account_identifier INT, first_name_p TEXT, last_name_p TEXT, date_of_birth_p DATE, phone_number_p TEXT, email_address_p TEXT, address_street_p TEXT, address_city_p TEXT, address_county_p TEXT, address_postcode_p TEXT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
BEGIN
    INSERT INTO staff_log(log_description, log_date, staff_name) VALUES ('Updating personal information', NOW(), CURRENT_USER);

    UPDATE customer SET first_name = first_name_p, last_name = last_name_p, date_of_birth = date_of_birth_p, phone_number = phone_number_p, email_address = email_address_p, address_street = address_street_p, address_city = address_city_p, address_county = address_county_p, address_postcode = address_postcode_p
    WHERE id = (SELECT customer_id FROM online_account WHERE id = account_identifier);

    passed = TRUE;
    RETURN passed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a function which allows a member of staff to update a client's login information
CREATE OR REPLACE FUNCTION staff.update_password(account_identifier INT, new_password TEXT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE ROW_COUNT INT;
BEGIN
    INSERT INTO staff_log(log_description, log_date, staff_name) VALUES ('Updating password', NOW(), CURRENT_USER);

    EXECUTE 'ALTER ROLE ' || (SELECT username FROM user_login WHERE account_id = account_identifier) || 'WITH PASSWORD ''' || new_password || ''';';

    UPDATE user_login SET password = (SELECT rolpassword FROM pg_authid WHERE rolname = username_p)
    WHERE account_id = account_identifier;
    GET DIAGNOSTICS ROW_COUNT = ROW_COUNT;
    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_identifier, 'Updated password', CURRENT_DATE);
    passed = CASE WHEN ROW_COUNT = 1 THEN TRUE ELSE FALSE END;
    RETURN passed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a function which allows a member of staff to update a client's email address
CREATE OR REPLACE FUNCTION staff.update_email(account_identifier INT, new_email TEXT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE ROW_COUNT INT;
BEGIN
    INSERT INTO staff_log(log_description, log_date, staff_name) VALUES ('Updating email', NOW(), CURRENT_USER);

    UPDATE user_login SET email = new_email
    WHERE account_id = account_identifier;

    GET DIAGNOSTICS ROW_COUNT = ROW_COUNT;

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_identifier, 'Updated email', CURRENT_DATE);
    passed = CASE WHEN ROW_COUNT = 1 THEN TRUE ELSE FALSE END;
    RETURN passed;
END;
$$ LANGUAGE plpgsql;

-- Creating a function which allows a member of staff open a dbit account for a customer
CREATE OR REPLACE FUNCTION staff.open_debit_account(account_id INT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE debit_account_number INT;
DECLARE next_account_number INT;
DECLARE ROW_COUNT INT;
BEGIN
    INSERT INTO staff_log(log_description, log_date, staff_name) VALUES ('Opening debit account', NOW(), CURRENT_USER);

    SELECT get_next_account_number() INTO next_account_number;

    INSERT INTO debit_account (account_number, account_id, current_balance, interest_rate) VALUES (next_account_number , account_id, 0, 0.01) RETURNING account_number INTO debit_account_number;
    GET DIAGNOSTICS ROW_COUNT = ROW_COUNT;
    INSERT INTO debit_statement (starting_date, end_date, amount, account_number) VALUES (date_trunc('month', now()::date), (date_trunc('month', now()::date)) + interval '1 month - 1 day', 0, debit_account_number);
    INSERT INTO debit_overdraft (overdraft_usage, overdraft_limit, interest_rate, account_number, approved) VALUES (0, 0, 0.01, debit_account_number, FALSE);
    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_id, 'Opened debit account', CURRENT_DATE);
    passed = CASE WHEN ROW_COUNT = 1 THEN TRUE ELSE FALSE END;
    RETURN passed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a function which allows a member of staff to open a credit account for a customer
CREATE OR REPLACE FUNCTION staff.open_credit_account(account_id INT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE credit_account_number INT;
DECLARE next_account_number INT;
DECLARE ROW_COUNT INT;
BEGIN
    INSERT INTO staff_log(log_description, log_date, staff_name) VALUES ('Opening credit account', NOW(), CURRENT_USER);

    SELECT get_next_account_number() INTO next_account_number;

    INSERT INTO credit_account (account_number, outstanding_balance, credit_limit, interest_rate, account_id) VALUES (next_account_number ,0, 1000, 24.9, account_id) RETURNING account_number INTO credit_account_number;
    GET DIAGNOSTICS ROW_COUNT = ROW_COUNT;
    INSERT INTO credit_statement (starting_date, end_date, amount, minimum_payment, minimum_payment_due_date, account_number) VALUES (date_trunc('month', now()::date), (date_trunc('month', now()::date)) + interval '1 month - 1 day', 0, 0, CURRENT_DATE, credit_account_number);
    INSERT INTO credit_account_application (account_number, application_status) VALUES (credit_account_number, 'PENDING');
    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_id, 'Opened credit account', CURRENT_DATE);
    passed = CASE WHEN ROW_COUNT = 1 THEN TRUE ELSE FALSE END;
    return PASSED;
END
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a function which allows a member of staff to open a savings account for a customer
CREATE OR REPLACE FUNCTION staff.open_savings_account(account_id INT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE savings_account_id INT;
DECLARE next_account_number INT;
DECLARE ROW_COUNT INT;
BEGIN
    INSERT INTO staff_log(log_description, log_date, staff_name) VALUES ('Opening savings account', NOW(), CURRENT_USER);

    SELECT get_next_account_number() INTO next_account_number;

    INSERT INTO savings_account (account_number, account_id, current_balance, interest_rate) VALUES (next_account_number ,account_id, 10000, 0.01) RETURNING account_number INTO savings_account_id;
    GET DIAGNOSTICS ROW_COUNT = ROW_COUNT;
    INSERT INTO savings_statement (starting_date, end_date, amount, account_number) VALUES (date_trunc('month', now()::date), (date_trunc('month', now()::date)) + interval '1 month - 1 day', 0, savings_account_id);
    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_id, 'Opened savings account', CURRENT_DATE);
    passed = CASE WHEN ROW_COUNT = 1 THEN TRUE ELSE FALSE END;
    RETURN passed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a function which allows a member of staff to open a loan for a customer
CREATE OR REPLACE FUNCTION staff.open_loan(account_id INT, loan_amount NUMERIC, loan_end_date DATE, loan_type TEXT, loan_interest_rate NUMERIC)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE loan_id INT;
DECLARE ROW_COUNT INT;
BEGIN
    INSERT INTO staff_log(log_description, log_date, staff_name) VALUES ('Opening loan', NOW(), CURRENT_USER);

    INSERT INTO loan (account_id, amount, end_date, loan_type, interest_rate) VALUES (account_id, 0, loan_end_date, loan_type, loan_interest_rate) RETURNING id INTO loan_id;
    GET DIAGNOSTICS ROW_COUNT = ROW_COUNT;
    INSERT INTO loan_statement (starting_date, amount, loan_id) VALUES (date_trunc('month', now()::date), 0, loan_id);
    INSERT INTO loan_application (loan_id, application_status, amount) VALUES (loan_id, 'PENDING', loan_amount);
    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_id, 'Opened loan', CURRENT_DATE);
    passed = CASE WHEN ROW_COUNT = 1 THEN TRUE ELSE FALSE END;
    RETURN passed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a function which allows a member of staff to open an overdraft application for a customer
CREATE OR REPLACE FUNCTION staff.open_overdraft_application(account_id INT, overdraft_limit NUMERIC)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE ROW_COUNT INT;
BEGIN
    INSERT INTO staff_log(log_description, log_date, staff_name) VALUES ('Opening overdraft application', NOW(), CURRENT_USER);

    INSERT INTO overdraft_application (account_id, application_status, overdraft_limit) VALUES (account_id, 'PENDING', overdraft_limit);
    GET DIAGNOSTICS ROW_COUNT = ROW_COUNT;
    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_id, 'Opened overdraft application', CURRENT_DATE);
    passed = CASE WHEN ROW_COUNT = 1 THEN TRUE ELSE FALSE END;
    RETURN passed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a function which allows a member of staff to view the personal information of a customer
CREATE OR REPLACE FUNCTION staff.view_personal_information(account_id INT)
RETURNS TABLE (first_name TEXT, last_name TEXT, email TEXT, phone_number TEXT, address TEXT, city TEXT, country TEXT, postal_code TEXT) AS $$
BEGIN
    INSERT INTO staff_log(log_description, log_date, staff_name) VALUES ('Viewing personal information', NOW(), CURRENT_USER);

    RETURN QUERY
        SELECT first_name, last_name, email, phone_number, address, city, country, postal_code
            FROM customer
        INNER JOIN online_account ON online_account.customer_id = customer.id
        WHERE accounts.id = account_id;
END;
$$ LANGUAGE plpgsql;

-- Creating a function which allows a member of staff to view the debit accounts of a customer
CREATE OR REPLACE FUNCTION staff.view_debit_accounts(account_id INT)
RETURNS TABLE (id INT, current_balance NUMERIC, interest_rate NUMERIC, overdraft_limit NUMERIC, overdraft_usage NUMERIC, overdraft_interest_rate NUMERIC, external_account_number INT, overdraft_approved BOOLEAN) AS $$
BEGIN
    INSERT INTO staff_log(log_description, log_date, staff_name) VALUES ('Viewing debit accounts', NOW(), CURRENT_USER);

    RETURN QUERY
        SELECT * FROM debit_account WHERE account_id = account_id;
END;
$$ LANGUAGE plpgsql;

-- Creating a function which allows a member of staff to view the credit accounts of a customer
CREATE OR REPLACE FUNCTION staff.view_credit_accounts(account_id INT)
RETURNS TABLE (id INT, outstanding_balance NUMERIC, credit_limit NUMERIC, interest_rate NUMERIC, application_status TEXT) AS $$
BEGIN

    INSERT INTO staff_log(log_description, log_date, staff_name) VALUES ('Viewing credit accounts', NOW(), CURRENT_USER);

    RETURN QUERY
        SELECT * FROM credit_account WHERE account_id = account_id;
END;
$$ LANGUAGE plpgsql;

-- Creating a function which allows a member of staff to view the savings accounts of a customer
CREATE OR REPLACE FUNCTION staff.view_savings_accounts(account_id INT)
RETURNS TABLE (id INT, current_balance NUMERIC, interest_rate NUMERIC, external_account_number INT) AS $$
BEGIN

    INSERT INTO staff_log(log_description, log_date, staff_name) VALUES ('Viewing savings accounts', NOW(), CURRENT_USER);

    RETURN QUERY
        SELECT * FROM savings_account WHERE account_id = account_id;
END;
$$ LANGUAGE plpgsql;

-- Creating a function which allows a member of staff to view the loans of a customer
CREATE OR REPLACE FUNCTION staff.view_loans(account_id INT)
RETURNS TABLE (id INT, loan_amount NUMERIC, loan_end_date DATE, loan_type TEXT, loan_interest_rate NUMERIC, application_status TEXT) AS $$
BEGIN

    INSERT INTO staff_log(log_description, log_date, staff_name) VALUES ('Viewing loans', NOW(), CURRENT_USER);

    RETURN QUERY
        SELECT * FROM loan WHERE account_id = account_id;
END;
$$ LANGUAGE plpgsql;

-- Creating a schema to hold the functions and views for a client
CREATE SCHEMA IF NOT EXISTS client;
SET search_path TO public, client;

-- Creating a view which provides personal information for a client
CREATE OR REPLACE VIEW client.online_account_information AS
    SELECT * FROM online_account;

-- Creating a view which provides the accounts for a client
CREATE OR REPLACE VIEW client.accounts AS
    SELECT account.account_number, account.account_id, online_account.sort_code FROM account
    INNER JOIN online_account ON account.account_id = online_account.id;

-- Creating a view which provides the personal information for a client
CREATE OR REPLACE VIEW client.personal_information AS
    SELECT * FROM customer;

-- Creating a view which provides the debit accounts for a client
CREATE OR REPLACE VIEW client.debit_accounts AS
    SELECT accounts.account_id, accounts.account_number, (debit_account.current_balance + debit_overdraft.overdraft_usage*-1) as current_balance, debit_account.interest_rate, debit_overdraft.overdraft_limit, debit_overdraft.overdraft_usage, debit_overdraft.interest_rate AS overdraft_interest_rate, debit_overdraft.approved as overdraft_approved
    FROM client.accounts
    INNER JOIN debit_account ON accounts.account_number = debit_account.account_number
    INNER JOIN debit_overdraft ON accounts.account_number = debit_overdraft.account_number;

-- Creating a view which provdes the debit account statements for a client
CREATE OR REPLACE VIEW client.debit_accounts_statements AS
    SELECT debit_accounts.account_id, debit_accounts.account_number, debit_statement.id, debit_statement.starting_date, debit_statement.end_date, debit_statement.amount
    FROM debit_accounts
    INNER JOIN debit_statement ON debit_accounts.account_number = debit_statement.account_number;

-- Creating a view which provides the debit account transactions for a client
CREATE OR REPLACE VIEW client.debit_accounts_statement AS
    SELECT debit_accounts_statements.account_id, debit_accounts_statements.account_number, debit_accounts_statements.id, debit_accounts_statements.starting_date, debit_accounts_statements.end_date, debit_accounts_statements.amount AS total_amount, transaction.origin_account_id, transaction.dest_account_id, transaction.amount, transaction.date
    FROM debit_accounts_statements
    INNER JOIN transaction ON debit_accounts_statements.id = transaction.debit_statement_id;

-- Creating a view which provides the credit accounts for a client
CREATE OR REPLACE VIEW client.credit_accounts AS
    SELECT accounts.account_id, accounts.account_number, credit_account.outstanding_balance, credit_account.credit_limit, credit_account.interest_rate, credit_account_application.application_status
    FROM client.accounts
    INNER JOIN credit_account ON accounts.account_number = credit_account.account_number
    INNER JOIN credit_account_application ON accounts.account_number = credit_account_application.account_number;

-- Creating a view which provides the credit account statements for a client
CREATE OR REPLACE VIEW client.credit_accounts_statements AS
    SELECT credit_accounts.account_id, credit_accounts.account_number, credit_statement.id, credit_statement.starting_date, credit_statement.end_date, credit_statement.amount, credit_statement.minimum_payment, credit_statement.minimum_payment_due_date
    FROM credit_accounts
    INNER JOIN credit_statement ON credit_accounts.account_number = credit_statement.account_number;

-- Creating a view which provides the credit account transactions for a client
CREATE OR REPLACE VIEW client.credit_accounts_statement AS
    SELECT credit_accounts_statements.account_id, credit_accounts_statements.account_number, credit_accounts_statements.id, credit_accounts_statements.starting_date, credit_accounts_statements.end_date, credit_accounts_statements.amount AS total_amount, credit_accounts_statements.minimum_payment, credit_accounts_statements.minimum_payment_due_date, transaction.origin_account_id, transaction.dest_account_id, transaction.amount, transaction.date
    FROM credit_accounts_statements
    INNER JOIN transaction ON credit_accounts_statements.id = transaction.credit_statement_id;

-- Creating a view which provides the savings accounts for a client
CREATE OR REPLACE VIEW client.savings_accounts AS
    SELECT accounts.account_id, accounts.account_number, savings_account.current_balance, savings_account.interest_rate
    FROM client.accounts
    INNER JOIN savings_account ON accounts.account_number = savings_account.account_number;

-- Creating a view which provides the savings account statements for a client
CREATE OR REPLACE VIEW client.savings_accounts_statements AS
    SELECT savings_accounts.account_id, savings_accounts.account_number, savings_statement.id, savings_statement.starting_date, savings_statement.end_date, savings_statement.amount
    FROM savings_accounts
    INNER JOIN savings_statement ON savings_accounts.account_number = savings_statement.account_number;

-- Creating a view which provides the savings account transactions for a client
CREATE OR REPLACE VIEW client.savings_accounts_statement AS
    SELECT savings_accounts_statements.account_id, savings_accounts_statements.account_number, savings_accounts_statements.id, savings_accounts_statements.starting_date, savings_accounts_statements.end_date, savings_accounts_statements.amount AS total_amount, transaction.origin_account_id, transaction.dest_account_id, transaction.amount, transaction.date
    FROM savings_accounts_statements
    INNER JOIN transaction ON savings_accounts_statements.id = transaction.savings_statement_id;

-- Creating a view which provides the loans for a client
CREATE OR REPLACE VIEW client.loans AS
    SELECT loan.account_id, loan.id, loan.amount, loan.interest_rate, loan.loan_type, loan.end_date, loan_application.application_status
    FROM loan
    INNER JOIN loan_application ON loan.id = loan_application.loan_id;

-- Creating a view which provides the loan statements for a client
CREATE OR REPLACE VIEW client.loan_statements AS
    SELECT loans.account_id, loans.id, loan_statement.id as statement_id, loan_statement.starting_date, loan_statement.amount
    FROM client.loans
    INNER JOIN loan_statement ON loans.id = loan_statement.loan_id;

-- Creating a view which provides the loan application for a client
CREATE OR REPLACE VIEW client.loan_applications AS
    SELECT loan.account_id, loan_application.id, loan_application.application_status, loan_application.loan_id
    FROM loan_application
    INNER JOIN loan ON loan_application.loan_id = loan.id;


-- Creating a function which allows a client to get their account id
CREATE OR REPLACE FUNCTION client.get_account_id()
RETURNS INT AS $$
DECLARE account_id INT;
BEGIN
    SELECT id INTO account_id FROM client.online_account_information;
    RETURN account_id;
END;
$$ LANGUAGE plpgsql;

-- Creating a function which allows a client to update their personal information
CREATE OR REPLACE FUNCTION client.update_personal_information(first_name_p TEXT, last_name_p TEXT, date_of_birth_p DATE, phone_number_p TEXT, email_address_p TEXT, address_street_p TEXT, address_city_p TEXT, address_county_p TEXT, address_postcode_p TEXT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE account_identifier INT;
BEGIN

    account_identifier = client.get_account_id();

    UPDATE customer SET first_name = first_name_p, last_name = last_name_p, date_of_birth = date_of_birth_p, phone_number = phone_number_p, email_address = email_address_p, address_street = address_street_p, address_city = address_city_p, address_county = address_county_p, address_postcode = address_postcode_p
    WHERE id = (SELECT customer_id FROM online_account WHERE id = account_identifier);

    -- INSERT INTO management_log (log_description, log_date, account_id) VALUES ('Updated personal information', CURRENT_DATE, account_identifier);
    passed = TRUE;
    RETURN passed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a function which allows a client to update their password
CREATE OR REPLACE FUNCTION client.update_password(new_password TEXT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE account_identifier INT;
DECLARE ROW_COUNT INT;

BEGIN
    account_identifier = client.get_account_id();

    EXECUTE 'ALTER ROLE ' || session_user || ' WITH PASSWORD ''' || new_password || ''';';

    UPDATE user_login SET password = (SELECT rolpassword FROM pg_authid WHERE rolname = session_user)
    WHERE account_id = account_identifier;
    GET DIAGNOSTICS ROW_COUNT = ROW_COUNT;
    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_identifier, 'Updated password', CURRENT_DATE);
    passed = CASE WHEN ROW_COUNT = 1 THEN TRUE ELSE FALSE END;
    RETURN passed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a function which allows a client to update their email
CREATE OR REPLACE FUNCTION client.update_email(new_email TEXT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE account_identifier INT;
DECLARE ROW_COUNT INT;
BEGIN

    account_identifier = client.get_account_id();

    UPDATE customer SET email_address = new_email
    WHERE id = (SELECT customer_id FROM online_account WHERE id = account_identifier);

    GET DIAGNOSTICS ROW_COUNT = ROW_COUNT;

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_identifier, 'Updated email', CURRENT_DATE);
    passed = CASE WHEN ROW_COUNT = 1 THEN TRUE ELSE FALSE END;
    RETURN passed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a function which allows a client to open a debit account
CREATE OR REPLACE FUNCTION client.open_debit_account()
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE debit_account_number INT;
DECLARE next_account_number INT;
DECLARE account_id INT;
DECLARE ROW_COUNT INT;
BEGIN
    account_id = client.get_account_id();

    SELECT get_next_account_number() INTO next_account_number;

    INSERT INTO debit_account (account_number, account_id, current_balance, interest_rate) VALUES (next_account_number ,client.get_account_id(), 0, 0.01) RETURNING account_number INTO debit_account_number;
    GET DIAGNOSTICS ROW_COUNT = ROW_COUNT;
    INSERT INTO debit_statement (starting_date, end_date, amount, account_number) VALUES (date_trunc('month', now()::date), (date_trunc('month', now()::date)) + interval '1 month - 1 day', 0, debit_account_number);
    INSERT INTO debit_overdraft (overdraft_usage, overdraft_limit, interest_rate, account_number, approved) VALUES (0, 0, 0.01, debit_account_number, FALSE);
    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_id, 'Opened debit account', CURRENT_DATE);
    passed = CASE WHEN ROW_COUNT = 1 THEN TRUE ELSE FALSE END;
    RETURN passed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a function which allows a client to open a credit account
CREATE OR REPLACE FUNCTION client.open_credit_account()
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE credit_account_number INT;
DECLARE next_account_number INT;
DECLARE account_id INT;
DECLARE ROW_COUNT INT;
BEGIN

    account_id = client.get_account_id();

    SELECT get_next_account_number() INTO next_account_number;

    INSERT INTO credit_account (account_number, outstanding_balance, credit_limit, interest_rate, account_id) VALUES (next_account_number ,0, 1000, 24.9, account_id) RETURNING account_number INTO credit_account_number;
    GET DIAGNOSTICS ROW_COUNT = ROW_COUNT;
    INSERT INTO credit_statement (starting_date, end_date, amount, minimum_payment, minimum_payment_due_date, account_number) VALUES (date_trunc('month', now()::date), (date_trunc('month', now()::date)) + interval '1 month - 1 day', 0, 0, CURRENT_DATE, credit_account_number);
    INSERT INTO credit_account_application (account_number, application_status) VALUES (credit_account_number, 'PENDING');
    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_id, 'Opened credit account', CURRENT_DATE);
    passed = CASE WHEN ROW_COUNT = 1 THEN TRUE ELSE FALSE END;
    return PASSED;
END
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a function which allows a client to open a savings account
CREATE OR REPLACE FUNCTION client.open_savings_account()
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE savings_account_id INT;
DECLARE next_account_number INT;
DECLARE account_id INT;
DECLARE ROW_COUNT INT;
BEGIN

    account_id = client.get_account_id();

    SELECT get_next_account_number() INTO next_account_number;

    INSERT INTO savings_account (account_number, account_id, current_balance, interest_rate) VALUES (next_account_number ,account_id, 0, 0.01) RETURNING account_number INTO savings_account_id;
    GET DIAGNOSTICS ROW_COUNT = ROW_COUNT;
    INSERT INTO savings_statement (starting_date, end_date, amount, account_number) VALUES (date_trunc('month', now()::date), (date_trunc('month', now()::date)) + interval '1 month - 1 day', 0, savings_account_id);
    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_id, 'Opened savings account', CURRENT_DATE);
    passed = CASE WHEN ROW_COUNT = 1 THEN TRUE ELSE FALSE END;
    RETURN passed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a function which allows a client to open a loan
CREATE OR REPLACE FUNCTION client.open_loan(loan_amount NUMERIC, loan_end_date DATE, loan_type TEXT, loan_interest_rate NUMERIC)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE loan_id INT;
DECLARE account_id INT;
DECLARE ROW_COUNT INT;
BEGIN
    account_id = client.get_account_id();

    INSERT INTO loan (account_id, amount, end_date, loan_type, interest_rate) VALUES (account_id, loan_amount, loan_end_date, loan_type, loan_interest_rate) RETURNING id INTO loan_id;
    GET DIAGNOSTICS ROW_COUNT = ROW_COUNT;
    INSERT INTO loan_statement (starting_date, amount, loan_id) VALUES (date_trunc('month', now()::date), 0, loan_id);
    INSERT INTO loan_application (loan_id, application_status, amount) VALUES (loan_id, 'PENDING', loan_amount);
    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_id, 'Opened loan', CURRENT_DATE);
    passed = CASE WHEN ROW_COUNT = 1 THEN TRUE ELSE FALSE END;
    RETURN passed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a function which allows a client to open an overdraft application
CREATE OR REPLACE FUNCTION client.open_overdraft_application(debit_account_number INT, requested_overdraft_limit NUMERIC)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE account_id INT;
DECLARE ROW_COUNT INT;
BEGIN
    account_id = client.get_account_id();

    --check if debit account exists
    IF EXISTS (SELECT * FROM client.debit_accounts WHERE account_number = debit_account_number) THEN
        INSERT INTO debit_overdraft(overdraft_usage, overdraft_limit, interest_rate, approved, account_number) VALUES (0, requested_overdraft_limit, 24.9, FALSE, debit_account_number);
        GET DIAGNOSTICS ROW_COUNT = ROW_COUNT;
        INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_id, 'Opened overdraft application', CURRENT_DATE);
        passed = CASE WHEN ROW_COUNT = 1 THEN TRUE ELSE FALSE END;
    ELSE
        passed = FALSE;
        RAISE NOTICE 'Debit account does not exist';
    END IF;

    RETURN passed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a function which allows a client to view their personal information
CREATE OR REPLACE FUNCTION client.view_personal_information()
RETURNS TABLE (first_name TEXT, last_name TEXT, email TEXT, phone_number TEXT, address TEXT, city TEXT, country TEXT, postal_code TEXT) AS $$
DECLARE account_id INT;
BEGIN
    account_id = client.get_account_id();

    RETURN QUERY
        SELECT first_name, last_name, email, phone_number, address, city, country, postal_code
            FROM client.personal_information
        INNER JOIN client.accounts ON accounts.customer_id = personal_information.id
        WHERE accounts.id = account_id;
END;
$$ LANGUAGE plpgsql;

-- Creating a function which allows a client to view their accounts
CREATE OR REPLACE FUNCTION client.view_accounts()
RETURNS TABLE (account_number INT, account_id INT, sort_code INT, balance NUMERIC, interest_rate NUMERIC, account_type TEXT) AS $$
DECLARE account_identifier INT;
BEGIN
    account_identifier = client.get_account_id();

    RETURN QUERY
        SELECT client.accounts.*, COALESCE(debit_accounts.current_balance, credit_accounts.outstanding_balance, savings_accounts.current_balance) AS balance,
            COALESCE(debit_accounts.interest_rate, credit_accounts.interest_rate, savings_accounts.interest_rate) AS interest_rate,
            get_account_type(accounts.account_number) AS account_type
            FROM client.accounts
            LEFT JOIN client.credit_accounts ON accounts.account_number = credit_accounts.account_number
            LEFT JOIN client.debit_accounts ON accounts.account_number = debit_accounts.account_number
            LEFT JOIN client.savings_accounts ON accounts.account_number = savings_accounts.account_number
            WHERE accounts.account_id = account_identifier;

END;
$$ LANGUAGE plpgsql;

-- Creating a function which allows a client to view their debit accounts
CREATE OR REPLACE FUNCTION client.view_debit_accounts()
RETURNS TABLE (id INT, account_number INT, current_balance NUMERIC, interest_rate NUMERIC, overdraft_limit NUMERIC, overdraft_usage NUMERIC, overdraft_interest_rate NUMERIC, overdraft_approved BOOLEAN) AS $$
DECLARE account_identifier INT;
BEGIN

    account_identifier = client.get_account_id();

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_identifier, 'Viewed debit accounts', CURRENT_DATE);

    RETURN QUERY
        SELECT * FROM client.debit_accounts WHERE account_id = account_identifier;
END;
$$ LANGUAGE plpgsql;

-- Creating a function which allows a client to view their credit accounts
CREATE OR REPLACE FUNCTION client.view_credit_accounts()
RETURNS TABLE (id INT, account_number INT, outstanding_balance NUMERIC, credit_limit NUMERIC, interest_rate NUMERIC, application_status VARCHAR) AS $$
DECLARE account_identifier INT;
BEGIN

    account_identifier = client.get_account_id();

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_identifier, 'Viewed credit accounts', CURRENT_DATE);

    RETURN QUERY
        SELECT * FROM client.credit_accounts WHERE account_id = account_identifier;
END;
$$ LANGUAGE plpgsql;

-- Creating a function which allows a client to view their savings accounts
CREATE OR REPLACE FUNCTION client.view_savings_accounts()
RETURNS TABLE (id INT, account_number INT, current_balance NUMERIC, interest_rate NUMERIC) AS $$
DECLARE account_identifier INT;
BEGIN

    account_identifier = client.get_account_id();

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_identifier, 'Viewed savings accounts', CURRENT_DATE);

    RETURN QUERY
        SELECT * FROM client.savings_accounts WHERE account_id = account_identifier;
END;
$$ LANGUAGE plpgsql;

-- Creating a function which allows a client to view their loans
CREATE OR REPLACE FUNCTION client.view_loans()
RETURNS TABLE (id INT, loan_id INT, loan_amount NUMERIC, loan_interest_rate NUMERIC, loan_type VARCHAR, loan_end_date DATE, loan_application_status VARCHAR) AS $$
DECLARE account_identifier INT;
BEGIN

    account_identifier = client.get_account_id();

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_identifier, 'Viewed loans', CURRENT_DATE);

    RETURN QUERY
        SELECT * FROM client.loans WHERE account_id = account_identifier;
END;
$$ LANGUAGE plpgsql;

-- Creating a function which allows a client to view their savings statements
CREATE OR REPLACE FUNCTION client.view_savings_statements(account_number_identifier INT)
RETURNS TABLE (account_id INT, account_number INT, starting_date DATE, end_date DATE, amount NUMERIC) AS $$
DECLARE account_identifier INT;
BEGIN

    account_identifier = client.get_account_id();

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_identifier, 'Viewed savings statements', CURRENT_DATE);

    RETURN QUERY
        SELECT savings_accounts_statements.starting_date, savings_accounts_statements.end_date, savings_accounts_statements.amount, savings_accounts_statements.account_id
        FROM client.savings_accounts_statements
        WHERE savings_accounts_statements.account_number = account_number_identifier
        AND savings_accounts_statements.account_id = account_identifier;
END;
$$ LANGUAGE plpgsql;

-- Creating a function which allows a client to view their debit statements
CREATE OR REPLACE FUNCTION client.view_debit_statements(account_number_identifier INT)
RETURNS TABLE (account_id INT, account_number INT, starting_date DATE, end_date DATE, amount NUMERIC) AS $$
DECLARE account_identifier INT;
BEGIN

    account_identifier = client.get_account_id();

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_identifier, 'Viewed debit statements', CURRENT_DATE);

    RETURN QUERY
        SELECT debit_accounts_statements.account_id, debit_accounts_statements.account_number, debit_accounts_statements.starting_date, debit_accounts_statements.end_date, debit_accounts_statements.amount
        FROM client.debit_accounts_statements
        WHERE debit_accounts_statements.account_number = account_number_identifier
        AND debit_accounts_statements.account_id = account_identifier;
END;
$$ LANGUAGE plpgsql;

-- Creating a function which allows a client to view their credit statements
CREATE OR REPLACE FUNCTION client.view_credit_statements(account_number_identifier INT)
RETURNS TABLE (account_id INT, account_number INT, starting_date DATE, end_date DATE, amount NUMERIC) AS $$
DECLARE account_identifier INT;
BEGIN

    account_identifier = client.get_account_id();

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_identifier, 'Viewed credit statements', CURRENT_DATE);

    RETURN QUERY
        SELECT credit_accounts_statements.account_id, credit_accounts_statements.account_number, credit_accounts_statements.starting_date, credit_accounts_statements.end_date, credit_accounts_statements.amount
        FROM client.credit_accounts_statements
        WHERE credit_accounts_statements.account_number = account_number_identifier
        AND credit_accounts_statements.account_id = account_identifier;
END;
$$ LANGUAGE plpgsql;

-- Creating a function which allows a client to view their debit transactions for a given statement
CREATE OR REPLACE FUNCTION client.view_debit_statement(account_number_identifier INT, statement_id INT)
RETURNS TABLE (account_id INT, account_number INT, starting_date DATE, end_date DATE, amount NUMERIC, dest_account_number INT, date DATE) AS $$
DECLARE account_identifier INT;
BEGIN

    account_identifier = client.get_account_id();

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_identifier, 'Viewed debit statement', CURRENT_DATE);

    RETURN QUERY
        SELECT debit_accounts_statement.account_id, debit_accounts_statement.account_number, debit_accounts_statement.starting_date, debit_accounts_statement.end_date, debit_accounts_statement.amount, debit_accounts_statement.dest_account_id, debit_accounts_statement.date
        FROM client.debit_accounts_statement
        WHERE debit_accounts_statement.account_id = account_identifier
        AND debit_accounts_statement.account_number = account_number_identifier
        AND debit_accounts_statement.id = statement_id;
END;
$$ LANGUAGE plpgsql;

-- Creating a function which allows a client to view their credit transactions for a given statement
CREATE OR REPLACE FUNCTION client.view_credit_statement(account_number_identifier INT, statement_id INT)
RETURNS TABLE (account_id INT, account_number INT, starting_date DATE, end_date DATE, amount NUMERIC, dest_account_number INT, date DATE) AS $$
DECLARE account_identifier INT;
BEGIN

    account_identifier = client.get_account_id();

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_id, 'Viewed credit statement', CURRENT_DATE);

    RETURN QUERY
        SELECT credit_accounts_statement.account_id, credit_accounts_statement.account_number, credit_accounts_statement.starting_date, credit_accounts_statement.end_date, credit_accounts_statement.amount, credit_accounts_statement.dest_account_id, credit_accounts_statement.date
        FROM client.credit_accounts_statement
        WHERE credit_accounts_statement.account_id = account_identifier
        AND credit_accounts_statement.account_number = account_number_identifier
        AND credit_accounts_statement.id = statement_id;
END;
$$ LANGUAGE plpgsql;

-- Creating a function which allows a client to view their savings transactions for a given statement
CREATE OR REPLACE FUNCTION client.view_savings_statement(account_number_identifier INT, statement_id INT)
RETURNS TABLE (account_id INT, account_number INT, starting_date DATE, end_date DATE, amount NUMERIC, dest_account_number INT, date DATE) AS $$
DECLARE account_identifier INT;
BEGIN

    account_identifier = client.get_account_id();

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_id, 'Viewed savings statement', CURRENT_DATE);

    RETURN QUERY
        SELECT savings_accounts_statement.account_id, savings_accounts_statement.account_number, savings_accounts_statement.starting_date, savings_accounts_statement.end_date, savings_accounts_statement.amount, savings_accounts_statement.dest_account_id, savings_accounts_statement.date
        FROM client.savings_accounts_statement
        WHERE savings_accounts_statement.account_id = account_identifier
        AND savings_accounts_statement.account_number = account_number_identifier
        AND savings_accounts_statement.id = statement_id;
END;
$$ LANGUAGE plpgsql;

-- Creating a function which either returns a new statement id or an existing one
CREATE OR REPLACE FUNCTION client.get_or_create_statement(orig_account_number INT, account_identifier INT DEFAULT client.get_account_id())
RETURNS INT AS $$
DECLARE statement_id INT;
BEGIN
    -- checks if account number exists for a debit account
    CASE WHEN EXISTS (SELECT * FROM debit_account WHERE account_id = account_identifier AND account_number = orig_account_number) THEN
        IF EXISTS (SELECT * FROM debit_statement WHERE account_number = orig_account_number AND starting_date <= now()::date AND end_date >= now()::date) THEN
            SELECT id INTO statement_id FROM debit_statement WHERE account_number = orig_account_number AND starting_date <= now()::date AND end_date >= now()::date;
            RETURN statement_id;
        ELSE 
            INSERT INTO debit_statement (account_number, starting_date, end_date, amount) VALUES (orig_account_number, date_trunc('month', now()::date), now()::date + 30, 0);
            SELECT id INTO statement_id FROM debit_statement WHERE account_number = orig_account_number AND starting_date <= now()::date AND end_date >= now()::date;
            RETURN statement_id;
        END IF;
    -- checks if account number exists for a credit account
    WHEN EXISTS (SELECT * FROM credit_account WHERE account_id = account_identifier AND account_number = orig_account_number) THEN
        IF EXISTS (SELECT * FROM credit_statement WHERE account_number = orig_account_number AND starting_date <= now()::date AND end_date >= now()::date) THEN
            SELECT id INTO statement_id FROM credit_statement WHERE account_number = orig_account_number AND starting_date <= now()::date AND end_date >= now()::date;
            return statement_id;
        ELSE 
            INSERT INTO credit_statement (account_number, starting_date, end_date, amount) VALUES (orig_account_number, date_trunc('month', now()::date), now()::date + 30, 0);
            SELECT id INTO statement_id FROM credit_statement WHERE account_number = orig_account_number AND starting_date <= now()::date AND end_date >= now()::date;
            return statement_id;
        END IF;
    -- checks if account number exists for a savings account
    WHEN EXISTS (SELECT * FROM savings_account WHERE account_id = account_identifier AND account_number = orig_account_number) THEN
        IF EXISTS (SELECT * FROM savings_statement WHERE account_number = orig_account_number AND starting_date <= now()::date AND end_date >= now()::date) THEN
            SELECT id INTO statement_id FROM savings_statement WHERE account_number = orig_account_number AND starting_date <= now()::date AND end_date >= now()::date;
            return statement_id;
        ELSE
            INSERT INTO savings_statement (account_number, starting_date, end_date, amount) VALUES (orig_account_number, date_trunc('month', now()::date), now()::date + 30, 0);
            SELECT id INTO statement_id FROM savings_statement WHERE account_number = orig_account_number AND starting_date <= now()::date AND end_date >= now()::date;
            return statement_id;
        END IF;
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- Creating a function which allows a client to place a transaction into their account
CREATE OR REPLACE FUNCTION client.place_transaction_into_account(orig_account_number INT, transaction_account_number INT, transaction_amount NUMERIC, transfer_account_sort_code INT, loan_payment BOOLEAN)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE statement_id INT;
DECLARE transaction_id INT;
DECLARE account_identifier INT;

BEGIN
    account_identifier = client.get_account_id();

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_identifier, 'Placed transaction into account', CURRENT_DATE);

    -- checks if account number exists for a debit account
    CASE WHEN EXISTS (SELECT * FROM debit_account WHERE account_id = account_identifier AND account_number = orig_account_number) THEN
        SELECT * FROM client.get_or_create_statement(orig_account_number) INTO statement_id;
        UPDATE debit_statement SET amount = amount + transaction_amount WHERE debit_statement.id = statement_id;
        INSERT INTO transaction (origin_account_id, dest_account_id, amount, date, debit_statement_id, dest_account_sort_code, approved)
        VALUES (orig_account_number, transaction_account_number, transaction_amount, now(), statement_id, transfer_account_sort_code, FALSE) RETURNING id INTO transaction_id;
        INSERT INTO pending_transaction (id, account_id, is_transfer, is_loan_payment) VALUES (transaction_id, orig_account_number, true, loan_payment);

    -- checks if account number exists for a credit account
    WHEN EXISTS (SELECT * FROM credit_account WHERE account_id = account_identifier AND account_number = orig_account_number) THEN
        SELECT * FROM client.get_or_create_statement(orig_account_number) INTO statement_id;
        UPDATE credit_statement SET amount = amount + transaction_amount WHERE credit_statement.id = statement_id;
        INSERT INTO transaction (origin_account_id, dest_account_id, amount, date, credit_statement_id, dest_account_sort_code, approved)
        VALUES (orig_account_number, transaction_account_number, transaction_amount, now(), statement_id, transfer_account_sort_code, FALSE) RETURNING id INTO transaction_id;
        INSERT INTO pending_transaction (id, account_id, is_transfer, is_loan_payment) VALUES (transaction_id, orig_account_number, true, loan_payment);

    -- checks if account number exists for a savings account
    WHEN EXISTS (SELECT * FROM savings_account WHERE account_id = account_identifier AND account_number = orig_account_number) THEN
        SELECT * FROM client.get_or_create_statement(orig_account_number) INTO statement_id;
        UPDATE savings_statement SET amount = amount + transaction_amount WHERE savings_statement.id = statement_id;
        INSERT INTO transaction (origin_account_id, dest_account_id, amount, date, savings_statement_id, dest_account_sort_code, approved)
        VALUES (orig_account_number, transaction_account_number, transaction_amount, now(), statement_id, transfer_account_sort_code, FALSE) RETURNING id INTO transaction_id;
        INSERT INTO pending_transaction (id, account_id, is_transfer, is_loan_payment) VALUES (transaction_id, orig_account_number, true, loan_payment);
    ELSE
        RAISE NOTICE 'Account does not exist';
        RETURN FALSE;
    END CASE;
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creating a function which allows a client to initiate a transfer
CREATE OR REPLACE FUNCTION client.initiate_transfer(orig_account_number INT, transfer_amount NUMERIC, transfer_account_number INT, transfer_account_sort_code INT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE internal_account_id INT;
DECLARE ROW_COUNT INT;
DECLARE account_identifier INT;
BEGIN
    account_identifier = client.get_account_id();

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_identifier, 'Initiated transfer', CURRENT_DATE);

    SELECT * FROM client.place_transaction_into_account(orig_account_number::INT, transfer_account_number::INT, transfer_amount::NUMERIC, transfer_account_sort_code::INT, FALSE::BOOLEAN) INTO passed;

    RETURN passed;

END;
$$ LANGUAGE plpgsql;

-- Creating a function which allows a client to initiate a loan payment
CREATE OR REPLACE FUNCTION client.initiate_loan_payment(orig_account_number INT, payment_amount NUMERIC, loan_id INT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE account_identifier INT;
BEGIN

    account_identifier = client.get_account_id();

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_identifier, 'Initiated loan payment', CURRENT_DATE);


    IF EXISTS (SELECT * FROM client.loans WHERE id = loan_id AND application_status = 'PENDING') THEN
        RAISE NOTICE 'Loan is not yet approved';
        RETURN FALSE;
    END IF;

    SELECT * FROM client.place_transaction_into_account(orig_account_number, loan_id, payment_amount, 0, TRUE) INTO passed;

    RETURN passed;

END;
$$ LANGUAGE plpgsql;
 
-- Creating a schema to contain the functions and views for an unauthenticated user
CREATE SCHEMA IF NOT EXISTS unauthenticated;
SET search_path TO unauthenticated, public;

-- Allows an unauthenticated user to match hashes to hashes of personal information contained in the customer table
CREATE OR REPLACE VIEW unauthenticated.unauthenticated_personal_information AS
SELECT id, md5(first_name) AS first_name, md5(last_name) AS last_name, md5(email_address) AS email_address, is_verified
FROM customer;

-- Allows an unauthenticated user to view hashes of usernames contained in the user_login table
CREATE OR REPLACE VIEW unauthenticated.unauthenticated_login AS
SELECT md5(username) AS username FROM user_login;

-- Allows a user to insert personal information into the online banking system
CREATE OR REPLACE FUNCTION unauthenticated.create_personal_info(first_name_p TEXT, last_name_p TEXT, date_of_birth_p DATE, phone_number_p TEXT, email_address_p TEXT, address_street_p TEXT, address_city_p TEXT, address_county_p TEXT, address_postcode_p TEXT)
RETURNS INT AS $$
DECLARE customer_id INT;
BEGIN
    IF NOT EXISTS (SELECT * FROM unauthenticated.unauthenticated_personal_information WHERE first_name = md5(first_name_p) AND last_name = md5(last_name_p) AND email_address = md5(email_address_p)) THEN
        INSERT INTO customer (first_name, last_name, date_of_birth, phone_number, email_address, address_street, address_city, address_county, address_postcode)
        VALUES (first_name_p, last_name_p, date_of_birth_p, phone_number_p, email_address_p, address_street_p, address_city_p, address_county_p, address_postcode_p)
        RETURNING id INTO customer_id;

        INSERT INTO management_log (log_description, log_date) VALUES ('New customer created', now());
    ELSE
        RAISE NOTICE 'CUSTOMER INFORMATION ALREADY PRESENT';
        SELECT id INTO customer_id FROM unauthenticated.unauthenticated_personal_information WHERE first_name = md5(first_name_p) AND last_name = md5(last_name_p) AND email_address = md5(email_address_p);
    END IF;
    RETURN customer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Allows an unauthenticated user to create an online account
CREATE OR REPLACE FUNCTION unauthenticated.create_online_account_details(
    customer_id_p INT, first_name_p TEXT, last_name_p TEXT, email_address_p TEXT, question_choice_ids_p INT[], question_answers_p TEXT[], username_p TEXT, password_p TEXT)
RETURNS INT AS $$
DECLARE account_id INT;
DECLARE online_account_id INT;
DECLARE question_choice_id INT;
BEGIN

    --check customer is verified
    IF NOT EXISTS (SELECT FROM unauthenticated.unauthenticated_personal_information WHERE id = customer_id_p AND first_name = md5(first_name_p) AND last_name = md5(last_name_p)
    AND email_address = md5(email_address_p) AND is_verified = FALSE) THEN
        RAISE NOTICE 'CUSTOMER INFORMATION NOT VERIFIED';
        RETURN -1;
    END IF;

    IF NOT EXISTS (SELECT FROM user_login WHERE username = username_p) THEN
        INSERT INTO online_account (date_opened, sort_code, customer_id)
        VALUES ((SELECT now()), (SELECT num FROM GENERATE_SERIES(1, 6) AS s(num) LIMIT 1), customer_id_p)
        RETURNING id INTO account_id;

        EXECUTE 'CREATE ROLE ' || username_p || ' LOGIN PASSWORD ''' || password_p || ''';';

        INSERT INTO user_login (account_id, username, password)
        VALUES (account_id, username_p, (SELECT rolpassword FROM pg_authid WHERE rolname = username_p))
        RETURNING id INTO online_account_id;

        FOR i IN 0..2 LOOP
            
            INSERT INTO user_login_security_question (question_choice_id, login_id)
            VALUES (question_choice_ids_p[i], online_account_id)
            RETURNING id INTO question_choice_id;

            INSERT INTO security_question_answer (answer, question_id)
            VALUES (question_answers_p[i], question_choice_id);

        END LOOP;

        EXECUTE 'GRANT l2 TO ' || username_p || ';';


        INSERT INTO authentication_log (log_description, log_date, account_id) VALUES ('New online account created', now(), account_id);

        RETURN account_id;
    ELSE
        RAISE NOTICE 'USERNAME ALREADY TAKEN';
        RETURN -1;

    END IF;
    RETURN 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Alters the views for a client that allows for policies to be applied
ALTER VIEW IF EXISTS client.personal_information OWNER TO user_banking_protection;
ALTER VIEW IF EXISTS client.accounts OWNER TO user_banking_protection;
ALTER VIEW IF EXISTS client.online_account_information OWNER TO user_banking_protection;

-- Begin by revoking all privileges from the user l1
REVOKE USAGE ON SCHEMA public FROM l1;
REVOKE USAGE ON SCHEMA bank FROM l1;
REVOKE USAGE ON SCHEMA staff FROM l1;
REVOKE USAGE ON SCHEMA client FROM l1;
REVOKE USAGE ON SCHEMA unauthenticated FROM l1;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM l1;
REVOKE ALL ON ALL TABLES IN SCHEMA bank FROM l1;
REVOKE ALL ON ALL TABLES IN SCHEMA staff FROM l1;
REVOKE ALL ON ALL TABLES IN SCHEMA client FROM l1;
REVOKE ALL ON ALL TABLES IN SCHEMA unauthenticated FROM l1;

-- Grant the user l1 the privileges to access the database for all schemas
GRANT USAGE ON SCHEMA staff TO l1;
GRANT USAGE ON SCHEMA client TO l1;
GRANT USAGE ON SCHEMA bank TO l1;
GRANT USAGE ON SCHEMA public TO l1;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA staff TO l1;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA client TO l1;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA bank TO l1;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO l1;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA staff TO l1;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA client TO l1;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA bank TO l1;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO l1;

-- Begin by revoking all privileges from the user l2
REVOKE USAGE ON SCHEMA public FROM l2;
REVOKE USAGE ON SCHEMA bank FROM l2;
REVOKE USAGE ON SCHEMA staff FROM l2;
REVOKE USAGE ON SCHEMA client FROM l2;
REVOKE USAGE ON SCHEMA unauthenticated FROM l2;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM l2;
REVOKE ALL ON ALL TABLES IN SCHEMA bank FROM l2;
REVOKE ALL ON ALL TABLES IN SCHEMA staff FROM l2;
REVOKE ALL ON ALL TABLES IN SCHEMA client FROM l2;
REVOKE ALL ON ALL TABLES IN SCHEMA unauthenticated FROM l2;

-- Grant the user l2 the privileges to access the database for schemas staff, client and bank
GRANT USAGE ON SCHEMA staff TO l2;
GRANT USAGE ON SCHEMA client TO l2;
GRANT USAGE ON SCHEMA bank TO l2;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA staff TO l2;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA client TO l2;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA bank TO l2;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA staff TO l2;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA client TO l2;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA bank TO l2;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO l2;
GRANT INSERT ON TABLE management_log TO l2;
GRANT INSERT ON TABLE authentication_log TO l2;

-- Begin by revoking all privileges from the user l3
REVOKE USAGE ON SCHEMA public FROM l3;
REVOKE USAGE ON SCHEMA bank FROM l3;
REVOKE USAGE ON SCHEMA staff FROM l3;
REVOKE USAGE ON SCHEMA client FROM l3;
REVOKE USAGE ON SCHEMA unauthenticated FROM l3;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM l3;
REVOKE ALL ON ALL TABLES IN SCHEMA bank FROM l3;
REVOKE ALL ON ALL TABLES IN SCHEMA staff FROM l3;
REVOKE ALL ON ALL TABLES IN SCHEMA client FROM l3;
REVOKE ALL ON ALL TABLES IN SCHEMA unauthenticated FROM l3;

-- Grant the user l3 the privileges to access the database for schemas staff and client
GRANT USAGE ON SCHEMA staff TO l3;
GRANT USAGE ON SCHEMA client TO l3;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA staff TO l3;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA client TO l3;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA staff TO l3;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA client TO l3;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO l3;
GRANT INSERT ON TABLE management_log TO l3;
GRANT INSERT ON TABLE authentication_log TO l3;
GRANT INSERT ON TABLE staff_log TO l3;

-- Begin by revoking all privileges from the user l4
REVOKE USAGE ON SCHEMA public FROM l4;
REVOKE USAGE ON SCHEMA bank FROM l4;
REVOKE USAGE ON SCHEMA staff FROM l4;
REVOKE USAGE ON SCHEMA client FROM l4;
REVOKE USAGE ON SCHEMA unauthenticated FROM l4;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM l4;
REVOKE ALL ON ALL TABLES IN SCHEMA bank FROM l4;
REVOKE ALL ON ALL TABLES IN SCHEMA staff FROM l4;
REVOKE ALL ON ALL TABLES IN SCHEMA client FROM l4;
REVOKE ALL ON ALL TABLES IN SCHEMA unauthenticated FROM l4;

-- Grant the user l4 the privileges to access the database for schema client
GRANT USAGE ON SCHEMA client TO l4;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA client TO l4;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA client TO l4;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO l4;
GRANT INSERT ON TABLE management_log TO l4;
GRANT INSERT ON TABLE authentication_log TO l4;

-- Begin by revoking all privileges from the user l5
REVOKE USAGE ON SCHEMA public FROM l5;
REVOKE USAGE ON SCHEMA bank FROM l5;
REVOKE USAGE ON SCHEMA staff FROM l5;
REVOKE USAGE ON SCHEMA client FROM l5;
REVOKE USAGE ON SCHEMA unauthenticated FROM l5;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM l5;
REVOKE ALL ON ALL TABLES IN SCHEMA bank FROM l5;
REVOKE ALL ON ALL TABLES IN SCHEMA staff FROM l5;
REVOKE ALL ON ALL TABLES IN SCHEMA client FROM l5;
REVOKE ALL ON ALL TABLES IN SCHEMA unauthenticated FROM l5;

-- Grant the user l5 the privileges to access the database for schema unauthenticated
GRANT USAGE ON SCHEMA unauthenticated TO l5;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA unauthenticated TO l5;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA unauthenticated TO l5;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO l5;


-- sample data for customers
INSERT INTO customer (first_name, last_name, date_of_birth, phone_number, email_address, address_street, address_city, address_county, address_postcode)
VALUES ('John', 'Smith', '1990-01-01', '01234567890', 'example@gmail.com', '1 Example Street', 'Example City', 'Example County', 'EX1 1EX'),
('Jane', 'Doe', '1990-01-01', '01234567890', 'test@gmail.com', '1 Test Street', 'Test City', 'Test County', 'TE1 1ST'),
('Joe', 'Bloggs', '1990-01-01', '01234567890', 'example@gmail.com', '1 Example Street', 'Example City', 'Example County', 'EX1 1EX'),
('John', 'Bloggs', '1990-01-01', '01234567890', 'hello@yahoo.com', '1 Hello Street', 'Hello City', 'Hello County', 'HE1 1LO'),
('Jane', 'Bloggs', '1990-01-01', '01234567890', 'test@outlook.com', '1 Test Street', 'Test City', 'Test County', 'TE1 1ST'),
('Joe', 'Doe', '1990-01-01', '01234567890', 'hello@outlook.com', '1 Hello Street', 'Hello City', 'Hello County', 'HE1 1LO'),
('John', 'Doe', '1990-01-01', '01234567890', 'mybankemail@icloud.com', '1 My Bank Street', 'My Bank City', 'My Bank County', 'MB1 1NK'),
('Jane', 'Smith', '1990-01-01', '01234567890', 'bankemail@outlook.com', '1 Bank Street', 'Bank City', 'Bank County', 'BA1 1NK'),
('Joe', 'Smith', '1990-01-01', '01234567890', 'example@icloud.com', '1 Example Street', 'Example City', 'Example County', 'EX1 1EX');

-- sample data for online account
INSERT INTO online_account (date_opened, sort_code, customer_id)
VALUES ('2020-01-01', '123456', 1),
('2019-01-01', '126485', 2),
('2018-01-01', '128475', 3),
('2017-01-01', '129476', 4),
('2016-01-01', '120386', 5),
('2017-02-03', '127385', 6),
('2018-02-04', '128256', 7),
('2020-01-01', '129386', 8),
('2020-01-01', '120386', 9);

-- sample data for user login
INSERT INTO user_login (account_id, username, password)
VALUES (1, 'johnsmith', 'SCRAM-SHA-256$4096:fXertN3iXYwXi/d1NAVWxA==$Km+VxQmt904W5FyobtdES0zrhQ09xdL/pvd6u5ygfic=:wde8zdAQOQlFfOW3dsfRHBwtEj23ca0e0S3csouNySo='),
(2, 'janedoe', 'SCRAM-SHA-256$4096:p96clDu3+uiBV1I/jmAgHw==$RbQAtbMkbOdQKulY+38vda2IoiwBwLgui8dTgvFz9Qg=:4hF8ENWP5xNMpVIb6LW4J08J7ISkfTX9Q1/jeChhw94='),
(3, 'joebloggs', 'SCRAM-SHA-256$4096:adA2GCgW3d6plVKRANTW3w==$86ddhb/Dqe0ZNPUwHBZnbsl3ik//LHmW1lnxar2N+dY=:CVo8Uv6IwVBac86vKlZOMydS6Ieri9VowNjdjIjorHo='),
(4, 'johnbloggs', 'SCRAM-SHA-256$4096:+s+CUUPEB77XPlzIeNMNhQ==$0Y39fJSqIT+uf8gyRmK6WIOpjLxgYqQx05mzWfgfTBU=:ScgKkt4E19sHef2wC6Bpy6erxknIxY7MHJp91AsDP6I='),
(5, 'janebloggs', 'SCRAM-SHA-256$4096:5DGw4usSvx0whpomKX+OaA==$e1PPUkUbYkj0I8wS1MMQbhPGw0NU23cfbjI0UzHiusI=:oIiGW/iW6MbDmn2uZraA4iax3f5+dz+f6sIchVdBQwY='),
(6, 'joedoe', 'SCRAM-SHA-256$4096:3q7kiXiAi+eQubxPE5JGWA==$1GXPGiuczUdK5uDKIFNN0qP8Ij3YYEPBxrTqGYmyTr0=:KbSSuRkVv9k6xJ8ZDjlVYgcBPv1513iQIkiGq9TtBxw='),
(7, 'johndoe', 'SCRAM-SHA-256$4096:BQHANI2Fs/8fhklD+b8CFw==$cHJJgKXGsaQm7W1C2k/5DthUu+5ThNNX+HxWAv95Ik0=:Rv5umCONzPr5o/3D/FcwgNruL59pem/GGB/eRpfz8Pc='),
(8, 'joesmith', 'SCRAM-SHA-256$4096:rGXQZA9O7zXnJkYXjMiNeA==$nU0XPqAAY5FTHtsN4aKqlEI+0PVlvwX5vjanXa5G3M8=:omr5rrcqy3WkuglJsDtMHCcjhMtlns5Els4faCXi/Pk='),
(9, 'janesmith', 'SCRAM-SHA-256$4096:o9vhxjolLJLx75rq9Z6zOQ==$wpWO4KKMBiV+KGugumnMKBb6Uo9ZUjHRgBzWn3Sshvs=:61Lu/sUm2AZ2Xy9ncXs/ulvoMDZAq/EUWFx0Q1SsP7w=');


-- sample data for security question option
INSERT INTO security_question_option (question_description)
VALUES ('What is your favourite colour?'),
('What is your favourite food?'),
('What is your favourite animal?'),
('What is your favourite sport?'),
('What is your favourite movie?'),
('What is your favourite book?'),
('What is your favourite song?'),
('What is your favourite band?'),
('What is your favourite game?'),
('What is your favourite TV show?');

--sample data for user login security question
INSERT INTO user_login_security_question (question_choice_id, login_id)
VALUES (1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 6),
(7, 7),
(8, 8),
(9, 9);

-- sample data for security question answer
INSERT INTO security_question_answer (question_answer, question_id)
VALUES ('Red', 1),
('Blue', 2),
('Green', 3),
('Yellow', 4),
('Orange', 5),
('Purple', 6),
('Pink', 7),
('Black', 8),
('White', 9);

CREATE ROLE johnsmith WITH LOGIN PASSWORD 'SCRAM-SHA-256$4096:fXertN3iXYwXi/d1NAVWxA==$Km+VxQmt904W5FyobtdES0zrhQ09xdL/pvd6u5ygfic=:wde8zdAQOQlFfOW3dsfRHBwtEj23ca0e0S3csouNySo=';
CREATE ROLE janedoe WITH LOGIN PASSWORD 'SCRAM-SHA-256$4096:p96clDu3+uiBV1I/jmAgHw==$RbQAtbMkbOdQKulY+38vda2IoiwBwLgui8dTgvFz9Qg=:4hF8ENWP5xNMpVIb6LW4J08J7ISkfTX9Q1/jeChhw94=';
CREATE ROLE joebloggs WITH LOGIN PASSWORD 'SCRAM-SHA-256$4096:adA2GCgW3d6plVKRANTW3w==$86ddhb/Dqe0ZNPUwHBZnbsl3ik//LHmW1lnxar2N+dY=:CVo8Uv6IwVBac86vKlZOMydS6Ieri9VowNjdjIjorHo=';
CREATE ROLE johnbloggs WITH LOGIN PASSWORD 'SCRAM-SHA-256$4096:+s+CUUPEB77XPlzIeNMNhQ==$0Y39fJSqIT+uf8gyRmK6WIOpjLxgYqQx05mzWfgfTBU=:ScgKkt4E19sHef2wC6Bpy6erxknIxY7MHJp91AsDP6I=';
CREATE ROLE janebloggs WITH LOGIN PASSWORD 'SCRAM-SHA-256$4096:5DGw4usSvx0whpomKX+OaA==$e1PPUkUbYkj0I8wS1MMQbhPGw0NU23cfbjI0UzHiusI=:oIiGW/iW6MbDmn2uZraA4iax3f5+dz+f6sIchVdBQwY=';
CREATE ROLE joedoe WITH LOGIN PASSWORD 'SCRAM-SHA-256$4096:3q7kiXiAi+eQubxPE5JGWA==$1GXPGiuczUdK5uDKIFNN0qP8Ij3YYEPBxrTqGYmyTr0=:KbSSuRkVv9k6xJ8ZDjlVYgcBPv1513iQIkiGq9TtBxw=';
CREATE ROLE johndoe WITH LOGIN PASSWORD 'SCRAM-SHA-256$4096:BQHANI2Fs/8fhklD+b8CFw==$cHJJgKXGsaQm7W1C2k/5DthUu+5ThNNX+HxWAv95Ik0=:Rv5umCONzPr5o/3D/FcwgNruL59pem/GGB/eRpfz8Pc=';
CREATE ROLE joesmith WITH LOGIN PASSWORD 'SCRAM-SHA-256$4096:rGXQZA9O7zXnJkYXjMiNeA==$nU0XPqAAY5FTHtsN4aKqlEI+0PVlvwX5vjanXa5G3M8=:omr5rrcqy3WkuglJsDtMHCcjhMtlns5Els4faCXi/Pk=';
CREATE ROLE janesmith WITH LOGIN PASSWORD 'SCRAM-SHA-256$4096:o9vhxjolLJLx75rq9Z6zOQ==$wpWO4KKMBiV+KGugumnMKBb6Uo9ZUjHRgBzWn3Sshvs=:61Lu/sUm2AZ2Xy9ncXs/ulvoMDZAq/EUWFx0Q1SsP7w=';

GRANT user_banking TO johnsmith, janedoe, joebloggs, johnbloggs, janebloggs, joedoe, johndoe, joesmith, janesmith;


-- test script to create a new customer and online account
DO $$
DECLARE customer_id INT;
DECLARE result INT;
BEGIN
    customer_id = unauthenticated.create_personal_info(
    'John'::text, 'Smith'::text, '1990-01-01'::date, '01234567890'::text,
    'example@gmail.com'::text, 'example street'::text, 'example city'::text,
    'example county'::text, 'EX1 1EX'::text);

    result = (SELECT * FROM unauthenticated.create_online_account_details(customer_id, 'John'::text, 'Smith'::text,
    'example@gmail.com'::text, '{1,2,3}'::int[], '{Blue, Wraps, Dogs}'::text[], 'johnsmith'::text, 'Password123'::text));

    RAISE NOTICE 'Result: %', result;
END
$$;


SELECT * FROM current_user;

SET ROLE johnsmith;
SET SESSION AUTHORIZATION johnsmith;

-- test script to change the password of an existing online account
DO $$
DECLARE result BOOLEAN;
BEGIN
    result = (SELECT * FROM client.update_password('Password1234'::text));
    RAISE NOTICE 'Result: %', result;
END
$$;

-- test script to change the email address of an existing online account
DO $$
DECLARE result BOOLEAN;
BEGIN
    result = (SELECT * FROM client.update_email('example@email.com'::text));
    RAISE NOTICE 'Result: %', result;
END
$$;

-- test script to open a new debit account from an existing customer
DO $$
DECLARE result BOOLEAN;
BEGIN
    result = (SELECT * FROM client.open_debit_account());
    RAISE NOTICE 'Result: %', result;
END
$$;

-- test script to open a new credit account from an existing customer
DO $$
DECLARE result BOOLEAN;
BEGIN
    result = (SELECT * FROM client.open_credit_account());
    RAISE NOTICE 'Result: %', result;
END
$$;

-- test script to open a new savings account from an existing customer
DO $$
DECLARE result BOOLEAN;
BEGIN
    result = (SELECT * FROM client.open_savings_account());
    RAISE NOTICE 'Result: %', result;
END
$$;

-- test script to start a new loan from an existing customer
DO $$
DECLARE result BOOLEAN;
BEGIN
    result = (SELECT * FROM client.open_loan(1000.00, '22-12-2025'::date, 'VEHICLE', 29.9));
    RAISE NOTICE 'Result: %', result;
END
$$;


-- test script to check account balances
SELECT * FROM client.view_accounts();

-- test script to view personal information
SELECT * FROM client.personal_information;

-- test script to view debit acounts
SELECT * FROM client.view_debit_accounts();

-- test script to view credit accounts
SELECT * FROM client.view_credit_accounts();

-- test script to view savings accounts
SELECT * FROM client.view_savings_accounts();

-- test script to view loans
SELECT * FROM client.view_loans();

-- test script to initiate an internal transfer for an existing customer
DO $$
DECLARE result BOOLEAN;
BEGIN
    result = (SELECT * FROM client.initiate_transfer(10000001, 100.00, 10000000, 123456));
    RAISE NOTICE 'Result: %', result;

    RESET SESSION AUTHORIZATION;
    RESET ROLE;

    SET ROLE employee;

    result = (SELECT * FROM staff.approve_or_deny_credit_application(10000001, TRUE));
    RAISE NOTICE 'Result: %', result;

    RESET ROLE;

    SET ROLE johnsmith;
    SET SESSION AUTHORIZATION johnsmith;


    result = (SELECT * FROM client.initiate_transfer(10000001, 100.00, 10000000, 123456));
    RAISE NOTICE 'Result: %', result;


END
$$;


-- test script to initiate an external transfer for an existing customer
DO $$
DECLARE result BOOLEAN;
BEGIN
    result = (SELECT * FROM client.initiate_transfer(10000001, 100.00, 10000000, 654321));
    RAISE NOTICE 'Result: %', result;

END
$$;


-- test script to initiate a loan payment from an existing customer
DO $$
DECLARE result BOOLEAN;
BEGIN
    result =  (SELECT * FROM client.initiate_loan_payment(10000001, 100.00, 1));
    RAISE NOTICE 'Result: %', result;

    RESET SESSION AUTHORIZATION;
    RESET ROLE;

    SET ROLE employee;

    result = (SELECT * FROM staff.approve_or_deny_loan_application(1, TRUE));
    RAISE NOTICE 'Result: %', result;

    RESET ROLE;

    SET ROLE johnsmith;
    SET SESSION AUTHORIZATION johnsmith;

    result =  (SELECT * FROM client.initiate_loan_payment(10000001, 100.00, 1));
    RAISE NOTICE 'Result: %', result;
END
$$;

-- test script to view the statements for a particular account
SELECT * FROM client.view_credit_statements(10000001);

-- test script to view the transactions for a particular account and statement
SELECT * FROM client.view_credit_statement(10000001, 1);


RESET SESSION AUTHORIZATION;
RESET ROLE;
SET ROLE employee;


-- test script to view all client accounts
SELECT * FROM staff.accounts;

--test script to verify customer information
SELECT * FROM staff.review_unverified_customer_personal_information();
SELECT * FROM staff.verify_customer_personal_information(1);

-- test script to approve or deny a credit account application
SELECT * FROM staff.credit_account_applications;
SELECT * FROM staff.approve_or_deny_credit_application(10000001, FALSE);

-- test script to approve or deny a loan application
SELECT * FROM staff.loan_applications;
SELECT * FROM staff.approve_or_deny_loan_application(1, FALSE);

-- test script to approve or deny an overdraft application
SELECT * FROM staff.overdrafts;
SELECT * FROM staff.approve_or_deny_overdraft_application(1, FALSE);




