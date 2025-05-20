-- ORDER BOOK

CREATE TABLE orders (
    order_id BIGINT PRIMARY KEY,
    instrument VARCHAR(50),
    side VARCHAR(4) CHECK (side IN ('BUY', 'SELL')),
    quantity DECIMAL(20, 5),
    price DECIMAL(20, 10),
    status VARCHAR(20),
    trader_id INT REFERENCES traders(trader_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE order_status_log (
    log_id SERIAL PRIMARY KEY,
    order_id BIGINT REFERENCES orders(order_id),
    status VARCHAR(20),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE VIEW v_active_orders AS
SELECT * FROM orders WHERE status IN ('NEW', 'PARTIALLY_FILLED');

CREATE OR REPLACE PROCEDURE sp_place_order (
    IN _order_id BIGINT,
    IN _instrument VARCHAR,
    IN _side VARCHAR,
    IN _quantity DECIMAL,
    IN _price DECIMAL,
    IN _trader_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO orders (order_id, instrument, side, quantity, price, status, trader_id)
    VALUES (_order_id, _instrument, _side, _quantity, _price, 'NEW', _trader_id);

    INSERT INTO order_status_log (order_id, status)
    VALUES (_order_id, 'NEW');
END;
$$;

CREATE OR REPLACE PROCEDURE sp_cancel_order (
    IN _order_id BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE orders SET status = 'CANCELLED' WHERE order_id = _order_id;
    INSERT INTO order_status_log (order_id, status) VALUES (_order_id, 'CANCELLED');
END;
$$;