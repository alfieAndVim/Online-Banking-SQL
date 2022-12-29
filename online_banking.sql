/*create schema*/
CREATE SCHEMA IF NOT EXISTS online_banking;

/*make all commands exist in the schema*/
SET search_path TO online_banking;

/*Drop all tables if they exist*/
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS account;
DROP TABLE IF EXISTS savings_account;
DROP TABLE IF EXISTS credit_account;
DROP TABLE IF EXISTS credit_account_application;
DROP TABLE IF EXISTS debit_account;
DROP TABLE IF EXISTS loan;
DROP TABLE IF EXISTS loan_application;
DROP TABLE IF EXISTS transaction;
DROP TABLE IF EXISTS log;

/*create a table customer with their address as an array*/
CREATE TABLE IF NOT EXISTS customer (
    id SERIAL PRIMARY KEY,
    init_date DATE,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    date_of_birth DATE,
    phone_number VARCHAR(255),
    address VARCHAR(255) []
);

/*create a table account with a foreign key to customer*/
CREATE TABLE IF NOT EXISTS account (
    id SERIAL PRIMARY KEY,
    init_date DATE,
    customer_id INTEGER REFERENCES customer(id),
    username VARCHAR(255),
    passwd VARCHAR(255)
);

/*create a table savings_account with a foreign key to account*/
CREATE TABLE IF NOT EXISTS savings_account (
    id SERIAL PRIMARY KEY,
    account_id INTEGER REFERENCES account(id),
    current_balance NUMERIC(10,2),
    interest_rate NUMERIC(5,2)
);

/*create a table credit_account with a foreign key to account*/
CREATE TABLE IF NOT EXISTS credit_account (
    id SERIAL PRIMARY KEY,
    account_id INTEGER REFERENCES account(id),
    current_balance NUMERIC(10,2),
    credit_limit NUMERIC(10,2),
    interest_rate NUMERIC(5,2)
);

/*create a table credit_account_application with a foreign key to credit_account*/
CREATE TABLE IF NOT EXISTS credit_account_application (
    id SERIAL PRIMARY KEY,
    credit_account_id INTEGER REFERENCES credit_account(id),
    is_approved BOOLEAN,
    application_date DATE,
    status VARCHAR(255)
);

/*create a table debit_account with a foreign key to account*/
CREATE TABLE IF NOT EXISTS debit_account (
    id SERIAL PRIMARY KEY,
    account_id INTEGER REFERENCES account(id),
    current_balance NUMERIC(10,2),
    overdraft_limit NUMERIC(10,2),
    interest_rate NUMERIC(5,2)
);

/*create a table loan with a foreign key to account*/
CREATE TABLE IF NOT EXISTS loan (
    id SERIAL PRIMARY KEY,
    account_id INTEGER REFERENCES account(id),
    current_balance NUMERIC(10,2),
    interest_rate NUMERIC(5,2),
    loan_amount NUMERIC(10,2),
    loan_term INTEGER,
    loan_start_date DATE,
    loan_end_date DATE
);

/*create a table loan_application with a foreign key to loan*/
CREATE TABLE IF NOT EXISTS loan_application (
    id SERIAL PRIMARY KEY,
    loan_id INTEGER REFERENCES loan(id),
    is_approved BOOLEAN,
    application_date DATE,
    status VARCHAR(255)
);

/*create a table transaction with a foreign key to account*/
CREATE TABLE IF NOT EXISTS transaction (
    id SERIAL PRIMARY KEY,
    account_id INTEGER REFERENCES account(id),
    transaction_date DATE,
    transaction_type VARCHAR(255),
    transaction_amount NUMERIC(10,2)
);

/*create a table to log all actions*/
CREATE TABLE IF NOT EXISTS log (
    id SERIAL PRIMARY KEY,
    log_date DATE,
    log_message VARCHAR(255),
    customer_id INTEGER REFERENCES customer(id),
    account_id INTEGER REFERENCES account(id)
);

CREATE OR REPLACE VIEW view_accounts AS
SELECT id, init_date, customer_id, username
FROM account;

