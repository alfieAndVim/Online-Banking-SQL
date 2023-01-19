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
    address_postcode VARCHAR(255),
    is_verified BOOLEAN DEFAULT FALSE
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
    account_id INT REFERENCES online_account(id),
    CONSTRAINT account_number_8_digits CHECK (account_number::text ~ '^[0-9]{8}$')
);

CREATE TABLE IF NOT EXISTS savings_account (
    current_balance NUMERIC(15, 2),
    interest_rate NUMERIC(5,2),
    PRIMARY KEY (account_number)
) INHERITS (account);

CREATE TABLE IF NOT EXISTS credit_account (
    outstanding_balance NUMERIC(15, 2),
    credit_limit NUMERIC(15, 2),
    interest_rate NUMERIC(5,2),
    PRIMARY KEY (account_number)
) INHERITS (account);

CREATE TABLE IF NOT EXISTS debit_account (
    current_balance NUMERIC(15, 2),
    interest_rate NUMERIC(5,2),
    PRIMARY KEY (account_number)
) INHERITS (account);

CREATE TABLE IF NOT EXISTS loan (
    id SERIAL PRIMARY KEY,
    amount NUMERIC(15, 2),
    end_date DATE,
    loan_type VARCHAR,
    interest_rate NUMERIC(5,2),
    account_id INT REFERENCES online_account(id)
);

CREATE TABLE IF NOT EXISTS savings_statement (
    id SERIAL PRIMARY KEY,
    starting_date DATE,
    end_date DATE,
    amount NUMERIC(15,2),
    account_number INT REFERENCES savings_account(account_number)
);

CREATE TABLE IF NOT EXISTS credit_account_application (
    id SERIAL PRIMARY KEY,
    application_status VARCHAR,
    account_number INT REFERENCES credit_account(account_number)
);

CREATE TABLE IF NOT EXISTS credit_statement (
    id SERIAL PRIMARY KEY,
    starting_date DATE,
    end_date DATE,
    amount NUMERIC(15,2),
    minimum_payment NUMERIC(15,2),
    minimum_payment_due_date DATE,
    account_number INT REFERENCES credit_account(account_number)
);

CREATE TABLE IF NOT EXISTS debit_statement (
    id SERIAL PRIMARY KEY,
    starting_date DATE,
    end_date DATE,
    amount NUMERIC(15,2),
    account_number INT REFERENCES debit_account(account_number)
);

CREATE TABLE IF NOT EXISTS debit_overdraft (
    id SERIAL PRIMARY KEY,
    overdraft_usage NUMERIC(15, 2),
    overdraft_limit NUMERIC(15, 2),
    interest_rate NUMERIC(5,2),
    approved BOOLEAN,
    account_number INT REFERENCES debit_account(account_number)
);

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

CREATE TABLE IF NOT EXISTS pending_transaction (
    id SERIAL PRIMARY KEY REFERENCES transaction(id),
    account_id INT,
    is_transfer BOOLEAN,
    is_loan_payment BOOLEAN
);

CREATE TABLE IF NOT EXISTS loan_application (
    id SERIAL PRIMARY KEY,
    application_status VARCHAR,
    loan_id INT REFERENCES loan(id),
    amount NUMERIC(15,2)
);

CREATE TABLE IF NOT EXISTS loan_statement (
    id SERIAL PRIMARY KEY,
    starting_date DATE,
    amount NUMERIC(15,2),
    loan_id INT REFERENCES loan(id)
);

CREATE TABLE IF NOT EXISTS loan_payment (
    id SERIAL PRIMARY KEY,
    amount NUMERIC(15,2),
    date DATE,
    approved BOOLEAN,
    loan_id INT REFERENCES loan(id)
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

CREATE TABLE IF NOT EXISTS staff_log (
    id SERIAL PRIMARY KEY,
    log_description VARCHAR,
    log_date DATE,
    staff_name VARCHAR
);

CREATE OR REPLACE FUNCTION pseudo_fk_account_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM account WHERE account_number = NEW.account_id) THEN
        RAISE EXCEPTION 'account_id % does not exist', NEW.account_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER pseudo_fk_account_id
BEFORE INSERT OR UPDATE ON pending_transaction
FOR EACH ROW EXECUTE PROCEDURE pseudo_fk_account_id();

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

CREATE TRIGGER transaction_verification
AFTER INSERT OR UPDATE ON pending_transaction
FOR EACH ROW EXECUTE PROCEDURE transaction_verification();


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

CREATE POLICY policy_customer_client ON customer
    FOR SELECT TO user_banking_protection USING (id = policy_customer_client_check(current_user));

ALTER TABLE customer ENABLE ROW LEVEL SECURITY;


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

CREATE POLICY policy_online_account_client ON online_account
    FOR SELECT TO user_banking_protection USING (id = policy_online_account_client_check(current_user));

ALTER TABLE online_account ENABLE ROW LEVEL SECURITY;

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

CREATE POLICY policy_user_login_client ON user_login
    FOR SELECT TO user_banking_protection USING (id = policy_user_login_client_check(current_user));

ALTER TABLE user_login ENABLE ROW LEVEL SECURITY;


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

CREATE POLICY policy_account_client ON account
    FOR SELECT TO user_banking_protection USING (account_id = policy_account_client_check(current_user));

ALTER TABLE account ENABLE ROW LEVEL SECURITY;



CREATE POLICY policy_savings_account_client ON savings_account
    FOR SELECT TO user_banking_protection USING (account_id = policy_account_client_check(current_user));

ALTER TABLE savings_account ENABLE ROW LEVEL SECURITY;

CREATE POLICY policy_credit_account_client ON credit_account
    FOR SELECT TO user_banking_protection USING (account_id = policy_account_client_check(current_user));

ALTER TABLE credit_account ENABLE ROW LEVEL SECURITY;

CREATE POLICY policy_debit_account_client ON debit_account
    FOR SELECT TO user_banking_protection USING (account_id = policy_account_client_check(current_user));

ALTER TABLE debit_account ENABLE ROW LEVEL SECURITY;




CREATE SCHEMA IF NOT EXISTS bank;
SET search_path TO public, bank, client;

CREATE OR REPLACE VIEW bank.accounts AS
    SELECT account.account_number, account.account_id, online_account.sort_code
    FROM account
    INNER JOIN online_account ON account.account_id = online_account.id;

