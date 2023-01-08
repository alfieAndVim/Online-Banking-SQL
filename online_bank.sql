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
    username VARCHAR,
    password VARCHAR
);

CREATE TABLE IF NOT EXISTS security_question_option (
    id SERIAL PRIMARY KEY,
    question_description VARCHAR
);

CREATE TABLE IF NOT EXISTS user_login_security_question (
    id SERIAL PRIMARY KEY,
    question_choice_id INT REFERENCES security_question_option(id),
    login_id INT REFERENCES user_login(id)
);

CREATE TABLE IF NOT EXISTS security_question_answer (
    id SERIAL PRIMARY KEY,
    question_answer VARCHAR,
    question_id INT REFERENCES user_login_security_question(id)
);

CREATE TABLE IF NOT EXISTS savings_account (
    id SERIAL PRIMARY KEY,
    current_balance INT,
    interest_rate NUMERIC(5,2),
    account_id INT REFERENCES online_account(id)
);

CREATE TABLE IF NOT EXISTS credit_account (
    id SERIAL PRIMARY KEY,
    outstanding_balance INT,
    interest_rate NUMERIC(5,2),
    account_id INT REFERENCES online_account(id)
);

CREATE TABLE IF NOT EXISTS debit_account (
    id SERIAL PRIMARY KEY,
    current_balance INT,
    interest_rate NUMERIC(5,2),
    account_id INT REFERENCES online_account(id)
);

CREATE TABLE IF NOT EXISTS loan (
    id SERIAL PRIMARY KEY,
    loan_amount INT,
    loan_duration INT,
    loan_type VARCHAR,
    account_id INT REFERENCES online_account(id)
);

CREATE TABLE IF NOT EXISTS savings_statement (
    id SERIAL PRIMARY KEY,
    starting_date DATE,
    end_date DATE,
    amount INT,
    debit_account_id INT REFERENCES savings_account(id)
);

CREATE TABLE IF NOT EXISTS credit_account_application (
    id SERIAL PRIMARY KEY,
    application_status VARCHAR,
    credit_account_id INT REFERENCES credit_account(id)
);

CREATE TABLE IF NOT EXISTS credit_statement (
    id SERIAL PRIMARY KEY,
    starting_date DATE,
    end_date DATE,
    amount INT,
    minimum_payment INT,
    minimum_payment_due_date DATE,
    credit_account_id INT REFERENCES credit_account(id)
);

CREATE TABLE IF NOT EXISTS debit_statement (
    id SERIAL PRIMARY KEY,
    starting_date DATE,
    end_date DATE,
    amount INT,
    debit_account_id INT REFERENCES debit_account(id)
);

CREATE TABLE IF NOT EXISTS debit_overdraft (
    id SERIAL PRIMARY KEY,
    overdraft_usage INT,
    overdraft_limit INT,
    interest_rate NUMERIC(5,2),
    debit_account_id INT REFERENCES debit_account(id)
);

CREATE TABLE IF NOT EXISTS transaction (
    id SERIAL PRIMARY KEY,
    origin_account_id INT,
    dest_account_id INT,
    amount INT,
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

CREATE SCHEMA IF NOT EXISTS client;

SET search_path TO client;

CREATE OR REPLACE VIEW view_login AS
SELECT id, account_id, username
FROM user_login
WHERE username = current_user;

CREATE OR REPLACE VIEW view_login_secret AS
SELECT id, account_id, username, password
FROM user_login
WHERE username = current_user;

CREATE OR REPLACE VIEW view_security_questions AS
SELECT security_question_option.question_description, security_question_answer.question_answer
FROM user_login_security_question
INNER JOIN security_question_option ON user_login_security_question.question_choice_id = security_question_option.id;
INNER JOIN security_question_answer ON user_login_security_question.id = security_question_answer.question_id;

CREATE OR REPLACE VIEW view_online_account_details AS
SELECT online_account.id, online_account.date_opened, online_account.sort_code, online_account.customer_id
    FROM online_account
INNER JOIN view_login ON online_account.id = view_login.id;

CREATE OR REPLACE VIEW view_personal_information AS
SELECT * FROM customer
LEFT JOIN view_online_account_details ON customer.id = view_online_account_details.customer_id;

CREATE OR REPLACE VIEW view_loans AS
SELECT loan.id, loan.loan_amount, loan.loan_duration, loan.loan_type
FROM loan
LEFT JOIN view_online_account_details ON loan.account_id = view_online_account_details.id;

CREATE OR REPLACE VIEW view_savings_account AS
SELECT savings_account.id, savings_account.current_balance, savings_account.interest_rate
FROM savings_account
LEFT JOIN view_online_account_details ON savings_account.account_id = view_online_account_details.id;

CREATE OR REPLACE VIEW view_credit_acounts AS
SELECT credit_account.id, credit_account.outstanding_balance, credit_account.credit_limit, credit_account.interest_rate
FROM credit_account
LEFT JOIN view_online_account_details ON credit_account.account_id = view_online_account_details.id;

CREATE OR REPLACE VIEW view_debit_accounts AS
SELECT debit_account.id, debit_account.current_balance, debit_account.interest_rate
FROM debit_account
LEFT JOIN view_online_account_details ON debit_account.account_id = view_online_account_details.id;


CREATE ROLE manager WITH LOGIN PASSWORD 'manager';
CREATE ROLE employee1 WITH LOGIN PASSWORD 'employee1';
CREATE ROLE employee2 WITH LOGIN PASSWORD 'employee2';
CREATE ROLE employee3 WITH LOGIN PASSWORD 'employee3';
CREATE ROLE employee4 WITH LOGIN PASSWORD 'employee4';
CREATE ROLE employee5 WITH LOGIN PASSWORD 'employee5';

\dt
\du