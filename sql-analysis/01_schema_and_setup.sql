CREATE TABLE customers (
	customer_id VARCHAR(30) PRIMARY KEY,
	first_name VARCHAR (50),
	last_name VARCHAR(50),
	gender VARCHAR (15),
	date_of_birth DATE,
	city VARCHAR (50),
	region VARCHAR (50),
	occupation VARCHAR (50),
	account_type VARCHAR(30),
	signup_date DATE,
	income_band VARCHAR (30),
	account_status VARCHAR(20)
) ;

CREATE TABLE transactions (
	transaction_id VARCHAR(30) PRIMARY KEY,
	customer_Id	VARCHAR(30),
	transaction_date DATE,
	transaction_type VARCHAR(30),
	payment_method	VARCHAR (30),
	channel	VARCHAR (30),
	transaction_amount	FLOAT,
	fee_amount	FLOAT,
	transaction_status VARCHAR (30)
) ;