CREATE OR REPLACE VIEW bank.pending_transactions AS
    SELECT pending_transaction.id, pending_transaction.is_transfer, pending_transaction.is_loan_payment, transaction.origin_account_id, transaction.dest_account_id, transaction.dest_account_sort_code as sort_code, transaction.amount, transaction.date, get_account_type(transaction.origin_account_id) AS origin_account_type
    FROM pending_transaction
    INNER JOIN transaction ON pending_transaction.id = transaction.id;

CREATE OR REPLACE FUNCTION bank.update_loan_amounts(loan_id INT, payment_amount NUMERIC)
RETURNS BOOLEAN AS $$
DECLARE loan_updated BOOLEAN;
BEGIN
    IF EXISTS (SELECT * FROM loan WHERE id = loan_id AND amount - payment_amount < 0) THEN
        RAISE EXCEPTION 'LOAN OVERPAID';
        loan_updated = FALSE;
    ELSE
        UPDATE loan SET amount = amount - payment_amount WHERE id = loan_id;
        loan_updated = TRUE;
    END IF;
    RETURN loan_updated;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION bank.update_balance_amounts(account_number_identifier INT, amount NUMERIC)
RETURNS BOOLEAN AS $$
DECLARE balances_updated BOOLEAN;
DECLARE account_type TEXT;
BEGIN
    SELECT get_account_type(account_number_identifier) INTO account_type;
    IF account_type = 'DEBIT' THEN

        IF EXISTS (SELECT * FROM debit_account WHERE account_number = account_number_identifier AND (current_balance + (SELECT overdraft_limit - overdraft_usage FROM debit_overdraft WHERE account_number = account_number_identifier AND approved = TRUE)) - amount >= 0) THEN
            RAISE NOTICE 'SUFFICIENT FUNDS';
            UPDATE debit_account SET current_balance = current_balance - amount WHERE account_number = account_number_identifier;
            UPDATE debit_overdraft SET overdraft_usage = overdraft_usage + (SELECT SUM(current_balance*-1) FROM debit_account WHERE account_number = account_number_identifier) WHERE account_number = account_number_identifier AND approved = TRUE;
            UPDATE debit_account SET current_balance = 0 WHERE account_number = account_number_identifier AND current_balance < 0;
            balances_updated = TRUE;
        ELSE
            RAISE EXCEPTION 'INSUFFICIENT FUNDS';
            balances_updated = FALSE;
        END IF;

    ELSIF account_type = 'CREDIT' THEN
        IF EXISTS (SELECT credit_account.* FROM credit_account INNER JOIN credit_account_application ON credit_account.account_number = credit_account_application.account_number WHERE credit_account.account_number = account_number_identifier AND credit_account.outstanding_balance + amount < credit_account.credit_limit AND credit_account_application.application_status = 'APPROVED') THEN
            RAISE NOTICE 'SUFFICIENT CREDIT';
            UPDATE credit_account SET outstanding_balance = outstanding_balance - amount WHERE account_number = account_number_identifier;
            balances_updated = TRUE;
        ELSE
            RAISE EXCEPTION 'CREDIT LIMIT EXCEEDED';
            balances_updated = FALSE;
        END IF;
    ELSIF account_type = 'SAVINGS' THEN
        IF EXISTS (SELECT * FROM savings_account WHERE account_number = account_number_identifier AND current_balance - amount < 0) THEN
            RAISE EXCEPTION 'INSUFFICIENT FUNDS';
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


CREATE OR REPLACE FUNCTION bank.verify_and_update_transaction_amounts(pending_transaction_id INT, is_transfer BOOLEAN, is_loan_payment BOOLEAN)
RETURNS BOOLEAN AS $$
DECLARE transaction_approved BOOLEAN;
DECLARE account_type TEXT;
DECLARE statement_id INT;
BEGIN

    
    IF EXISTS (SELECT * FROM bank.accounts WHERE account_number = (SELECT dest_account_id FROM bank.pending_transactions WHERE id = pending_transaction_id) AND sort_code = (SELECT sort_code FROM bank.pending_transactions WHERE id = pending_transaction_id)) OR is_loan_payment THEN
        RAISE NOTICE 'INTERNAL TRANSFER OCCURING';

        IF is_loan_payment = TRUE THEN
            IF bank.update_balance_amounts((SELECT origin_account_id FROM transaction WHERE id = pending_transaction_id), (SELECT amount FROM bank.pending_transactions WHERE id = pending_transaction_id)) = TRUE THEN
                IF bank.update_loan_amounts((SELECT dest_account_id FROM transaction WHERE id = pending_transaction_id), (SELECT amount FROM bank.pending_transactions WHERE id = pending_transaction_id)) THEN
                    transaction_approved = TRUE;
                END IF;
            ELSE
                transaction_approved = FALSE;
            END IF;

            DELETE FROM pending_transaction WHERE id = pending_transaction_id;

        ELSIF is_transfer = TRUE THEN
            IF bank.update_balance_amounts((SELECT origin_account_id FROM transaction WHERE id = pending_transaction_id), (SELECT amount FROM bank.pending_transactions WHERE id = pending_transaction_id)) = TRUE THEN
                IF bank.update_balance_amounts((SELECT dest_account_id FROM transaction WHERE id = pending_transaction_id), (SELECT SUM(amount*-1) FROM bank.pending_transactions WHERE id = pending_transaction_id)) THEN
                    SELECT * FROM client.get_or_create_statement((SELECT account_id FROM account WHERE account_number = (SELECT dest_account_id FROM transaction WHERE id = pending_transaction_id)), (SELECT dest_account_id FROM transaction WHERE id = pending_transaction_id)) INTO statement_id;
                    transaction_approved = TRUE;
                END IF;
            ELSE
                transaction_approved = FALSE;
            END IF;

            DELETE FROM pending_transaction WHERE id = pending_transaction_id;

        ELSE
            IF bank.update_balance_amounts((SELECT origin_account_id FROM transaction WHERE id = pending_transaction_id), (SELECT amount FROM bank.pending_transactions WHERE id = pending_transaction_id)) = TRUE THEN
                transaction_approved = TRUE;
            ELSE
                transaction_approved = FALSE;
            END IF;

            DELETE FROM pending_transaction WHERE id = pending_transaction_id;
        END IF;
    ELSE
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

    
CREATE OR REPLACE FUNCTION bank.verify_transaction_type(pending_transaction_id INT)
RETURNS BOOLEAN AS $$
DECLARE transaction_approved BOOLEAN;
BEGIN
    -- check pending transaction exists
    IF EXISTS (SELECT * FROM bank.pending_transactions) THEN
        --check is it is a transfer

        IF EXISTS (SELECT * FROM bank.pending_transactions WHERE id = pending_transaction_id AND is_transfer = TRUE AND is_loan_payment = FALSE) THEN
            RAISE NOTICE 'Transfer transaction';
            SELECT * FROM bank.verify_and_update_transaction_amounts(pending_transaction_id, TRUE, FALSE) INTO transaction_approved;
        ELSIF EXISTS (SELECT * FROM bank.pending_transactions WHERE id = pending_transaction_id AND is_loan_payment = TRUE) THEN
            RAISE NOTICE 'Loan payment transaction';
            SELECT * FROM bank.verify_and_update_transaction_amounts(pending_transaction_id, FALSE, TRUE) INTO transaction_approved;
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