CREATE OR REPLACE VIEW view_account AS
SELECT id, init_date, customer_id, username
FROM account
WHERE username = current_user;

-- Create a view that only the current user is able to see their loan information
CREATE OR REPLACE VIEW view_loan AS
SELECT account.customer_id, loan.id, loan.account_id, loan.loan_start_date, loan.is_approved
    FROM (
        SELECT loan.id, loan.account_id, loan.loan_start_date, loan_application.loan_id, loan_application.is_approved FROM loan
        INNER JOIN loan_application ON loan.id = loan_application.loan_id
    ) AS loan
INNER JOIN account ON loan.account_id = account.id
WHERE account.username = current_user;

-- Create a view where only the current user is able to see their credit account information
CREATE OR REPLACE VIEW view_credit_account AS
SELECT account.customer_id, credit_account.id, credit_account.account_id, credit_account.is_approved
    FROM (
        SELECT credit_account.id, credit_account.account_id, credit_account.interest_rate, credit_account_application.credit_account_id, credit_account_application.is_approved FROM credit_account
        INNER JOIN credit_account_application ON credit_account.id = credit_account_application.credit_account_id
    ) AS credit_account
INNER JOIN account on credit_account.account_id = account.id
WHERE account.username = current_user;

-- Create a view where only the current user is able to see their savings account
CREATE OR REPLACE VIEW view_savings_account AS
SELECT account.customer_id, savings_account.id, savings_account.account_id, savings_account.interest_rate
    FROM savings_account
INNER JOIN account ON savings_account.account_id = account.id
WHERE account.username = current_user;

-- Allows a user with significant permissions to read all of the loans that are available
CREATE OR REPLACE VIEW view_loans AS
SELECT customer.first_name, customer.last_name, loans.customer_id, loans.account_id, loans.loan_start_date, loans.is_approved FROM customer
INNER JOIN
    (SELECT account.customer_id, loan.id, loan.account_id, loan.loan_start_date, loan.is_approved
    FROM (
        SELECT loan.id, loan.account_id, loan.loan_start_date, loan_application.loan_id, loan_application.is_approved FROM loan
        INNER JOIN loan_application ON loan.id = loan_application.loan_id
    ) AS loan
    INNER JOIN account ON loan.account_id = account.id) AS loans
ON customer.id = loans.customer_id
ORDER BY customer.last_name ASC;

-- Allows a user with significant permissions to read all of the credit accounts available
CREATE OR REPLACE VIEW view_credit_accounts AS
SELECT customer.first_name, customer.last_name, credit_accounts.customer_id, credit_accounts.id, credit_accounts.is_approved FROM customer
INNER JOIN
    (SELECT account.customer_id, credit_account.id, credit_account.account_id, credit_account.is_approved
    FROM (
        SELECT credit_account.id, credit_account.account_id, credit_account.interest_rate, credit_account_application.credit_account_id, credit_account_application.is_approved FROM credit_account
        INNER JOIN credit_account_application ON credit_account.id = credit_account_application.credit_account_id
    ) AS credit_account
    INNER JOIN account on credit_account.account_id = account.id) AS credit_accounts
ON customer.id = credit_accounts.customer_id
ORDER BY customer.last_name ASC;


-- Allows a user with significant permissions to read all of the debit accounts available
CREATE OR REPLACE VIEW view_debit_accounts AS
SELECT customer.first_name, customer.last_name, debit_accounts.customer_id, debit_accounts.interest_rate FROM customer
INNER JOIN
    (SELECT account.customer_id, debit_account.id, debit_account.account_id, debit_account.interest_rate
    FROM debit_account
    INNER JOIN account ON debit_account.account_id = account.id) AS debit_accounts
ON customer.id = debit_accounts.customer_id;


-- Allows a user with significant permissions to read all of the savings accounts available
CREATE OR REPLACE VIEW view_savings_accounts AS
SELECT customer.first_name, customer.last_name, savings.customer_id, savings.account_id, savings.interest_rate FROM customer
INNER JOIN
    (SELECT account.customer_id, savings_account.id, savings_account.account_id, savings_account.interest_rate
    FROM savings_account
    INNER JOIN account ON savings_account.account_id = account.id) AS savings
