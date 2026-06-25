create table customers (
    customer_id serial primary key,
    full_name varchar(100) not null,
    email varchar(100) unique not null,
    balance numeric(10,2) default 0
);

create table products (
    product_id serial primary key,
    product_name varchar(100) not null,
    price numeric(10,2) not null,
    stock_quantity int not null
);

create table orders (
    order_id serial primary key,
    customer_id int references customers(customer_id),
    order_date timestamp default current_timestamp,
    total_amount numeric(10,2) default 0
);

create table order_items (
    order_item_id serial primary key,
    order_id int references orders(order_id),
    product_id int references products(product_id),
    quantity int not null,
    price numeric(10,2) not null
);

create table order_log (
    log_id serial primary key,
    order_id int,
    customer_id int,
    action varchar(50),
    log_date timestamp default current_timestamp
);

CREATE OR REPLACE FUNCTION calculate_order_total(
p_order_id INT
)
RETURNS NUMERIC(10,2)
LANGUAGE plpgsql
AS $$
DECLARE
v_total NUMERIC(10,2);
BEGIN
SELECT COALESCE(SUM(quantity * price), 0)
INTO v_total
FROM order_items
WHERE order_id = p_order_id;

RETURN v_total;

END;
$$;

CREATE OR REPLACE PROCEDURE create_order(
p_customer_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
	IF NOT EXISTS (
	    SELECT 
	    FROM customers
	    WHERE customer_id = p_customer_id
	) 
	THEN
	    RAISE EXCEPTION
	        'The customer does not exist';
	END IF;
	
	INSERT INTO orders (
	    customer_id,
	    order_date,
	    total_amount
	)
	VALUES (
	    p_customer_id,
	    CURRENT_TIMESTAMP,
	    0
	);
END;
$$;

CREATE OR REPLACE PROCEDURE add_product_to_order(
p_order_id INT,
p_product_id INT,
p_quantity INT
)
LANGUAGE plpgsql
AS $$
DECLARE
v_price NUMERIC(10,2);
v_stock INT;
BEGIN
	IF p_quantity <= 0 
	THEN
	    RAISE EXCEPTION
	        'Quantity must be more than zero';
	END IF;
	
	SELECT
	    price,
	    stock_quantity
	INTO
	    v_price,
	    v_stock
	FROM products
	WHERE product_id = p_product_id;
	
	IF NOT FOUND 
	THEN
	    RAISE EXCEPTION
	        'The product does not exist';
	END IF;
	
	IF v_stock < p_quantity 
	THEN
	    RAISE EXCEPTION
	        'Not enough stock';
	END IF;
	
	INSERT INTO order_items (
	    order_id,
	    product_id,
	    quantity,
	    price
	)
	VALUES (
	    p_order_id,
	    p_product_id,
	    p_quantity,
	    v_price
	);
	
	UPDATE products
	SET stock_quantity = stock_quantity - p_quantity
	WHERE product_id = p_product_id;
END;
$$;