--CREATE OR REPLACE FUNCTION bank.approve_loan_payment(loan_payment_id INT)

CREATE SCHEMA IF NOT EXISTS staff;
SET search_path TO public, staff, client;


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

-- CREATE OR REPLACE VIEW staff.accounts AS
--     SELECT account.account_number, account.account_id, online_account.sort_code
--     FROM account
--     INNER JOIN online_account ON account.account_id = online_account.id;

CREATE OR REPLACE VIEW staff.credit_account_applications AS
    SELECT credit_account_application.id, credit_account_application.application_status, credit_account.account_number, credit_account.outstanding_balance, credit_account.credit_limit, credit_account.interest_rate
    FROM credit_account_application
    INNER JOIN credit_account ON credit_account_application.account_number = credit_account.account_number;

CREATE OR REPLACE VIEW staff.loan_applications AS
    SELECT loan_application.id, loan_application.application_status, loan.id as loan_id, loan.amount, loan.end_date, loan.loan_type, loan.interest_rate, loan.account_id
    FROM loan_application
    INNER JOIN loan ON loan_application.loan_id = loan.id;

CREATE OR REPLACE VIEW staff.customers AS
    SELECT online_account.id as account_id, customer.first_name, customer.last_name
    FROM online_account
    INNER JOIN customer ON customer.id = online_account.customer_id;

CREATE OR REPLACE VIEW staff.customer_personal_information AS
    SELECT * FROM customer;

CREATE OR REPLACE VIEW staff.overdrafts AS
    SELECT customers.first_name, customers.last_name, debit_overdraft.id, debit_overdraft.account_number, debit_overdraft.overdraft_usage, debit_overdraft.overdraft_limit, debit_overdraft.interest_rate
    FROM debit_overdraft
    INNER JOIN staff.accounts ON staff.accounts.account_number = debit_overdraft.account_number
    INNER JOIN staff.customers ON staff.customers.account_id = staff.accounts.account_id;

CREATE OR REPLACE FUNCTION staff.review_unverified_customer_personal_information()
RETURNS TABLE(first_name TEXT, last_name TEXT, date_of_birth DATE, address TEXT, email TEXT, phone_number TEXT) AS $$
BEGIN
    RETURN QUERY SELECT first_name, last_name, date_of_birth, address, email, phone_number
    FROM staff.customer_personal_information
    WHERE is_verified = FALSE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION staff.verify_customer_personal_information(customer_id INT)
RETURNS BOOLEAN AS $$
DECLARE customer_verified BOOLEAN;
BEGIN
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION staff.view_outstanding_credit_applications()
RETURNS TABLE(first_name TEXT, last_name TEXT, account_number INT) AS $$
BEGIN
    RETURN QUERY SELECT customers.first_name, customers.last_name, credit_account_applications.account_number
    FROM staff.customers
    INNER JOIN staff.accounts ON customers.account_id = accounts.account_id
    INNER JOIN staff.credit_card_applications ON accounts.account_number = credit_card_applications.account_number
    WHERE credit_card_applications.application_status = 'PENDING';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION staff.approve_or_deny_credit_application(account_number INT, application_approved BOOLEAN)
RETURNS BOOLEAN AS $$
DECLARE application_approved BOOLEAN;
BEGIN
    IF EXISTS (SELECT * FROM staff.credit_card_applications WHERE account_number = account_number) THEN
        IF application_approved = TRUE THEN
            UPDATE credit_account_application
            SET application_status = 'APPROVED'
            WHERE account_number = account_number;
            application_approved = TRUE;
        ELSE
            UPDATE credit_account_application
            SET application_status = 'DENIED'
            WHERE account_number = account_number;
            application_approved = FALSE;
        END IF;
    ELSE
        application_approved = FALSE;
    END IF;
    RETURN application_approved;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION staff.view_outstanding_loan_applications()
RETURNS TABLE(first_name TEXT, last_name TEXT, loan_id INT) AS $$
BEGIN
    RETURN QUERY SELECT customers.first_name, customers.last_name, loan_applications.id
    FROM staff.customers
    INNER JOIN staff.loan_applications ON loan_applications.account_id = customers.account_id
    WHERE loan_applications.application_status = 'PENDING';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION staff.approve_or_deny_loan_application(loan_id INT, application_approved BOOLEAN)
RETURNS BOOLEAN AS $$
DECLARE application_approved BOOLEAN;
BEGIN
    IF EXISTS (SELECT * FROM staff.loan_applications WHERE id = loan_id) THEN
        IF application_approved = TRUE THEN
            UPDATE loan_application
            SET application_status = 'APPROVED'
            WHERE id = loan_id;
            application_approved = TRUE;
        ELSE
            UPDATE loan_application
            SET application_status = 'DENIED'
            WHERE id = loan_id;
            application_approved = FALSE;
        END IF;
    ELSE
        application_approved = FALSE;
    END IF;
    RETURN application_approved;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION staff.view_outstanding_overdraft_applications()
RETURNS TABLE(first_name TEXT, last_name TEXT, overdraft_id INT, account_number INT, overdraft_usage NUMERIC, overdraft_limit NUMERIC, interest_rate NUMERIC) AS $$
BEGIN
    SELECT * FROM staff.overdrafts
    WHERE overdraft_approved = FALSE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION staff.approve_or_deny_overdraft_application(overdraft_id INT, application_approved BOOLEAN)