ON customer.id = savings.customer_id;


/*insert 10 elements of sample data into customer*/
INSERT INTO customer (init_date, first_name, last_name, date_of_birth, phone_number, address)
VALUES
    ('2019-01-01', 'John', 'Smith', '1990-01-01', '123-456-7890', '{"123 Main St", "Apt 1", "New York, NY 10001"}'),
    ('2019-01-01', 'Jane', 'Doe', '1990-01-01', '123-456-7890', '{"123 Main St", "Apt 1", "New York, NY 10001"}'),
    ('2019-01-01', 'Bob', 'Smith', '1990-01-01', '123-456-7890', '{"123 Main St", "Apt 1", "New York, NY 10001"}'),
    ('2019-01-01', 'Alice', 'Doe', '1990-01-01', '123-456-7890', '{"123 Main St", "Apt 1", "New York, NY 10001"}'),
    ('2019-01-01', 'John', 'Doe', '1990-01-01', '123-456-7890', '{"123 Main St", "Apt 1", "New York, NY 10001"}'),
    ('2019-01-01', 'Jane', 'Smith', '1990-01-01', '123-456-7890', '{"123 Main St", "Apt 1", "New York, NY 10001"}'),
    ('2019-01-01', 'Bob', 'Doe', '1990-01-01', '123-456-7890', '{"123 Main St", "Apt 1", "New York, NY 10001"}'),
    ('2019-01-01', 'Alice', 'Smith', '1990-01-01', '123-456-7890', '{"123 Main St", "Apt 1", "New York, NY 10001"}'),
    ('2019-01-01', 'John', 'Dee', '1990-01-01', '123-456-7890', '{"123 Main St", "Apt 1", "New York, NY 10001"}'),
    ('2019-01-01', 'Jane', 'Dee', '1990-01-01', '123-456-7890', '{"123 Main St", "Apt 1", "New York, NY 10001"}');


/*insert elements of sample data into account*/
INSERT INTO account (init_date, customer_id, username, passwd)
VALUES
    ('2019-01-01', 1, 'JohnSmith', '4e1b8f5bacb39b35f0a97f962871b2d4d5b5e935c34db051b45e3cc5f5b5d5c5'),
    ('2017-01-01', 2, 'JaneDoe', 'f0d5d3c9cf9b5b8c3b3e5e5ce5b5d5c8f5e5b5c5d9d5c5f5b5b5b5f5b5d5b5b5'),
    ('2018-01-01', 3, 'BobSmith', 'e4e9b5b5b5b5e9e9e9b5b5b5e9e9b5b5b5b5b5b5e9e9e9e9b5b5b5e9b5b5b5b5'),
    ('2015-01-01', 4, 'AliceDoe', 'c5d5d5b5b5b5b5b5b5d5d5d5d5b5b5b5b5b5b5d5d5d5d5b5b5b5b5b5b5b5b5'),
    ('2016-01-01', 5, 'JohnDoe', 'a9d9b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5'),
    ('2016-01-01', 6, 'JaneSmith', 'f5e9e9e9b5b5b5e9e9e9e9b5b5b5e9e9e9e9b5b5b5e9e9e9e9b5b5b5e9e9e9'),
    ('2017-01-01', 7, 'BobDoe', 'd5d5d5d5b5b5b5b5b5d5d5d5d5b5b5b5b5b5d5d5d5d5b5b5b5b5b5b5b5b5b5'),
    ('2014-01-01', 8, 'AliceSmith', 'b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5'),
    ('2016-01-01', 9, 'JohnDee', 'e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5'),
    ('2017-01-01', 10, 'JaneDee', 'c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5');

/*insert 8 elements of sample data into savings_account with different amounts and interest rates*/
INSERT INTO savings_account (account_id, current_balance, interest_rate)
VALUES
    (1, 1000.00, 0.01),
    (2, 2000.00, 0.02),
    (3, 3000.00, 0.03),
    (4, 4000.00, 0.04),
    (5, 5000.00, 0.05),
    (6, 6000.00, 0.06),
    (7, 7000.00, 0.07),
    (8, 8000.00, 0.08);

