-- TRADE CANCELLATION

CREATE TABLE trade_cancellations (
    cancellation_id SERIAL PRIMARY KEY,
    trade_id BIGINT REFERENCES trades(trade_id),
    cancellation_reason VARCHAR(255),
    cancelled_by INT REFERENCES traders(trader_id),
    cancelled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE VIEW v_cancelled_trades AS
SELECT 
    c.cancellation_id,
    c.trade_id,
    t.instrument,
    t.side,
    t.quantity,
    t.price,
    tr.name AS trader_name,
    c.cancellation_reason,
    c.cancelled_at
FROM trade_cancellations c
JOIN trades t ON c.trade_id = t.trade_id
JOIN traders tr ON c.cancelled_by = tr.trader_id;

CREATE OR REPLACE PROCEDURE sp_cancel_trade (
    IN _trade_id BIGINT,
    IN _reason VARCHAR,
    IN _cancelled_by INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO trade_cancellations (trade_id, cancellation_reason, cancelled_by)
    VALUES (_trade_id, _reason, _cancelled_by);
END;
$$;