RETURNS BOOLEAN AS $$
DECLARE application_approved BOOLEAN;
BEGIN
    IF EXISTS (SELECT * FROM staff.overdrafts WHERE id = overdraft_id) THEN
        IF application_approved = TRUE THEN
            UPDATE overdraft
            SET overdraft_approved = TRUE
            WHERE id = overdraft_id;
            application_approved = TRUE;
        ELSE
            UPDATE overdraft
            SET overdraft_approved = FALSE
            WHERE id = overdraft_id;
            application_approved = FALSE;
        END IF;
    ELSE
        application_approved = FALSE;
    END IF;
    RETURN application_approved;
END;
$$ LANGUAGE plpgsql;

CREATE SCHEMA IF NOT EXISTS client;
SET search_path TO public, client;


CREATE OR REPLACE VIEW client.accounts AS
    SELECT account.account_number, account.account_id, online_account.sort_code FROM account
    INNER JOIN online_account ON account.account_id = online_account.id;

CREATE OR REPLACE VIEW client.personal_information AS
    SELECT * FROM customer;

CREATE OR REPLACE VIEW client.debit_accounts AS
    SELECT accounts.account_id, accounts.account_number, (debit_account.current_balance + debit_overdraft.overdraft_usage*-1) as current_balance, debit_account.interest_rate, debit_overdraft.overdraft_limit, debit_overdraft.overdraft_usage, debit_overdraft.interest_rate AS overdraft_interest_rate, debit_overdraft.approved as overdraft_approved
    FROM client.accounts
    INNER JOIN debit_account ON accounts.account_number = debit_account.account_number
    INNER JOIN debit_overdraft ON accounts.account_number = debit_overdraft.account_number;

CREATE OR REPLACE VIEW client.debit_accounts_statements AS
    SELECT debit_accounts.account_id, debit_accounts.account_number, debit_statement.id, debit_statement.starting_date, debit_statement.end_date, debit_statement.amount
    FROM debit_accounts
    INNER JOIN debit_statement ON debit_accounts.account_number = debit_statement.account_number;

CREATE OR REPLACE VIEW client.debit_accounts_statement AS
    SELECT debit_accounts_statements.account_id, debit_accounts_statements.account_number, debit_accounts_statements.id, debit_accounts_statements.starting_date, debit_accounts_statements.end_date, debit_accounts_statements.amount AS total_amount, transaction.origin_account_id, transaction.dest_account_id, transaction.amount, transaction.date
    FROM debit_accounts_statements
    INNER JOIN transaction ON debit_accounts_statements.id = transaction.debit_statement_id;

CREATE OR REPLACE VIEW client.credit_accounts AS
    SELECT accounts.account_id, accounts.account_number, credit_account.outstanding_balance, credit_account.credit_limit, credit_account.interest_rate, credit_account_application.application_status
    FROM client.accounts
    INNER JOIN credit_account ON accounts.account_number = credit_account.account_number
    INNER JOIN credit_account_application ON accounts.account_number = credit_account_application.account_number;

CREATE OR REPLACE VIEW client.credit_accounts_statements AS
    SELECT credit_accounts.account_id, credit_accounts.account_number, credit_statement.id, credit_statement.starting_date, credit_statement.end_date, credit_statement.amount, credit_statement.minimum_payment, credit_statement.minimum_payment_due_date
    FROM credit_accounts
    INNER JOIN credit_statement ON credit_accounts.account_number = credit_statement.account_number;

CREATE OR REPLACE VIEW client.credit_accounts_statement AS
    SELECT credit_accounts_statements.account_id, credit_accounts_statements.account_number, credit_accounts_statements.id, credit_accounts_statements.starting_date, credit_accounts_statements.end_date, credit_accounts_statements.amount AS total_amount, credit_accounts_statements.minimum_payment, credit_accounts_statements.minimum_payment_due_date, transaction.origin_account_id, transaction.dest_account_id, transaction.amount, transaction.date
    FROM credit_accounts_statements
    INNER JOIN transaction ON credit_accounts_statements.id = transaction.credit_statement_id;

CREATE OR REPLACE VIEW client.savings_accounts AS
    SELECT accounts.account_id, accounts.account_number, savings_account.current_balance, savings_account.interest_rate
    FROM client.accounts
    INNER JOIN savings_account ON accounts.account_number = savings_account.account_number;

CREATE OR REPLACE VIEW client.savings_accounts_statements AS
    SELECT savings_accounts.account_id, savings_accounts.account_number, savings_statement.id, savings_statement.starting_date, savings_statement.end_date, savings_statement.amount
    FROM savings_accounts
    INNER JOIN savings_statement ON savings_accounts.account_number = savings_statement.account_number;

CREATE OR REPLACE VIEW client.savings_accounts_statement AS
    SELECT savings_accounts_statements.account_id, savings_accounts_statements.account_number, savings_accounts_statements.id, savings_accounts_statements.starting_date, savings_accounts_statements.end_date, savings_accounts_statements.amount AS total_amount, transaction.origin_account_id, transaction.dest_account_id, transaction.amount, transaction.date
    FROM savings_accounts_statements
    INNER JOIN transaction ON savings_accounts_statements.id = transaction.savings_statement_id;

CREATE OR REPLACE VIEW client.loans AS
    SELECT loan.account_id, loan.id, loan.amount, loan.interest_rate, loan.loan_type, loan.end_date, loan_application.application_status
    FROM loan
    INNER JOIN loan_application ON loan.id = loan_application.loan_id;

CREATE OR REPLACE VIEW client.loan_statements AS
    SELECT loans.account_id, loans.id, loan_statement.id as statement_id, loan_statement.starting_date, loan_statement.amount
    FROM client.loans
    INNER JOIN loan_statement ON loans.id = loan_statement.loan_id;

CREATE OR REPLACE VIEW client.loan_applications AS
    SELECT loan.account_id, loan_application.id, loan_application.application_status, loan_application.loan_id
    FROM loan_application
    INNER JOIN loan ON loan_application.loan_id = loan.id;