/*insert 8 elements of sample data into credit_account with different amounts, credit limits, and interest rates*/
INSERT INTO credit_account (account_id, current_balance, credit_limit, interest_rate)
VALUES
    (1, 1000.00, 10000.00, 0.01),
    (2, 2000.00, 20000.00, 0.02),
    (3, 3000.00, 30000.00, 0.03),
    (4, 4000.00, 40000.00, 0.04),
    (5, 5000.00, 50000.00, 0.05),
    (6, 6000.00, 60000.00, 0.06),
    (7, 7000.00, 70000.00, 0.07),
    (8, 8000.00, 80000.00, 0.08);

/*insert 8 elements of sample data into debit_account with different amounts, overdraft limits, and interest rates*/
INSERT INTO debit_account (account_id, current_balance, overdraft_limit, interest_rate)
VALUES
    (1, 1000.00, 10000.00, 0.01),
    (2, 2000.00, 20000.00, 0.02),
    (3, 3000.00, 30000.00, 0.03),
    (4, 4000.00, 40000.00, 0.04),
    (5, 5000.00, 50000.00, 0.05),
    (6, 6000.00, 60000.00, 0.06),
    (7, 7000.00, 70000.00, 0.07),
    (8, 8000.00, 80000.00, 0.08);

/*insert 8 elements of sample data into loan with different amounts, interest rates, loan terms, and loan start and end dates*/
INSERT INTO loan (account_id, loan_amount, interest_rate, loan_term, loan_start_date, loan_end_date)
VALUES
    (1, 1000.00, 0.01, 12, '2019-01-01', '2020-01-01'),
    (2, 2000.00, 0.02, 12, '2019-01-01', '2020-01-01'),
    (3, 3000.00, 0.03, 12, '2019-01-01', '2020-01-01'),
    (4, 4000.00, 0.04, 12, '2019-01-01', '2020-01-01'),
    (5, 5000.00, 0.05, 12, '2019-01-01', '2020-01-01'),
    (6, 6000.00, 0.06, 12, '2019-01-01', '2020-01-01'),
    (7, 7000.00, 0.07, 12, '2019-01-01', '2020-01-01'),
    (8, 8000.00, 0.08, 12, '2019-01-01', '2020-01-01');

INSERT INTO loan_application(loan_id, is_approved, application_date, status)
VALUES
    (1, 't', '2019-01-01', 'pending'),
    (2, 't', '2019-01-01', 'pending'),
    (3, 't', '2019-01-01', 'pending'),
    (4, 't', '2019-01-01', 'pending'),
    (5, 't', '2019-01-01', 'pending'),
    (6, 't', '2019-01-01', 'pending'),
    (7, 't', '2019-01-01', 'pending'),
    (8, 't', '2019-01-01', 'pending');

CREATE OR REPLACE FUNCTION get_id(username TEXT)
RETURNS INT AS $$
DECLARE username BOOLEAN;
BEGIN
    SELECT id FROM view_account WHERE username = username;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION add_customer(first_name TEXT, last_name TEXT, date_of_birth DATE, phone_number VARCHAR(255), address VARCHAR(255) [])
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
BEGIN
    INSERT INTO customer (init_date, first_name, last_name, date_of_birth, phone_number, address)
    VALUES (current_date, first_name, last_name, date_of_birth, phone_number, address);
    INSERT INTO log (log_date, log_message, customer_id)
    VALUES (current_date, 'Customer added', (SELECT customer_id FROM customer WHERE first_name = first_name AND last_name = last_name));
    passed := true;
    RETURN passed;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION add_account_role(username TEXT, passwd TEXT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = username) THEN
        EXECUTE format(
            'CREATE USER %I WITH
                LOGIN
                PASSWORD %L'
            , username
            , passwd
        );
        RAISE NOTICE 'CREATED USER "%"', username;
        passed := true;
        RETURN passed;
    ELSE
        RAISE NOTICE 'USER ALREADY EXISTS';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE EXTENSION pgcrypto;

