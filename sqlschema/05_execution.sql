-- EXECUTION

CREATE TABLE executions (
    execution_id SERIAL PRIMARY KEY,
    order_id BIGINT REFERENCES orders(order_id),
    execution_price DECIMAL(20, 10),
    execution_quantity DECIMAL(20, 5),
    venue_id INT REFERENCES venues(venue_id),
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE VIEW v_execution_details AS
SELECT 
    e.execution_id,
    o.instrument,
    o.side,
    e.execution_quantity,
    e.execution_price,
    v.name AS venue,
    e.executed_at
FROM executions e
JOIN orders o ON e.order_id = o.order_id
JOIN venues v ON e.venue_id = v.venue_id;

CREATE OR REPLACE PROCEDURE sp_record_execution (
    IN _order_id BIGINT,
    IN _price DECIMAL,
    IN _quantity DECIMAL,
    IN _venue_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    _remaining_qty DECIMAL;
BEGIN
    INSERT INTO executions (order_id, execution_price, execution_quantity, venue_id)
    VALUES (_order_id, _price, _quantity, _venue_id);

    SELECT quantity - COALESCE(SUM(execution_quantity), 0)
    INTO _remaining_qty
    FROM orders o
    LEFT JOIN executions e ON o.order_id = e.order_id
    WHERE o.order_id = _order_id
    GROUP BY o.quantity;

    IF _remaining_qty <= 0 THEN
        UPDATE orders SET status = 'FILLED' WHERE order_id = _order_id;
        INSERT INTO order_status_log (order_id, status) VALUES (_order_id, 'FILLED');
    ELSE
        UPDATE orders SET status = 'PARTIALLY_FILLED' WHERE order_id = _order_id;
        INSERT INTO order_status_log (order_id, status) VALUES (_order_id, 'PARTIALLY_FILLED');
    END IF;
END;
$$;