CREATE OR REPLACE FUNCTION client.update_personal_information(account_identifier INT, first_name TEXT, last_name TEXT, date_of_birth DATE, phone_number TEXT, email_address TEXT, address_street TEXT, address_city TEXT, address_county TEXT, address_postcode TEXT, account_id INT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
BEGIN
    UPDATE customer SET first_name = first_name, last_name = last_name, date_of_birth = date_of_birth, phone_number = phone_number, email_address = email_address, address_street = address_street, address_city = address_city, address_county = address_county, address_postcode = address_postcode
    WHERE id = (SELECT customer_id FROM online_account WHERE id = account_identifier);

    -- INSERT INTO management_log (log_description, log_date, account_id) VALUES ('Updated personal information', CURRENT_DATE, account_identifier);
    passed = CASE WHEN @@ROWCOUNT = 1 THEN TRUE ELSE FALSE END;
    RETURN passed;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.update_password(account_identifier INT, new_password TEXT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE ROW_COUNT INT;
BEGIN
    UPDATE user_login SET password = md5(new_password)
    WHERE account_id = account_identifier;
    GET DIAGNOSTICS ROW_COUNT = ROW_COUNT;
    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_identifier, 'Updated password', CURRENT_DATE);
    passed = CASE WHEN ROW_COUNT = 1 THEN TRUE ELSE FALSE END;
    RETURN passed;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.update_email(account_identifier INT, new_email TEXT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE ROW_COUNT INT;
BEGIN
    UPDATE user_login SET email = new_email
    WHERE account_id = account_identifier;

    GET DIAGNOSTICS ROW_COUNT = ROW_COUNT;

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_identifier, 'Updated email', CURRENT_DATE);
    passed = CASE WHEN ROW_COUNT = 1 THEN TRUE ELSE FALSE END;
    RETURN passed;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION client.open_debit_account(account_id INT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE debit_account_number INT;
DECLARE next_account_number INT;
DECLARE ROW_COUNT INT;
BEGIN

    SELECT get_next_account_number() INTO next_account_number;

    INSERT INTO debit_account (account_number, account_id, current_balance, interest_rate) VALUES (next_account_number ,account_id, 0, 0.01) RETURNING account_number INTO debit_account_number;
    GET DIAGNOSTICS ROW_COUNT = ROW_COUNT;
    INSERT INTO debit_statement (starting_date, end_date, amount, account_number) VALUES (date_trunc('month', now()::date), (date_trunc('month', now()::date)) + interval '1 month - 1 day', 0, debit_account_number);
    INSERT INTO debit_overdraft (overdraft_usage, overdraft_limit, interest_rate, account_number, approved) VALUES (0, 0, 0.01, debit_account_number, FALSE);
    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_id, 'Opened debit account', CURRENT_DATE);
    passed = CASE WHEN ROW_COUNT = 1 THEN TRUE ELSE FALSE END;
    RETURN passed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION client.open_credit_account(account_id INT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE credit_account_number INT;
DECLARE next_account_number INT;
DECLARE ROW_COUNT INT;
BEGIN

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

CREATE OR REPLACE FUNCTION client.open_savings_account(account_id INT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE savings_account_id INT;
DECLARE next_account_number INT;
DECLARE ROW_COUNT INT;
BEGIN

    SELECT get_next_account_number() INTO next_account_number;

    INSERT INTO savings_account (account_number, account_id, current_balance, interest_rate) VALUES (next_account_number ,account_id, 10000, 0.01) RETURNING account_number INTO savings_account_id;
    GET DIAGNOSTICS ROW_COUNT = ROW_COUNT;
    INSERT INTO savings_statement (starting_date, end_date, amount, account_number) VALUES (date_trunc('month', now()::date), (date_trunc('month', now()::date)) + interval '1 month - 1 day', 0, savings_account_id);
    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_id, 'Opened savings account', CURRENT_DATE);
    passed = CASE WHEN ROW_COUNT = 1 THEN TRUE ELSE FALSE END;
    RETURN passed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION client.open_loan(account_id INT, loan_amount NUMERIC, loan_end_date DATE, loan_type TEXT, loan_interest_rate NUMERIC)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE loan_id INT;
DECLARE ROW_COUNT INT;
BEGIN
    INSERT INTO loan (account_id, amount, end_date, loan_type, interest_rate) VALUES (account_id, 0, loan_end_date, loan_type, loan_interest_rate) RETURNING id INTO loan_id;
    GET DIAGNOSTICS ROW_COUNT = ROW_COUNT;
    INSERT INTO loan_statement (starting_date, amount, loan_id) VALUES (date_trunc('month', now()::date), 0, loan_id);
    INSERT INTO loan_application (loan_id, application_status, amount) VALUES (loan_id, 'PENDING', loan_amount);
    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_id, 'Opened loan', CURRENT_DATE);
    passed = CASE WHEN ROW_COUNT = 1 THEN TRUE ELSE FALSE END;
    RETURN passed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION client.open_overdraft_application(account_id INT, overdraft_limit NUMERIC)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE ROW_COUNT INT;
BEGIN
    INSERT INTO overdraft_application (account_id, application_status, overdraft_limit) VALUES (account_id, 'PENDING', overdraft_limit);
    GET DIAGNOSTICS ROW_COUNT = ROW_COUNT;
    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_id, 'Opened overdraft application', CURRENT_DATE);
    passed = CASE WHEN ROW_COUNT = 1 THEN TRUE ELSE FALSE END;
    RETURN passed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION client.view_personal_information(account_id INT)
RETURNS TABLE (first_name TEXT, last_name TEXT, email TEXT, phone_number TEXT, address TEXT, city TEXT, country TEXT, postal_code TEXT) AS $$
BEGIN
    RETURN QUERY
        SELECT first_name, last_name, email, phone_number, address, city, country, postal_code
            FROM client.personal_information
        INNER JOIN client.accounts ON accounts.customer_id = personal_information.id
        WHERE accounts.id = account_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.view_accounts(account_identifier INT)
RETURNS TABLE (account_number INT, account_id INT, sort_code INT, balance NUMERIC, interest_rate NUMERIC, account_type TEXT) AS $$

BEGIN

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

CREATE OR REPLACE FUNCTION client.view_debit_accounts(account_id INT)
RETURNS TABLE (id INT, current_balance NUMERIC, interest_rate NUMERIC, overdraft_limit NUMERIC, overdraft_usage NUMERIC, overdraft_interest_rate NUMERIC, external_account_number INT, overdraft_approved BOOLEAN) AS $$
BEGIN

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_id, 'Viewed debit accounts', CURRENT_DATE);

    RETURN QUERY
        SELECT * FROM client.debit_accounts WHERE account_id = account_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.view_credit_accounts(account_id INT)