CREATE OR REPLACE FUNCTION add_account(customer_id INTEGER, username TEXT, passwd TEXT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
BEGIN
    INSERT INTO account (init_date, customer_id, username, passwd)
    VALUES (current_date, customer_id, username, DIGEST(passwd, 'sha256'));
    PERFORM add_account_role(username, passwd);
    INSERT INTO log (log_date, log_message, customer_id)
    VALUES (current_date, 'Account added', customer_id);
    passed := true;
    RETURN passed;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM add_account(1, TEXT 'hello', TEXT 'pass');

CREATE OR REPLACE FUNCTION add_savings_account(account_id INTEGER, current_balance NUMERIC, interest_rate NUMERIC)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
BEGIN
    INSERT INTO savings_account (account_id, current_balance, interest_rate)
    VALUES (account_id, current_balance, interest_rate);
    INSERT INTO log (log_date, log_message, customer_id)
    VALUES (current_date, 'Savings account added', (SELECT customer_id FROM account WHERE account_id = account_id));
    passed := true;
    RETURN passed;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION add_credit_account(account_id INTEGER, current_balance NUMERIC, credit_limit NUMERIC, interest_rate NUMERIC)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
BEGIN
    INSERT INTO credit_account (account_id, current_balance, credit_limit, interest_rate)
    VALUES (account_id, current_balance, credit_limit, interest_rate);
    INSERT INTO log (log_date, log_message, customer_id)
    VALUES (current_date, 'Credit account added', (SELECT customer_id FROM account WHERE account_id = account_id));
    passed := true;
    RETURN passed;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION add_credit_account_application(credit_account_id INTEGER, is_approved BOOLEAN)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
BEGIN
    INSERT INTO credit_account_application (credit_account_id, is_approved, application_date, status)
    VALUES (credit_account_id, is_approved, current_date, "pending");
    INSERT INTO log (log_date, log_message, customer_id)
    VALUES (current_date, 'Credit account application added', (SELECT customer_id FROM account WHERE account_id = credit_account_id));
    passed := true;
    RETURN passed;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION update_credit_account_application(credit_application_id INTEGER, status_change TEXT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
BEGIN
    UPDATE credit_account_application SET status = status_change
    WHERE id = credit_application_id;
    passed := true;
    RETURN passed;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION add_debit_account(account_id INTEGER, current_balance NUMERIC, overdraft_limit NUMERIC, interest_rate NUMERIC)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
BEGIN
    INSERT INTO debit_account (account_id, current_balance, overdraft_limit, interest_rate)
    VALUES (account_id, current_balance, overdraft_limit, interest_rate);
    INSERT INTO log (log_date, log_message, customer_id)
    VALUES (current_date, 'Debit account added', (SELECT customer_id FROM account WHERE account_id = account_id));
    passed := true;
    RETURN passed;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION add_loan(account_id INTEGER, loan_amount NUMERIC, interest_rate NUMERIC, loan_term INTEGER, loan_start_date DATE, loan_end_date DATE)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
BEGIN
    INSERT INTO loan (account_id, loan_amount, interest_rate, loan_term, loan_start_date, loan_end_date)
    VALUES (account_id, loan_amount, interest_rate, loan_term, loan_start_date, loan_end_date);
    INSERT INTO log (log_date, log_message, customer_id)
    VALUES (current_date, 'Loan added', (SELECT customer_id FROM account WHERE account_id = account_id));
    passed := true;
    RETURN passed;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION add_loan_application (loan_id INTEGER, is_approved BOOLEAN, application_date DATE, status VARCHAR(255))
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
BEGIN
    INSERT INTO loan_application (loan_id, is_approved, application_date, status)
    VALUES (loan_id, is_approved, application_date, status);
    INSERT INTO log (log_date, log_message, customer_id)
    VALUES (current_date, 'Loan application added', (SELECT customer_id FROM account WHERE account_id = (SELECT account_id FROM loan WHERE loan_id = loan_id)));
    passed := true;
    RETURN passed;
END;
$$ LANGUAGE plpgsql;


\dt

SELECT * FROM view_debit_accounts;