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

CREATE OR REPLACE FUNCTION update_order_total_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
	UPDATE orders
	SET total_amount =
	    calculate_order_total(
	        COALESCE(NEW.order_id, OLD.order_id)
	    )
	WHERE order_id =
	    COALESCE(NEW.order_id, OLD.order_id);
	RETURN NULL;
END;
$$;

CREATE TRIGGER update_order_total_triger
AFTER INSERT OR UPDATE OR DELETE
ON order_items
FOR EACH ROW
EXECUTE FUNCTION update_order_total_trigger();

CREATE OR REPLACE FUNCTION order_log_creation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO order_log (
	    order_id,
	    customer_id,
	    action,
	    log_date
	)
	VALUES (
	    NEW.order_id,
	    NEW.customer_id,
	    'ORDER_CREATED',
	    CURRENT_TIMESTAMP
	);
	
	RETURN NEW;
END;
$$;

CREATE TRIGGER order_log_triger
AFTER INSERT
ON orders
FOR EACH ROW
EXECUTE FUNCTION order_log_creation();



INSERT INTO customers(full_name, email, balance) --creating a new customer
VALUES
('John Smith', 'john@example.com', 1000)

INSERT INTO products(product_name, price, stock_quantity) --creating a new product
VALUES
('TV', 1500, 15)

call create_order(2) --creates an order
call create_order(80) --raises exeption (no customer with such id currently)

call add_product_to_order(1,2,1) --adds a ptoduct to order
call add_product_to_order(1,20,1) --raises exeption (no product with such id currently)
call add_product_to_order(1,2,-1) --raises exeption (negative quantity)
call add_product_to_order(1,2,50) --raises exeption (not enough stock currently)

select --order total amount is increased after adding a product to it
	order_id,
	total_amount
FROM orders
WHERE order_id = 1;

select --stock quantity decreased after adding it to an order
	product_id,
	product_name,
	stock_quantity
FROM products;

select* --new order logs have been added
from order_log ol 