RETURNS TABLE (id INT, outstanding_balance NUMERIC, credit_limit NUMERIC, interest_rate NUMERIC, application_status TEXT) AS $$
BEGIN

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_id, 'Viewed credit accounts', CURRENT_DATE);

    RETURN QUERY
        SELECT * FROM client.credit_accounts WHERE account_id = account_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.view_savings_accounts(account_id INT)
RETURNS TABLE (id INT, current_balance NUMERIC, interest_rate NUMERIC, external_account_number INT) AS $$
BEGIN

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_id, 'Viewed savings accounts', CURRENT_DATE);

    RETURN QUERY
        SELECT * FROM client.savings_accounts WHERE account_id = account_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.view_loans(account_id INT)
RETURNS TABLE (id INT, loan_amount NUMERIC, loan_end_date DATE, loan_type TEXT, loan_interest_rate NUMERIC, application_status TEXT) AS $$
BEGIN

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_id, 'Viewed loans', CURRENT_DATE);

    RETURN QUERY
        SELECT * FROM client.loans WHERE account_id = account_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.view_savings_statements(account_identifier INT, orig_account_number INT)
RETURNS TABLE (starting_date DATE, end_date DATE, amount NUMERIC, account_id INT) AS $$
BEGIN

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_identifier, 'Viewed savings statements', CURRENT_DATE);

    RETURN QUERY
        SELECT savings_accounts_statements.starting_date, savings_accounts_statements.end_date, savings_accounts_statements.amount, savings_accounts_statements.account_id
        FROM client.savings_accounts_statements
        WHERE savings_accounts_statements.account_number = orig_account_number
        AND savings_accounts_statements.account_id = account_identifier;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.view_debit_statements(account_identifier INT, account_number INT)
RETURNS TABLE (starting_date DATE, end_date DATE, amount NUMERIC, account_id INT) AS $$
BEGIN

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_identifier, 'Viewed debit statements', CURRENT_DATE);

    RETURN QUERY
        SELECT debit_accounts_statements.account_id, debit_accounts_statements.account_number, debit_accounts_statements.starting_date, debit_accounts_statements.end_date, debit_accounts_statements.amount
        FROM client.debit_accounts_statements
        WHERE debit_accounts_statements.account_number = account_number
        AND debit_accounts_statements.account_id = account_identifier;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.view_credit_statements(account_identifier INT, account_number INT)
RETURNS TABLE (starting_date DATE, end_date DATE, amount NUMERIC, account_id INT) AS $$
BEGIN

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_identifier, 'Viewed credit statements', CURRENT_DATE);

    RETURN QUERY
        SELECT credit_accounts_statements.account_id, credit_accounts_statements.account_number, credit_accounts_statements.starting_date, credit_accounts_statements.end_date, credit_accounts_statements.amount
        FROM client.credit_accounts_statements
        WHERE credit_accounts_statements.account_number = account_number
        AND credit_accounts_statements.account_id = account_identifier;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.view_debit_statement(account_identifier INT, account_number INT, statement_id INT)
RETURNS TABLE (starting_date DATE, end_date DATE, amount NUMERIC, account_id INT) AS $$
BEGIN

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_identifier, 'Viewed debit statement', CURRENT_DATE);

    RETURN QUERY
        SELECT debit_accounts_statement.account_id, debit_accounts_statement.account_number, debit_accounts_statement.starting_date, debit_accounts_statement.end_date, debit_accounts_statement.amount
        FROM client.debit_accounts_statement
        WHERE debit_accounts_statement.account_id = account_identifier
        AND debit_accounts_statement.account_number = account_number
        AND debit_accounts_statement.statement_id = statement_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.view_credit_statement(account_identifier INT, account_number INT, statement_id INT)
RETURNS TABLE (starting_date DATE, end_date DATE, amount NUMERIC, account_id INT) AS $$
BEGIN

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_id, 'Viewed credit statement', CURRENT_DATE);

    RETURN QUERY
        SELECT credit_accounts_statement.account_id, credit_accounts_statement.account_number, credit_accounts_statement.starting_date, credit_accounts_statement.end_date, credit_accounts_statement.amount
        FROM client.credit_accounts_statement
        WHERE credit_accounts_statement.account_id = account_identifier
        AND credit_accounts_statement.account_number = account_number
        AND credit_accounts_statement.statement_id = statement_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.view_savings_statement(account_identifier INT, account_number_identifier INT, statement_id INT)
RETURNS TABLE (starting_date DATE, end_date DATE, amount NUMERIC, account_id INT) AS $$
BEGIN

    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_id, 'Viewed savings statement', CURRENT_DATE);

    RETURN QUERY
        SELECT savings_accounts_statement.account_id, savings_accounts_statement.account_number, savings_accounts_statement.starting_date, savings_accounts_statement.end_date, savings_accounts_statement.amount
        FROM client.savings_accounts_statement
        WHERE savings_accounts_statement.account_id = account_identifier
        AND savings_accounts_statement.account_number = account_number_identifier
        AND savings_accounts_statement.statement_id = statement_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.get_or_create_statement(account_identifier INT, orig_account_number INT)
RETURNS INT AS $$
DECLARE statement_id INT;
BEGIN
    CASE WHEN EXISTS (SELECT * FROM debit_account WHERE account_id = account_identifier AND account_number = orig_account_number) THEN
        IF EXISTS (SELECT * FROM debit_statement WHERE account_number = orig_account_number AND starting_date <= now()::date AND end_date >= now()::date) THEN
            SELECT id INTO statement_id FROM debit_statement WHERE account_number = orig_account_number AND starting_date <= now()::date AND end_date >= now()::date;
            RETURN statement_id;
        ELSE 
            INSERT INTO debit_statement (account_number, starting_date, end_date, amount) VALUES (orig_account_number, date_trunc('month', now()::date), now()::date + 30, 0);
            SELECT id INTO statement_id FROM debit_statement WHERE account_number = orig_account_number AND starting_date <= now()::date AND end_date >= now()::date;
            RETURN statement_id;
        END IF;
    WHEN EXISTS (SELECT * FROM credit_account WHERE account_id = account_identifier AND account_number = orig_account_number) THEN
        IF EXISTS (SELECT * FROM credit_statement WHERE account_number = orig_account_number AND starting_date <= now()::date AND end_date >= now()::date) THEN
            SELECT id INTO statement_id FROM credit_statement WHERE account_number = orig_account_number AND starting_date <= now()::date AND end_date >= now()::date;
            return statement_id;
        ELSE 
            INSERT INTO credit_statement (account_number, starting_date, end_date, amount) VALUES (orig_account_number, date_trunc('month', now()::date), now()::date + 30, 0);
            SELECT id INTO statement_id FROM credit_statement WHERE account_number = orig_account_number AND starting_date <= now()::date AND end_date >= now()::date;
            return statement_id;
        END IF;
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

