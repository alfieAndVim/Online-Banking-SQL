-- Creating roles for the database system
CREATE ROLE l1 WITH CREATEDB CREATEROLE SUPERUSER;
CREATE ROLE l2 WITH CREATEROLE;
CREATE ROLE l3 WITH CREATEROLE;
CREATE ROLE l4;
CREATE ROLE l5;

-- Creating users for application access
CREATE ROLE unauthenticated WITH LOGIN PASSWORD 'unauthenticated';
CREATE ROLE user_banking WITH LOGIN PASSWORD 'mobile_banking';
CREATE ROLE employee WITH LOGIN PASSWORD 'employee';
CREATE ROLE manager WITH LOGIN PASSWORD 'manager';

-- Granting role based access to users
GRANT l1 TO postgres;
GRANT l2 TO manager;
GRANT l3 TO employee;
GRANT l4 TO user_banking;
GRANT l5 TO unauthenticated;

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
    address_postcode VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS online_account (
    id SERIAL PRIMARY KEY,
    date_opened DATE,
    sort_code INT,
    customer_id INT REFERENCES customer(id)
);

CREATE TABLE IF NOT EXISTS user_login (
    id SERIAL PRIMARY KEY,
    account_id INT REFERENCES online_account(id),
    username VARCHAR(255),
    password VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS security_question_option (
    id SERIAL PRIMARY KEY,
    question_description VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS user_login_security_question (
    id SERIAL PRIMARY KEY,
    question_choice_id INT REFERENCES security_question_option(id),
    login_id INT REFERENCES user_login(id)
);

CREATE TABLE IF NOT EXISTS security_question_answer (
    id SERIAL PRIMARY KEY,
    question_answer VARCHAR(255),
    question_id INT REFERENCES user_login_security_question(id)
);

CREATE TABLE IF NOT EXISTS account (
    account_number SERIAL PRIMARY KEY,
    account_id INT REFERENCES online_account(id)
);

CREATE TABLE IF NOT EXISTS savings_account (
    id SERIAL PRIMARY KEY,
    current_balance NUMERIC(15, 2),
    interest_rate NUMERIC(5,2),
    account_number INT REFERENCES account(account_number)
);

CREATE TABLE IF NOT EXISTS credit_account (
    id SERIAL PRIMARY KEY,
    outstanding_balance NUMERIC(15, 2),
    credit_limit NUMERIC(15, 2),
    interest_rate NUMERIC(5,2),
    account_number INT REFERENCES account(account_number)
);

CREATE TABLE IF NOT EXISTS debit_account (
    id SERIAL PRIMARY KEY,
    current_balance NUMERIC(15, 2),
    interest_rate NUMERIC(5,2),
    account_number INT REFERENCES account(account_number)
);

CREATE TABLE IF NOT EXISTS loan (
    id SERIAL PRIMARY KEY,
    loan_amount NUMERIC(15, 2),
    loan_end_date DATE,
    loan_type VARCHAR,
    loan_interest_rate NUMERIC(5,2),
    account_id INT REFERENCES online_account(id)
);

CREATE TABLE IF NOT EXISTS savings_statement (
    id SERIAL PRIMARY KEY,
    starting_date DATE,
    end_date DATE,
    amount INT,
    account_id INT REFERENCES savings_account(id)
);

CREATE TABLE IF NOT EXISTS credit_account_application (
    id SERIAL PRIMARY KEY,
    application_status VARCHAR,
    account_id INT REFERENCES credit_account(id)
);

CREATE TABLE IF NOT EXISTS credit_statement (
    id SERIAL PRIMARY KEY,
    starting_date DATE,
    end_date DATE,
    amount INT,
    minimum_payment INT,
    minimum_payment_due_date DATE,
    account_id INT REFERENCES credit_account(id)
);

CREATE TABLE IF NOT EXISTS debit_statement (
    id SERIAL PRIMARY KEY,
    starting_date DATE,
    end_date DATE,
    amount INT,
    account_id INT REFERENCES debit_account(id)
);

CREATE TABLE IF NOT EXISTS debit_overdraft (
    id SERIAL PRIMARY KEY,
    overdraft_usage NUMERIC(15, 2),
    overdraft_limit NUMERIC(15, 2),
    interest_rate NUMERIC(5,2),
    account_id INT REFERENCES debit_account(id)
);

CREATE TABLE IF NOT EXISTS transaction (
    id SERIAL PRIMARY KEY,
    origin_account_id INT,
    dest_account_id INT,
    amount NUMERIC(15, 2),
    date DATE,
    savings_statement_id INT REFERENCES savings_statement(id),
    credit_statement_id INT REFERENCES credit_statement(id),
    debit_statement_id INT REFERENCES debit_statement(id)
);

CREATE TABLE IF NOT EXISTS loan_application (
    id SERIAL PRIMARY KEY,
    application_status VARCHAR,
    loan_id INT REFERENCES loan(id)
);

CREATE TABLE IF NOT EXISTS loan_statement (
    id SERIAL PRIMARY KEY,
    starting_date INT,
    amount INT,
    loan_id INT REFERENCES loan(id)
);

CREATE TABLE IF NOT EXISTS external_account (
    account_id SERIAL PRIMARY KEY REFERENCES online_account(id),
    external_account_number INT
);

CREATE TABLE IF NOT EXISTS authentication_log (
    id SERIAL PRIMARY KEY,
    log_description VARCHAR,
    log_date DATE,
    account_id INT REFERENCES online_account(id)
);

CREATE TABLE IF NOT EXISTS management_log (
    id SERIAL PRIMARY KEY,
    log_description VARCHAR,
    log_date DATE,
    account_id INT REFERENCES online_account(id)
);

CREATE TABLE IF NOT EXISTS request_log (
    id SERIAL PRIMARY KEY,
    log_description VARCHAR,
    log_date DATE
);

CREATE SCHEMA IF NOT EXISTS client;
SET search_path TO public, client;

-- -- Allows the user to view their login details, no password is shown
-- CREATE OR REPLACE VIEW client.view_login AS
-- SELECT *
-- FROM user_login;

-- -- Allows the user to view their security questions along with the answers given by them
-- CREATE OR REPLACE VIEW client.client_security_questions AS
-- SELECT security_question_option.question_description, security_question_answer.question_answer
-- FROM user_login_security_question
-- INNER JOIN security_question_option ON user_login_security_question.question_choice_id = security_question_option.id
-- INNER JOIN security_question_answer ON user_login_security_question.id = security_question_answer.question_id
-- INNER JOIN view_login ON user_login_security_question.login_id = view_login.id;

-- -- Allows the user to view their online account details such as date opened, sort code and id
-- CREATE OR REPLACE VIEW client.client_online_account_details AS
-- SELECT online_account.id, online_account.date_opened, online_account.sort_code, online_account.customer_id
--     FROM online_account
-- INNER JOIN view_login ON online_account.id = view_login.id;

-- -- Allows the user to view their personal information such as name and address
-- CREATE OR REPLACE VIEW client.client_personal_information AS
-- SELECT customer.* FROM customer
-- INNER JOIN client_online_account_details ON customer.id = client_online_account_details.customer_id;

-- -- Allows a user to view their loan information such as amount and duration
-- CREATE OR REPLACE VIEW client.client_loans AS
-- SELECT loan.id, loan.loan_amount, loan.loan_end_date, loan.loan_type, loan.loan_interest_rate, loan.account_id
-- FROM loan
-- INNER JOIN client_online_account_details ON loan.account_id = client_online_account_details.id;

-- CREATE OR REPLACE VIEW client.client_loan_applications AS
-- SELECT loan_application.application_status, loan_application.loan_id
-- FROM client_loans
-- INNER JOIN loan_application ON client_loans.id = loan_application.loan_id;

-- CREATE OR REPLACE VIEW client.client_loan_statements AS
-- SELECT loan_statement.starting_date, loan_statement.amount, loan_statement.loan_id
-- FROM client_loans
-- INNER JOIN loan_statement ON client_loans.id = loan_statement.loan_id;

-- -- Allows a user to view their savings account information such as balance and interest rate
-- CREATE OR REPLACE VIEW client.client_savings_account AS
-- SELECT savings_account.id, savings_account.current_balance, savings_account.interest_rate
-- FROM savings_account
-- INNER JOIN client_online_account_details ON savings_account.account_id = client_online_account_details.id;

-- CREATE OR REPLACE VIEW client.client_savings_account_statements AS
-- SELECT savings_statement.id, savings_statement.starting_date, savings_statement.end_date, savings_statement.amount, savings_statement.account_id
-- FROM client_savings_account
-- INNER JOIN savings_statement ON client_savings_account.id = savings_statement.account_id;

-- CREATE OR REPLACE VIEW client.client_savings_account_statement AS
-- SELECT transaction.origin_account_id, transaction.dest_account_id, transaction.amount, transaction.date, transaction.savings_statement_id
-- FROM client_savings_account_statements
-- INNER JOIN transaction ON client_savings_account_statements.id = transaction.savings_statement_id;

-- -- Allows a user to view their credit account information such as credit limit and interest rate
-- CREATE OR REPLACE VIEW client.client_credit_accounts AS
-- SELECT credit_account.id, credit_account.outstanding_balance, credit_account.credit_limit, credit_account.interest_rate
-- FROM credit_account
-- INNER JOIN client_online_account_details ON credit_account.account_id = client_online_account_details.id;

-- CREATE OR REPLACE VIEW client.client_credit_account_applications AS
-- SELECT credit_account_application.application_status, credit_account_application.account_id
-- FROM client_credit_accounts
-- INNER JOIN credit_account_application ON client_credit_accounts.id = credit_account_application.account_id;

-- CREATE OR REPLACE VIEW client.client_credit_account_statements AS
-- SELECT credit_statement.id, credit_statement.starting_date, credit_statement.end_date, credit_statement.amount, credit_statement.minimum_payment, credit_statement.minimum_payment_due_date, credit_statement.account_id
-- FROM client_credit_accounts
-- INNER JOIN credit_statement ON client_credit_accounts.id = credit_statement.account_id;

-- CREATE OR REPLACE VIEW client.client_credit_account_statement AS
-- SELECT transaction.origin_account_id, transaction.dest_account_id, transaction.amount, transaction.date, transaction.credit_statement_id
-- FROM client_credit_account_statements
-- INNER JOIN transaction ON client_credit_account_statements.id = transaction.credit_statement_id;

-- -- Allows a user to view their debit account information such as current balance and interest rate
-- CREATE OR REPLACE VIEW client.client_debit_accounts AS
-- SELECT debit_account.id, debit_account.current_balance, debit_account.interest_rate
-- FROM debit_account
-- INNER JOIN client_online_account_details ON debit_account.account_id = client_online_account_details.id;

-- CREATE OR REPLACE VIEW client.client_debit_account_overdraft AS
-- SELECT client.client_debit_accounts.id id, debit_overdraft.overdraft_usage overdraft_usage, debit_overdraft.overdraft_limit overdraft_limit, debit_overdraft.interest_rate interest_rate, debit_overdraft.account_id account_id
-- FROM client.client_debit_accounts
-- INNER JOIN debit_overdraft ON client.client_debit_accounts.id = debit_overdraft.account_id;



-- CREATE OR REPLACE VIEW client.client_debit_account_statement AS
-- SELECT transaction.origin_account_id, transaction.dest_account_id, transaction.amount, transaction.date, transaction.credit_statement_id
-- FROM client_debit_account_statements
-- INNER JOIN transaction ON client_debit_account_statements.id = transaction.debit_statement_id;

CREATE OR REPLACE VIEW client.account_information AS
    SELECT account.account_id, account.account_number, savings_account.current_balance, credit_account.outstanding_balance, debit_account.current_balance
    FROM account
    LEFT JOIN savings_account ON account.account_number = savings_account.account_number
    LEFT JOIN credit_account ON account.account_number = credit_account.account_number
    LEFT JOIN debit_account ON account.account_number = debit_account.account_number;

CREATE OR REPLACE VIEW client.debit_account_information AS
    SELECT debit_account.account_id, debit_account.id, debit_account.current_balance, debit_account.interest_rate, debit_overdraft.overdraft_limit, debit_overdraft.overdraft_usage, debit_overdraft.interest_rate, external_account.account_number
    FROM debit_account
    INNER JOIN debit_overdraft ON debit_account.id = debit_overdraft.account_id
    INNER JOIN external_account ON debit_account.id = external_account.account_id;

CREATE OR REPLACE VIEW client.client_debit_account_statements AS
    SELECT debit_statement.id, debit_statement.starting_date, debit_statement.end_date, debit_statement.amount, debit_statement.account_id
    FROM client.debit_account_information
    INNER JOIN debit_statement ON client.debit_account_information.id = debit_statement.account_id;

CREATE OR REPLACE VIEW client.client_debit_account_statement AS
    SELECT transaction.origin_account_id, transaction.dest_account_id, transaction.amount, transaction.date, transaction.debit_statement_id
    FROM client.client_debit_account_statements
    INNER JOIN transaction ON client.client_debit_account_statements.id = transaction.debit_statement_id;

CREATE OR REPLACE VIEW client.credit_account_information AS
    SELECT credit_account.account_id, credit_account.id, credit_account.outstanding_balance, credit_account.credit_limit, credit_account.interest_rate, credit_account_application.application_status
    FROM credit_account
    INNER JOIN credit_account_application ON credit_account.id = credit_account_application.account_id;

CREATE OR REPLACE VIEW client.client_credit_account_statements AS
    SELECT credit_statement.id, credit_statement.starting_date, credit_statement.end_date, credit_statement.amount, credit_statement.minimum_payment, credit_statement.minimum_payment_due_date, credit_statement.account_id
    FROM client.credit_account_information
    INNER JOIN credit_statement ON client.credit_account_information.id = credit_statement.account_id;

CREATE OR REPLACE VIEW client.client_credit_account_statement AS
    SELECT transaction.origin_account_id, transaction.dest_account_id, transaction.amount, transaction.date, transaction.credit_statement_id
    FROM client.client_credit_account_statements
    INNER JOIN transaction ON client.client_credit_account_statements.id = transaction.credit_statement_id;

CREATE OR REPLACE VIEW client.savings_account_information AS
    SELECT savings_account.account_id, savings_account.id, savings_account.current_balance, savings_account.interest_rate, external_account.account_number
    FROM savings_account
    INNER JOIN external_account ON savings_account.id = external_account.account_id;

CREATE OR REPLACE VIEW client.loan_information AS
    SELECT loan.account_id, loan.id, loan.amount, loan.interest_rate, loan.term, loan_application.application_status
    FROM loan
    INNER JOIN loan_application ON loan.id = loan_application.account_id;

CREATE OR REPLACE FUNCTION client.update_personal_information(first_name TEXT, last_name TEXT, date_of_birth DATE, phone_number TEXT, email_address TEXT, address_street TEXT, address_city TEXT, address_county TEXT, address_postcode TEXT, account_id INT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
BEGIN
    UPDATE customer SET first_name = first_name, last_name = last_name, date_of_birth = date_of_birth, phone_number = phone_number, email_address = email_address, address_street = address_street, address_city = address_city, address_county = address_county, address_postcode = address_postcode
    WHERE id = (SELECT customer_id FROM online_account WHERE id = account_id);

    INSERT INTO management_log (account_id, action, date) VALUES (account_id, 'Updated personal information', CURRENT_DATE);
    passed = CASE WHEN @@ROWCOUNT = 1 THEN TRUE ELSE FALSE END;
    RETURN passed;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.update_password(account_identifier INT, new_password TEXT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
BEGIN
    UPDATE user_login SET password = md5(new_password)
    WHERE account_id = account_identifier;

    INSERT INTO management_log (account_id, action, date) VALUES (account_identifier, 'Updated password', CURRENT_DATE);
    passed = CASE WHEN @@ROWCOUNT = 1 THEN TRUE ELSE FALSE END;
    RETURN passed;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.open_debit_account(account_id INT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE debit_account_id INT;
BEGIN
    INSERT INTO debit_account (account_id, current_balance, interest_rate) VALUES (account_id, 0, 0.01) RETURNING id INTO debit_account_id;
    INSERT INTO debit_statement (starting_date, end_date, amount, account_id) VALUES (CURRENT_DATE, CURRENT_DATE, 0, debit_account_id);
    INSERT INTO debit_overdraft (overdraft_usage, overdraft_limit, interest_rate, account_id) VALUES (0, 0, 0.01, debit_account_id);
    INSERT INTO external_account (account_id, external_account_number) VALUES (debit_account_id, '12345678');
    INSERT INTO management_log (account_id, action, date) VALUES (account_id, 'Opened debit account', CURRENT_DATE);
    passed = CASE WHEN @@ROWCOUNT = 1 THEN TRUE ELSE FALSE END;
    RETURN passed;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.open_credit_account(account_id INT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE credit_account_id INT;
BEGIN
    INSERT INTO credit_account (outstanding_balance, credit_limit, interest_rate, account_id) VALUES (0, 0, 24.9, account_id) RETURNING id INTO credit_account_id;
    INSERT INTO credit_statement (starting_date, end_date, amount, minimum_payment, minimum_payment_due_date, account_id) VALUES (CURRENT_DATE, CURRENT_DATE, 0, 0, CURRENT_DATE, credit_account_id);
    INSERT INTO credit_account_application (credit_account_id, application_status) VALUES (credit_account_id, 'PENDING');
    INSERT INTO management_log (account_id, action, date) VALUES (account_id, 'Opened credit account', CURRENT_DATE);
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.open_savings_account(account_id INT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE savings_account_id INT;
BEGIN
    INSERT INTO savings_account (account_id, current_balance, interest_rate) VALUES (account_id, 0, 0.01) RETURNING id INTO savings_account_id;
    INSERT INTO savings_statement (starting_date, end_date, amount, account_id) VALUES (CURRENT_DATE, CURRENT_DATE, 0, savings_account_id);
    INSERT INTO management_log (account_id, action, date) VALUES (account_id, 'Opened savings account', CURRENT_DATE);
    INSERT INTO external_account (account_id, external_account_number) VALUES (savings_account_id, '12345678');
    passed = CASE WHEN @@ROWCOUNT = 1 THEN TRUE ELSE FALSE END;
    RETURN passed;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.open_loan(account_id INT, loan_amount INT, loan_end_date DATE, loan_type TEXT, loan_interest_rate NUMERIC)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE loan_id INT;
BEGIN
    INSERT INTO loan (account_id, loan_amount, loan_end_date, loan_type, loan_interest_rate) VALUES (account_id, loan_amount, loan_end_date, loan_type, loan_interest_rate) RETURNING id INTO loan_id;
    INSERT INTO loan_statement (starting_date, end_date, amount, account_id) VALUES (CURRENT_DATE, CURRENT_DATE, 0, loan_id);
    INSERT INTO loan_application (loan_id, application_status) VALUES (loan_id, 'PENDING');
    INSERT INTO management_log (account_id, action, date) VALUES (account_id, 'Opened loan', CURRENT_DATE);
    passed = CASE WHEN @@ROWCOUNT = 1 THEN TRUE ELSE FALSE END;
    RETURN passed;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.view_debit_accounts(account_id INT)
RETURNS TABLE (id INT, current_balance NUMERIC, interest_rate NUMERIC, overdraft_limit NUMERIC, overdraft_usage NUMERIC, interest_rate, external_account_number INT) AS $$
BEGIN

    INSERT INTO management_log (account_id, action, date) VALUES (account_id, 'Viewed debit accounts', CURRENT_DATE);

    RETURN QUERY
        SELECT debit_accounts.id, debit_accounts.current_balance, debit_accounts.interest_rate, debit_overdraft.overdraft_limit, debit_overdraft.overdraft_usage, debit_overdraft.interest_rate
        FROM client.debit_account_information AS debit_accounts
        WHERE debit_accounts.account_id = account_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.view_credit_accounts(account_id INT)
RETURNS TABLE (id INT, outstanding_balance NUMERIC, credit_limit NUMERIC, interest_rate NUMERIC, application_status TEXT) AS $$
BEGIN

    INSERT INTO management_log (account_id, action, date) VALUES (account_id, 'Viewed credit accounts', CURRENT_DATE);

    RETURN QUERY
        SELECT credit_accounts.id, credit_accounts.outstanding_balance, credit_accounts.credit_limit, credit_accounts.interest_rate, credit_account_application.application_status
        FROM client.credit_account_information AS credit_accounts
        WHERE credit_accounts.account_id = account_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.view_savings_accounts(account_id INT)
RETURNS TABLE (id INT, current_balance NUMERIC, interest_rate NUMERIC, external_account_number INT) AS $$
BEGIN

    INSERT INTO management_log (account_id, action, date) VALUES (account_id, 'Viewed savings accounts', CURRENT_DATE);

    RETURN QUERY
        SELECT savings_accounts.id, savings_accounts.current_balance, savings_accounts.interest_rate, savings_accounts.external_account_number
        FROM client.savings_account_information AS savings_accounts
        WHERE savings_account.account_id = account_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.view_loans(account_id INT)
RETURNS TABLE (id INT, loan_amount NUMERIC, loan_end_date DATE, loan_type TEXT, loan_interest_rate NUMERIC, application_status TEXT) AS $$
BEGIN

    INSERT INTO management_log (account_id, action, date) VALUES (account_id, 'Viewed loans', CURRENT_DATE);

    RETURN QUERY
        SELECT loan.id, loan.loan_amount, loan.loan_end_date, loan.loan_type, loan.loan_interest_rate, loan_application.application_status
        FROM client.loan_information AS loan
        WHERE loan.account_id = account_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.view_savings_statements(account_id INT, savings_account_id INT)
RETURNS TABLE (starting_date DATE, end_date DATE, amount NUMERIC, account_id INT) AS $$
BEGIN

    INSERT INTO management_log (account_id, action, date) VALUES (account_id, 'Viewed savings statements', CURRENT_DATE);

    RETURN QUERY
        SELECT savings_statement.starting_date, savings_statement.end_date, savings_statement.amount, savings_statement.account_id
        FROM client.savings_statement_information AS savings_statement
        WHERE savings_statement.account_id = savings_account_id;
END;

CREATE OR REPLACE FUNCTION client.view_loan_statements(account_id INT, loan_id INT)
RETURNS TABLE (starting_date DATE, end_date DATE, amount NUMERIC, account_id INT) AS $$
BEGIN

    INSERT INTO management_log (account_id, action, date) VALUES (account_id, 'Viewed loan statements', CURRENT_DATE);

    RETURN QUERY
        SELECT loan_statement.starting_date, loan_statement.end_date, loan_statement.amount, loan_statement.account_id
        FROM client.loan_statement_information AS loan_statement
        WHERE loan_statement.account_id = loan_id;
END;

CREATE OR REPLACE FUNCTION client.view_debit_statements(account_id INT, debit_account_id INT)
RETURNS TABLE (starting_date DATE, end_date DATE, amount NUMERIC, account_id INT) AS $$
BEGIN

    INSERT INTO management_log (account_id, action, date) VALUES (account_id, 'Viewed debit statements', CURRENT_DATE);

    RETURN QUERY
        SELECT debit_statement.starting_date, debit_statement.end_date, debit_statement.amount, debit_statement.account_id
        FROM client.debit_statement_information AS debit_statement
        WHERE debit_statement.account_id = debit_account_id;
END;

CREATE OR REPLACE FUNCTION client.view_credit_statements(account_id INT, credit_account_id INT)
RETURNS TABLE (starting_date DATE, end_date DATE, amount NUMERIC, account_id INT) AS $$
BEGIN

    INSERT INTO management_log (account_id, action, date) VALUES (account_id, 'Viewed credit statements', CURRENT_DATE);

    RETURN QUERY
        SELECT credit_statement.starting_date, credit_statement.end_date, credit_statement.amount, credit_statement.account_id
        FROM client.credit_statement_information AS credit_statement
        WHERE credit_statement.account_id = credit_account_id;
END;

CREATE OR REPLACE FUNCTION client.view_debit_statement(account_id INT, debit_account_id INT, starting_date DATE, end_date DATE)
RETURNS TABLE (starting_date DATE, end_date DATE, amount NUMERIC, account_id INT) AS $$
BEGIN

    INSERT INTO management_log (account_id, action, date) VALUES (account_id, 'Viewed debit statement', CURRENT_DATE);

    RETURN QUERY
        SELECT debit_statement.starting_date, debit_statement.end_date, debit_statement.amount, debit_statement.account_id
        FROM client.debit_statement_information AS debit_statement
        WHERE debit_statement.account_id = debit_account_id AND debit_statement.starting_date = starting_date AND debit_statement.end_date = end_date;
END;

CREATE OR REPLACE FUNCTION client.view_credit_statement(account_id INT, credit_account_id INT, starting_date DATE, end_date DATE)
RETURNS TABLE (starting_date DATE, end_date DATE, amount NUMERIC, account_id INT) AS $$
BEGIN

    INSERT INTO management_log (account_id, action, date) VALUES (account_id, 'Viewed credit statement', CURRENT_DATE);

    RETURN QUERY
        SELECT credit_statement.starting_date, credit_statement.end_date, credit_statement.amount, credit_statement.account_id
        FROM client.credit_statement_information AS credit_statement
        WHERE credit_statement.account_id = credit_account_id AND credit_statement.starting_date = starting_date AND credit_statement.end_date = end_date;
END;

CREATE OR REPLACE FUNCTION client.view_savings_statement(account_id INT, savings_account_id INT, starting_date DATE, end_date DATE)
RETURNS TABLE (starting_date DATE, end_date DATE, amount NUMERIC, account_id INT) AS $$
BEGIN

    INSERT INTO management_log (account_id, action, date) VALUES (account_id, 'Viewed savings statement', CURRENT_DATE);

    RETURN QUERY
        SELECT savings_statement.starting_date, savings_statement.end_date, savings_statement.amount, savings_statement.account_id
        FROM client.savings_statement_information AS savings_statement
        WHERE savings_statement.account_id = savings_account_id AND savings_statement.starting_date = starting_date AND savings_statement.end_date = end_date;
END;

CREATE OR REPLACE FUNCTION client.view_

CREATE SCHEMA IF NOT EXISTS unauthenticated;
SET search_path TO unauthenticated, public;

-- Allows an unauthenticated user to match hashes to hashes of personal information contained in the customer table
CREATE OR REPLACE VIEW unauthenticated.unauthenticated_personal_information AS
SELECT id, md5(first_name) AS first_name, md5(last_name) AS last_name, md5(email_address) AS email_address
FROM customer;

-- Allows an unauthenticated user to view hashes of usernames contained in the user_login table
CREATE OR REPLACE VIEW unauthenticated.unauthenticated_login AS
SELECT md5(username) AS username FROM user_login;

-- Allows a user to insert personal information into the online banking system
CREATE OR REPLACE FUNCTION unauthenticated.create_personal_info(first_name TEXT, last_name TEXT, date_of_birth DATE, phone_number TEXT, email_address TEXT, address_street TEXT, address_city TEXT, address_county TEXT, address_postcode TEXT)
RETURNS INT AS $$
DECLARE customer_id INT;
BEGIN
    IF NOT EXISTS (SELECT FROM unauthenticated.unauthenticated_personal_information WHERE md5(first_name) = first_name AND md5(last_name) = last_name AND md5(email_address) = email_address) THEN
        INSERT INTO customer
        VALUES (first_name, last_name, date_of_birth, phone_number, email_address, address_street, address_city, address_county, address_postcode)
        RETURNING id INTO customer_id;

        INSERT INTO management_log (log_description, log_date) VALUES ('New customer created', now());
    ELSE
        RAISE NOTICE 'CUSTOMER INFORMATION ALREADY PRESENT';
        SELECT id INTO customer_id FROM unauthenticated.unauthenticated_personal_information WHERE md5(first_name) = first_name AND md5(last_name) = last_name AND md5(email_address) = email_address;
    END IF;
    RETURN customer_id;
END;
$$ LANGUAGE plpgsql;

-- Allows an unauthenticated user to create an online account
CREATE OR REPLACE FUNCTION unauthenticated.create_online_account_details(customer_id INT, first_name TEXT, last_name TEXT, email_address TEXT, question_choice_ids INT[], question_answers TEXT[])
RETURNS INT AS $$
DECLARE account_id INT;
DECLARE online_account_id INT;
DECLARE question_choice_id INT;
BEGIN
    IF NOT EXISTS (SELECT FROM user_login WHERE username = username) THEN
        INSERT INTO online_account (date_opened, sort_code, customer_id)
        VALUES ((SELECT now()), (SELECT num FROM GENERATE_SERIES(1, 6) AS s(num) LIMIT 1), customer_id)
        RETURNING id INTO account_id;

        INSERT INTO user_login (account_id, username, password)
        VALUES (account_id, username, md5(password))
        RETURNING id INTO online_account_id;

        FOR i IN 0..2 LOOP
            
            INSERT INTO user_login_security_question (question_choice_id, login_id)
            VALUES (question_choice_ids[i], online_account_id)
            RETURNING id INTO question_choice_id;

            INSERT INTO security_question_answer (answer, question_id)
            VALUES (question_answers[i], question_choice_id);

        END LOOP;


        INSERT INTO authentication_log (log_description, log_date, account_id) VALUES ('New online account created', now(), account_id);

        RETURN account_id;
    ELSE
        RAISE NOTICE 'USERNAME ALREADY TAKEN';
        RETURN NULL;

    END IF;
    RETURN success;
END;
$$ LANGUAGE plpgsql;





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
('2019-01-01', '123456', 2),
('2018-01-01', '123456', 3),
('2017-01-01', '123456', 4),
('2016-01-01', '123456', 5),
('2017-02-03', '123456', 6),
('2018-02-04', '123456', 7),
('2020-01-01', '123456', 8),
('2020-01-01', '123456', 9);

-- sample data for user login
INSERT INTO user_login (account_id, username, password)
VALUES (1, 'johnsmith', 'b29af57c2b3bba21e9df0cece40952c6'),
(2, 'janedoe', 'ee02f771bbeb15b28ccd7bbd68faf193'),
(3, 'joebloggs', 'b29af57c2b3bba21e9df0cece40952c6'),
(4, 'johnbloggs', 'ee02f771bbeb15b28ccd7bbd68faf193'),
(5, 'janebloggs', 'b29af57c2b3bba21e9df0cece40952c6'),
(6, 'joedoe', 'ee02f771bbeb15b28ccd7bbd68faf193'),
(7, 'johndoe', 'b29af57c2b3bba21e9df0cece40952c6'),
(8, 'joesmith', 'ee02f771bbeb15b28ccd7bbd68faf193'),
(9, 'janesmith', 'b29af57c2b3bba21e9df0cece40952c6');

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

-- sample data for savings account
INSERT INTO savings_account (current_balance, interest_rate, account_id)
VALUES (2000.00, 2.05, 1),
(1000.00, 2.05, 2),
(5000.00, 2.05, 3),
(10000.00, 2.05, 4),
(20000.00, 2.05, 5),
(50000.00, 2.05, 6),
(100000.00, 2.05, 7),
(200000.00, 2.05, 8);

-- sample data for credit account
INSERT INTO credit_account (outstanding_balance, credit_limit, interest_rate, account_id)
VALUES (55.43, 2000.00, 4.22, 1),
(100.00, 1000.00, 4.22, 2),
(200.00, 5000.00, 4.22, 3),
(300.00, 10000.00, 4.22, 4),
(400.00, 20000.00, 4.22, 5),
(500.00, 50000.00, 4.22, 6),
(600.00, 100000.00, 4.22, 7),
(700.00, 200000.00, 4.22, 8);

-- sample data for debit account
INSERT INTO debit_account (current_balance, interest_rate, account_id)
VALUES (3465.43, 0.05, 1),
(1000.00, 0.05, 1),
(5000.00, 0.05, 2),
(10000.00, 0.05, 3),
(20000.00, 0.05, 4),
(50000.00, 0.05, 5),
(100000.00, 0.05, 6),
(200000.00, 0.05, 9);

-- sample data for loan
INSERT INTO loan (loan_end_date, loan_amount, loan_type, account_id)
VALUES ('2024-01-01', 10000, 'vehicle', 8),
('2023-03-04', 300000, 'mortgage', 8),
('2035-03-03', 400000, 'mortgage', 1),
('2025-04-05', 25000, 'vehicle', 1),
('2026-05-05', 34000, 'vehicle', 1),
('2023-06-07', 500000, 'mortgage', 2),
('2026-04-04', 60000, 'vehicle', 2),
('2024-03-03', 70000, 'vehicle', 2),
('2023-02-02', 800000, 'mortgage', 3),
('2022-01-01', 90000, 'vehicle', 3),
('2021-01-01', 100000, 'vehicle', 3),
('2020-01-01', 110000, 'mortgage', 4),
('2020-01-01', 12000, 'vehicle', 4),
('2020-01-01', 13000, 'vehicle', 4),
('2020-01-01', 140000, 'mortgage', 5),
('2020-01-01', 15000, 'vehicle', 5),
('2020-01-01', 16000, 'vehicle', 5),
('2020-01-01', 170000, 'mortgage', 6),
('2020-01-01', 18000, 'vehicle', 6),
('2020-01-01', 19000, 'vehicle', 6),
('2020-01-01', 200000, 'mortgage', 7),
('2020-01-01', 21000, 'vehicle', 7),
('2020-01-01', 22000, 'vehicle', 7);

CREATE SCHEMA IF NOT EXISTS staff;

SET search_path TO public, staff;