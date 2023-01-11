CREATE ROLE l1 WITH CREATEDB CREATEROLE SUPERUSER;
CREATE ROLE l2 WITH CREATEROLE;
CREATE ROLE l3 WITH CREATEROLE;
CREATE ROLE l4;
CREATE ROLE l5;

CREATE ROLE manager WITH LOGIN PASSWORD 'manager';
CREATE ROLE employee1 WITH LOGIN PASSWORD 'employee1';
CREATE ROLE employee2 WITH LOGIN PASSWORD 'employee2';
CREATE ROLE employee3 WITH LOGIN PASSWORD 'employee3';
CREATE ROLE employee4 WITH LOGIN PASSWORD 'employee4';
CREATE ROLE employee5 WITH LOGIN PASSWORD 'employee5';
CREATE ROLE unauthenticated WITH LOGIN PASSWORD 'unauthenticated';

GRANT l1 TO postgres;
GRANT l2 TO manager;
GRANT l3 TO employee1;
GRANT l3 TO employee2;
GRANT l3 TO employee3;
GRANT l3 TO employee4;
GRANT l3 TO employee5;
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
    username VARCHAR(255)
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

CREATE TABLE IF NOT EXISTS savings_account (
    id SERIAL PRIMARY KEY,
    current_balance NUMERIC(15, 2),
    interest_rate NUMERIC(5,2),
    account_id INT REFERENCES online_account(id)
);

CREATE TABLE IF NOT EXISTS credit_account (
    id SERIAL PRIMARY KEY,
    outstanding_balance NUMERIC(15, 2),
    credit_limit NUMERIC(15, 2),
    interest_rate NUMERIC(5,2),
    account_id INT REFERENCES online_account(id)
);

CREATE TABLE IF NOT EXISTS debit_account (
    id SERIAL PRIMARY KEY,
    current_balance NUMERIC(15, 2),
    interest_rate NUMERIC(5,2),
    account_id INT REFERENCES online_account(id)
);

CREATE TABLE IF NOT EXISTS loan (
    id SERIAL PRIMARY KEY,
    loan_amount NUMERIC(15, 2),
    loan_end_date DATE,
    loan_type VARCHAR,
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
    log_date DATE
);

CREATE TABLE IF NOT EXISTS management_log (
    id SERIAL PRIMARY KEY,
    log_description VARCHAR,
    log_date DATE
);

CREATE TABLE IF NOT EXISTS request_log (
    id SERIAL PRIMARY KEY,
    log_description VARCHAR,
    log_date DATE
);

CREATE SCHEMA IF NOT EXISTS client;
SET search_path TO public, client;

-- Allows the user to view their login details, no password is shown
CREATE OR REPLACE VIEW client.view_login AS
SELECT id, account_id, username
FROM user_login
WHERE username = current_user;

-- Allows the user to view their security questions along with the answers given by them
CREATE OR REPLACE VIEW client.client_security_questions AS
SELECT security_question_option.question_description, security_question_answer.question_answer
FROM user_login_security_question
INNER JOIN security_question_option ON user_login_security_question.question_choice_id = security_question_option.id
INNER JOIN security_question_answer ON user_login_security_question.id = security_question_answer.question_id
INNER JOIN view_login ON user_login_security_question.login_id = view_login.id;

-- Allows the user to view their online account details such as date opened, sort code and id
CREATE OR REPLACE VIEW client.client_online_account_details AS
SELECT online_account.id, online_account.date_opened, online_account.sort_code, online_account.customer_id
    FROM online_account
INNER JOIN view_login ON online_account.id = view_login.id;

-- Allows the user to view their personal information such as name and address
CREATE OR REPLACE VIEW client.client_personal_information AS
SELECT customer.* FROM customer
INNER JOIN client_online_account_details ON customer.id = client_online_account_details.customer_id;

-- Allows a user to view their loan information such as amount and duration
CREATE OR REPLACE VIEW client.client_loans AS
SELECT loan.id, loan.loan_amount, loan.loan_end_date, loan.loan_type
FROM loan
INNER JOIN client_online_account_details ON loan.account_id = client_online_account_details.id;

CREATE OR REPLACE VIEW client.client_loan_applications AS
SELECT loan_application.application_status, loan_application.loan_id
FROM client_loans
INNER JOIN loan_application ON client_loans.id = loan_application.loan_id;

CREATE OR REPLACE VIEW client.client_loan_statements AS
SELECT loan_statement.starting_date, loan_statement.amount, loan_statement.loan_id
FROM client_loans
INNER JOIN loan_statement ON client_loans.id = loan_statement.loan_id;

-- Allows a user to view their savings account information such as balance and interest rate
CREATE OR REPLACE VIEW client.client_savings_account AS
SELECT savings_account.id, savings_account.current_balance, savings_account.interest_rate
FROM savings_account
INNER JOIN client_online_account_details ON savings_account.account_id = client_online_account_details.id;