CREATE OR REPLACE FUNCTION client.place_transaction_into_account(account_identifier INT, orig_account_number INT, transaction_account_number INT, transaction_amount NUMERIC, transfer_account_sort_code INT, loan_payment BOOLEAN)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE statement_id INT;
DECLARE transaction_id INT;

BEGIN
    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_identifier, 'Placed transaction into account', CURRENT_DATE);

    CASE WHEN EXISTS (SELECT * FROM debit_account WHERE account_id = account_identifier AND account_number = orig_account_number) THEN
        --UPDATE debit_account SET current_balance = current_balance - transaction_amount WHERE debit_account.account_number = orig_account_number;
        SELECT * FROM client.get_or_create_statement(account_identifier, orig_account_number) INTO statement_id;
        INSERT INTO transaction (origin_account_id, dest_account_id, amount, date, debit_statement_id, dest_account_sort_code, approved)
        VALUES (orig_account_number, transaction_account_number, transaction_amount, now(), statement_id, transfer_account_sort_code, FALSE) RETURNING id INTO transaction_id;
        INSERT INTO pending_transaction (id, account_id, is_transfer, is_loan_payment) VALUES (transaction_id, orig_account_number, true, loan_payment);

    WHEN EXISTS (SELECT * FROM credit_account WHERE account_id = account_identifier AND account_number = orig_account_number) THEN
        --UPDATE credit_account SET outstanding_balance = outstanding_balance - transaction_amount WHERE credit_account.account_number = orig_account_number;
        SELECT * FROM client.get_or_create_statement(account_identifier, orig_account_number) INTO statement_id;
        INSERT INTO transaction (origin_account_id, dest_account_id, amount, date, credit_statement_id, dest_account_sort_code, approved)
        VALUES (orig_account_number, transaction_account_number, transaction_amount, now(), statement_id, transfer_account_sort_code, FALSE) RETURNING id INTO transaction_id;
        INSERT INTO pending_transaction (id, account_id, is_transfer, is_loan_payment) VALUES (transaction_id, orig_account_number, true, loan_payment);

    WHEN EXISTS (SELECT * FROM savings_account WHERE account_id = account_identifier AND account_number = orig_account_number) THEN
        --UPDATE savings_account SET current_balance = current_balance - transaction_amount WHERE savings_account.account_number = orig_account_number;
        SELECT * FROM client.get_or_create_statement(account_identifier, orig_account_number) INTO statement_id;
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


CREATE OR REPLACE FUNCTION client.initiate_transfer(account_identifier INT, orig_account_number INT, transfer_amount NUMERIC, transfer_account_number INT, transfer_account_sort_code INT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
DECLARE internal_account_id INT;
DECLARE ROW_COUNT INT;
BEGIN
    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_identifier, 'Initiated transfer', CURRENT_DATE);

    SELECT * FROM client.place_transaction_into_account(account_identifier, orig_account_number, transfer_account_number, transfer_amount, transfer_account_sort_code, FALSE) INTO passed;

    RETURN passed;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION client.initiate_loan_payment(account_identifier INT, orig_account_number INT, payment_amount NUMERIC, loan_id INT)
RETURNS BOOLEAN AS $$
DECLARE passed BOOLEAN;
BEGIN
    INSERT INTO management_log (account_id, log_description, log_date) VALUES (account_identifier, 'Initiated loan payment', CURRENT_DATE);


    IF EXISTS (SELECT * FROM client.loans WHERE id = loan_id AND application_status = 'PENDING') THEN
        RAISE NOTICE 'Loan is not yet approved';
        RETURN FALSE;
    END IF;

    SELECT * FROM client.place_transaction_into_account(account_identifier, orig_account_number, loan_id, payment_amount, 0, TRUE) INTO passed;

    RETURN passed;

END;
$$ LANGUAGE plpgsql;
 

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
    IF NOT EXISTS (SELECT FROM unauthenticated.unauthenticated_personal_information WHERE md5(first_name) = first_naming AND md5(last_name) = last_naming AND md5(email_address) = email_addressing) THEN
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

    --check customer is verified
    IF NOT EXISTS (SELECT FROM unauthenticated.unauthenticated_personal_information WHERE id = customer_id AND md5(first_name) = first_name AND md5(last_name) = last_name AND md5(email_address) = email_address) AND is_verified = FALSE THEN
        RAISE NOTICE 'CUSTOMER INFORMATION NOT VERIFIED';
        RETURN -1;
    END IF;

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
    RETURN 1;
END;
$$ LANGUAGE plpgsql;


ALTER VIEW IF EXISTS client.personal_information OWNER TO user_banking_protection;
ALTER VIEW IF EXISTS client.accounts OWNER TO user_banking_protection;


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

-- Setting role based access control for l2 level clients
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

-- Setting role based access control for l3 level clients
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

GRANT USAGE ON SCHEMA staff TO l3;
GRANT USAGE ON SCHEMA client TO l3;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA staff TO l3;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA client TO l3;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA staff TO l3;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA client TO l3;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO l3;
GRANT INSERT ON TABLE management_log TO l3;
GRANT INSERT ON TABLE authentication_log TO l3;

-- Setting role based access control for l4 level clients
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

GRANT USAGE ON SCHEMA client TO l4;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA client TO l4;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA client TO l4;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO l4;
GRANT INSERT ON TABLE management_log TO l4;
GRANT INSERT ON TABLE authentication_log TO l4;

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
VALUES (1, 'johnsmith', '8b1a9953c4611296a827abf8c47804d7'),
(2, 'janedoe', '161e7ce7bfdc89ab4b9f52c1d4c94212'),
(3, 'joebloggs', 'fa3ebd6742c360b2d9652b7f78d9bd7d'),
(4, 'johnbloggs', 'dc647eb65e6711e155375218212b3964'),
(5, 'janebloggs', '42f749ade7f9e195bf475f37a44cafcb'),
(6, 'joedoe', '227d56be289d0f869da94b3976f7d82a'),
(7, 'johndoe', 'a94d7853871a856c71a172a599cee227'),
(8, 'joesmith', 'e433bdbeae0efbfba64964bd1c381b90'),
(9, 'janesmith', '155f25da0ecfab1f56f21310490daaa7');




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

