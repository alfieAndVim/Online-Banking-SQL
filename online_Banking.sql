SET @sql_dialect = 'postgresql';

/*create schema*/
CREATE SCHEMA online_banking;

/*make all commands exist in the schema*/
SET search_path TO online_banking;

/*create a table customer with their address as an array*/
CREATE TABLE customer (
    id SERIAL PRIMARY KEY,
    init_date DATE,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    date_of_birth DATE,
    phone_number VARCHAR(255),
    address VARCHAR(255) []
);

/*create a table account with a foreign key to customer*/
CREATE TABLE account (
    id SERIAL PRIMARY KEY,
    init_date DATE,
    customer_id INTEGER REFERENCES customer(id),
);

/*create a table savings_account with a foreign key to account*/
CREATE TABLE savings_account (
    id SERIAL PRIMARY KEY,
    account_id INTEGER REFERENCES account(id),
    current_balance NUMERIC(10,2),
    interest_rate NUMERIC(5,2)
);

/*create a table credit_account with a foreign key to account*/
CREATE TABLE credit_account (
    id SERIAL PRIMARY KEY,
    account_id INTEGER REFERENCES account(id),
    current_balance NUMERIC(10,2),
    credit_limit NUMERIC(10,2),
    interest_rate NUMERIC(5,2)
);

/*create a table credit_account_application with a foreign key to credit_account*/
CREATE TABLE credit_account_application (
    id SERIAL PRIMARY KEY,
    credit_account_id INTEGER REFERENCES credit_account(id),
    is_approved BOOLEAN,
    application_date DATE,
    status VARCHAR(255)
);

/*create a table debit_account with a foreign key to account*/
CREATE TABLE debit_account (
    id SERIAL PRIMARY KEY,
    account_id INTEGER REFERENCES account(id),
    current_balance NUMERIC(10,2),
    overdraft_limit NUMERIC(10,2),
    interest_rate NUMERIC(5,2)
);

/*create a table loan with a foreign key to account*/
CREATE TABLE loan (
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
CREATE TABLE loan_application (
    id SERIAL PRIMARY KEY,
    loan_id INTEGER REFERENCES loan(id),
    is_approved BOOLEAN,
    application_date DATE,
    status VARCHAR(255)
);

/*create a table transaction with a foreign key to account*/
CREATE TABLE transaction (
    id SERIAL PRIMARY KEY,
    account_id INTEGER REFERENCES account(id),
    transaction_date DATE,
    transaction_type VARCHAR(255),
    transaction_amount NUMERIC(10,2)
);

/*create a table to log all actions*/
CREATE TABLE log (
    id SERIAL PRIMARY KEY,
    date DATE,
    action VARCHAR(255),
    customer_id INTEGER REFERENCES customer(id),
    account_id INTEGER REFERENCES account(id)
);

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
    ('2019-01-01', 'John', 'Doe', '1990-01-01', '123-456-7890', '{"123 Main St", "Apt 1", "New York, NY 10001"}'),
    ('2019-01-01', 'Jane', 'Smith', '1990-01-01', '123-456-7890', '{"123 Main St", "Apt 1", "New York, NY 10001"}');


/*insert 10 elements of sample data into account*/
INSERT INTO account (init_date, customer_id)
VALUES
    ('2019-01-01', 1),
    ('2019-01-01', 2),
    ('2019-01-01', 3),
    ('2019-01-01', 4),
    ('2019-01-01', 5),
    ('2019-01-01', 6),
    ('2019-01-01', 7),
    ('2019-01-01', 8),
    ('2019-01-01', 9),
    ('2019-01-01', 10);

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