CREATE OR REPLACE VIEW client.client_savings_account_statements AS
SELECT savings_statement.id, savings_statement.starting_date, savings_statement.end_date, savings_statement.amount, savings_statement.account_id
FROM client_savings_account
INNER JOIN savings_statement ON client_savings_account.id = savings_statement.account_id;

CREATE OR REPLACE VIEW client.client_savings_account_statement AS
SELECT transaction.origin_account_id, transaction.dest_account_id, transaction.amount, transaction.date, transaction.savings_statement_id
FROM client_savings_account_statements
INNER JOIN transaction ON client_savings_account_statements.id = transaction.savings_statement_id;

-- Allows a user to view their credit account information such as credit limit and interest rate
CREATE OR REPLACE VIEW client.client_credit_accounts AS
SELECT credit_account.id, credit_account.outstanding_balance, credit_account.credit_limit, credit_account.interest_rate
FROM credit_account
INNER JOIN client_online_account_details ON credit_account.account_id = client_online_account_details.id;

CREATE OR REPLACE VIEW client.client_credit_account_applications AS
SELECT credit_account_application.application_status, credit_account_application.account_id
FROM client_credit_accounts
INNER JOIN credit_account_application ON client_credit_accounts.id = credit_account_application.account_id;

CREATE OR REPLACE VIEW client.client_credit_account_statements AS
SELECT credit_statement.id, credit_statement.starting_date, credit_statement.end_date, credit_statement.amount, credit_statement.minimum_payment, credit_statement.minimum_payment_due_date, credit_statement.account_id
FROM client_credit_accounts
INNER JOIN credit_statement ON client_credit_accounts.id = credit_statement.account_id;

CREATE OR REPLACE VIEW client.client_credit_account_statement AS
SELECT transaction.origin_account_id, transaction.dest_account_id, transaction.amount, transaction.date, transaction.credit_statement_id
FROM client_credit_account_statements
INNER JOIN transaction ON client_credit_account_statements.id = transaction.credit_statement_id;

-- Allows a user to view their debit account information such as current balance and interest rate
CREATE OR REPLACE VIEW client.client_debit_accounts AS
SELECT debit_account.id, debit_account.current_balance, debit_account.interest_rate
FROM debit_account
INNER JOIN client_online_account_details ON debit_account.account_id = client_online_account_details.id;

CREATE OR REPLACE VIEW client.client_debit_account_statements AS
SELECT debit_statement.id, debit_statement.starting_date, debit_statement.end_date, debit_statement.amount, debit_statement.account_id
FROM client_debit_accounts
INNER JOIN debit_statement ON client_debit_accounts.id = debit_statement.account_id;

CREATE OR REPLACE VIEW client.client_debit_account_statement AS
SELECT transaction.origin_account_id, transaction.dest_account_id, transaction.amount, transaction.date, transaction.credit_statement_id
FROM client_debit_account_statements
INNER JOIN transaction ON client_debit_account_statements.id = transaction.debit_statement_id;