SELECT * FROM staff.accounts;

CREATE ROLE johnsmith WITH LOGIN PASSWORD '8b1a9953c4611296a827abf8c47804d7';
CREATE ROLE janedoe WITH LOGIN PASSWORD '161e7ce7bfdc89ab4b9f52c1d4c94212';
CREATE ROLE joebloggs WITH LOGIN PASSWORD 'fa3ebd6742c360b2d9652b7f78d9bd7d';
CREATE ROLE johnbloggs WITH LOGIN PASSWORD 'dc647eb65e6711e155375218212b3964';
CREATE ROLE janebloggs WITH LOGIN PASSWORD '42f749ade7f9e195bf475f37a44cafcb';
CREATE ROLE joedoe WITH LOGIN PASSWORD '227d56be289d0f869da94b3976f7d82a';
CREATE ROLE johndoe WITH LOGIN PASSWORD 'a94d7853871a856c71a172a599cee227';
CREATE ROLE joesmith WITH LOGIN PASSWORD 'e433bdbeae0efbfba64964bd1c381b90';
CREATE ROLE janesmith WITH LOGIN PASSWORD '155f25da0ecfab1f56f21310490daaa7';

GRANT user_banking TO johnsmith, janedoe, joebloggs, johnbloggs, janebloggs, joedoe, johndoe, joesmith, janesmith;

--SET ROLE johnsmith;

SELECT * FROM client.open_savings_account(1);

--sample data for savings account
SELECT * FROM client.open_savings_account(1);
SELECT * FROM client.open_savings_account(2);
SELECT * FROM client.open_savings_account(3);
SELECT * FROM client.open_savings_account(4);

SELECT * FROM client.open_debit_account(1);
SELECT * FROM client.open_debit_account(2);
SELECT * FROM client.open_debit_account(3);
SELECT * FROM client.open_debit_account(4);

SELECT * FROM client.open_credit_account(1);
SELECT * FROM client.open_credit_account(2);
SELECT * FROM client.open_credit_account(3);
SELECT * FROM client.open_credit_account(4);

SELECT * FROM client.open_loan(1, 10000.00, '22-12-2025'::DATE, 'vehicle'::TEXT, 5.00);


SELECT * FROM client.initiate_transfer(1, 10000001, 100.00, 10000000, 123456);

SET ROLE janedoe;
SELECT * FROM client.personal_information;
SELECT * FROM client.accounts;

SELECT * FROM client.savings_accounts_statement;


--SELECT * FROM bank.verify_transaction(1);


SELECT * FROM client.view_accounts(2);

SELECT * FROM client.debit_accounts;

SELECT * FROM client.credit_accounts;


-- -- sample data for savings account
-- INSERT INTO savings_account (current_balance, interest_rate, account_id)
-- VALUES (2000.00, 2.05, 1),
-- (1000.00, 2.05, 2),
-- (5000.00, 2.05, 3),
-- (10000.00, 2.05, 4),
-- (20000.00, 2.05, 5),
-- (50000.00, 2.05, 6),
-- (100000.00, 2.05, 7),
-- (200000.00, 2.05, 8);

-- -- sample data for credit account
-- INSERT INTO credit_account (outstanding_balance, credit_limit, interest_rate, account_id)
-- VALUES (55.43, 2000.00, 4.22, 1),
-- (100.00, 1000.00, 4.22, 2),
-- (200.00, 5000.00, 4.22, 3),
-- (300.00, 10000.00, 4.22, 4),
-- (400.00, 20000.00, 4.22, 5),
-- (500.00, 50000.00, 4.22, 6),
-- (600.00, 100000.00, 4.22, 7),
-- (700.00, 200000.00, 4.22, 8);

-- -- sample data for debit account
-- INSERT INTO debit_account (current_balance, interest_rate, account_id)
-- VALUES (3465.43, 0.05, 1),
-- (1000.00, 0.05, 1),
-- (5000.00, 0.05, 2),
-- (10000.00, 0.05, 3),
-- (20000.00, 0.05, 4),
-- (50000.00, 0.05, 5),
-- (100000.00, 0.05, 6),
-- (200000.00, 0.05, 9);

-- -- sample data for loan
-- INSERT INTO loan (loan_end_date, loan_amount, loan_type, account_id)
-- VALUES ('2024-01-01', 10000, 'vehicle', 8),
-- ('2023-03-04', 300000, 'mortgage', 8),
-- ('2035-03-03', 400000, 'mortgage', 1),
-- ('2025-04-05', 25000, 'vehicle', 1),
-- ('2026-05-05', 34000, 'vehicle', 1),
-- ('2023-06-07', 500000, 'mortgage', 2),
-- ('2026-04-04', 60000, 'vehicle', 2),
-- ('2024-03-03', 70000, 'vehicle', 2),
-- ('2023-02-02', 800000, 'mortgage', 3),
-- ('2022-01-01', 90000, 'vehicle', 3),
-- ('2021-01-01', 100000, 'vehicle', 3),
-- ('2020-01-01', 110000, 'mortgage', 4),
-- ('2020-01-01', 12000, 'vehicle', 4),
-- ('2020-01-01', 13000, 'vehicle', 4),
-- ('2020-01-01', 140000, 'mortgage', 5),
-- ('2020-01-01', 15000, 'vehicle', 5),
-- ('2020-01-01', 16000, 'vehicle', 5),
-- ('2020-01-01', 170000, 'mortgage', 6),
-- ('2020-01-01', 18000, 'vehicle', 6),
-- ('2020-01-01', 19000, 'vehicle', 6),
-- ('2020-01-01', 200000, 'mortgage', 7),
-- ('2020-01-01', 21000, 'vehicle', 7),
-- ('2020-01-01', 22000, 'vehicle', 7);

-- CREATE SCHEMA IF NOT EXISTS staff;

-- SET search_path TO public, staff;