CREATE OR REPLACE FUNCTION client.update_personal_information(first_name TEXT, last_name TEXT, date_of_birth DATE, phone_number TEXT, email_address TEXT, address_street TEXT, address_city TEXT, address_county TEXT, address_postcode TEXT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
BEGIN
    UPDATE customer SET first_name = first_name, last_name = last_name, date_of_birth = date_of_birth, phone_number = phone_number, email_address = email_address, address_street = address_street, address_city = address_city, address_county = address_county, address_postcode = address_postcode
    WHERE id = (SELECT customer_id FROM client.client_personal_information);
    passed = CASE WHEN @@ROWCOUNT = 1 THEN TRUE ELSE FALSE END;
    RETURN passed;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.update_login_information(username TEXT, password TEXT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
BEGIN
    UPDATE user_login SET username = username
    WHERE id = (SELECT id FROM client.view_login);
    passed = CASE WHEN @@ROWCOUNT = 1 THEN TRUE ELSE FALSE END;

    EXECUTE format('ALTER USER %I WITH PASSWORD %L', username, password);

    RETURN passed;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.close_online_account()
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
BEGIN

    EXECUTE format('DROP USER %I', (SELECT username FROM client.view_login));
    passed = CASE WHEN @@ROWCOUNT = 1 THEN TRUE ELSE FALSE END;

    DELETE FROM user_login WHERE id = (SELECT id FROM client.view_login);
    passed = CASE WHEN @@ROWCOUNT = 1 THEN TRUE ELSE FALSE END;

    DELETE FROM client_online_account_details WHERE id = (SELECT id FROM client.view_login);
    passed = CASE WHEN @@ROWCOUNT = 1 THEN TRUE ELSE FALSE END;

    RETURN passed;

    SET ROLE unauthenticated;

END;

CREATE OR REPLACE FUNCTION client.open_debit_account()
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
BEGIN
    INSERT INTO debit_account (account_id, current_balance, interest_rate) VALUES ((SELECT id FROM client.view_login), 0, 0.01);
    passed = CASE WHEN @@ROWCOUNT = 1 THEN TRUE ELSE FALSE END;
    RETURN passed;
END;


CREATE SCHEMA IF NOT EXISTS unauthenticated;
SET search_path TO unauthenticated, public;

CREATE OR REPLACE VIEW unauthenticated.unauthenticated_personal_information AS
SELECT id, hashtext(first_name) AS first_name, hashtext(last_name) AS last_name, hashtext(email_address) AS email_address
FROM customer;

CREATE OR REPLACE VIEW unauthenticated.unauthenticated_customer AS
SELECT * FROM customer;

CREATE OR REPLACE VIEW unauthenticated.unauthenticated_login AS
SELECT hashtext(username) AS username FROM user_login;



-- Allows a user to insert personal information into the online banking system
CREATE OR REPLACE FUNCTION unauthenticated.create_personal_info(first_name TEXT, last_name TEXT, date_of_birth DATE, phone_number TEXT, email_address TEXT, address_street TEXT, address_city TEXT, address_county TEXT, address_postcode TEXT)
RETURNS INT AS $$
DECLARE success INT;
BEGIN
    IF NOT EXISTS (SELECT FROM unauthenticated_personal_information WHERE hashtext(first_name) = first_name AND hashtext(last_name) = last_name AND hashtext(email_address) = email_address) THEN
        INSERT INTO customer
        VALUES (first_name, last_name, date_of_birth, phone_number, email_address, address_street, address_city, address_county, address_postcode);
        success = 1;
    ELSE
        RAISE NOTICE 'CUSTOMER INFORMATION ALREADY PRESENT';
        success = 0;
    END IF;
    RETURN success;
END;
$$ LANGUAGE plpgsql;

-- Allows a user to fetch their respective customer id
CREATE OR REPLACE FUNCTION unauthenticated.get_customer_id(first_name TEXT, last_name TEXT, email_address TEXT)
RETURNS INT AS $$
DECLARE customer_id INT;
BEGIN
    SELECT id INTO customer_id FROM customer WHERE first_name = first_name AND last_name = last_name AND email_address = email_address;
    RETURN customer_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION unauthenticated.create_online_account_details(username TEXT, password TEXT, first_name TEXT, last_name TEXT, email_address TEXT, question_choice_ids INT[], question_answers TEXT[])
RETURNS INT AS $$
DECLARE success INT;
DECLARE customer_id INT;
DECLARE account_id INT;
DECLARE online_account_id INT;
DECLARE question_choice_id INT;
BEGIN
    IF NOT EXISTS (SELECT FROM user_login WHERE username = username) THEN
        customer_id = unauthenticated.get_customer_id(first_name, last_name, email_address);
        INSERT INTO online_account (date_opened, sort_code, customer_id)
        VALUES ((SELECT now()), (SELECT num FROM GENERATE_SERIES(1, 6) AS s(num) LIMIT 1), customer_id)
        RETURNING id INTO account_id;

        INSERT INTO user_login (account_id, username)
        VALUES (account_id, username)
        RETURNING id INTO online_account_id;

        FOR i IN 0..2 LOOP
            
            INSERT INTO user_login_security_question (question_choice_id, login_id)
            VALUES (question_choice_ids[i], online_account_id)
            RETURNING id INTO question_choice_id;

            INSERT INTO security_question_answer (answer, question_id)
            VALUES (question_answers[i], question_choice_id);

        END LOOP;

        success = 1;
    ELSE
        RAISE NOTICE 'USERNAME ALREADY TAKEN';
        success = 0;


    EXECUTE format(
        'CREATE ROLE %I WITH LOGIN PASSWORD %L', username, password
    );
    EXECUTE format(
        'SET ROLE %I', username
    );
    EXECUTE format(
        'GRANT USAGE ON SCHEMA client TO %I', username
    );
    EXECUTE format(
        'GRANT ALL ON ALL TABLES IN SCHEMA client TO %I', username
    );
    EXECUTE format(
        'REVOKE ALL ON ALL TABLES IN SCHEMA public TO %I', username
    );

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
INSERT INTO user_login (account_id, username)
VALUES (1, 'johnsmith'),
(2, 'janedoe'),
(3, 'joebloggs'),
(4, 'johnbloggs'),
(5, 'janebloggs'),
(6, 'joedoe'),
(7, 'johndoe'),
(8, 'joesmith'),
(9, 'janesmith');

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

REVOKE ALL ON ALL TABLES IN SCHEMA public FROM unauthenticated;
GRANT USAGE ON SCHEMA client TO unauthenticated;
GRANT ALL ON ALL TABLES IN SCHEMA client TO unauthenticated;

CREATE ROLE johnsmith WITH LOGIN PASSWORD '123456';
GRANT unauthenticated TO johnsmith;
SET ROLE johnsmith;

SELECT * FROM client.view_login;
SELECT * from client.client_security_questions;
SELECT * FROM client.client_online_account_details;
SELECT * FROM client.client_personal_information;
SELECT * FROM client.client_loans;

SELECT * FROM customer;

SELECT current_user;



SELECT current_user;

-- \dt
-- \du