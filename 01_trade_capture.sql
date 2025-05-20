-- TRADE CAPTURE

CREATE TABLE traders (
    trader_id INT PRIMARY KEY,
    name VARCHAR(100),
    desk VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE venues (
    venue_id INT PRIMARY KEY,
    name VARCHAR(100),
    region VARCHAR(50)
);

CREATE TABLE trades (
    trade_id BIGINT PRIMARY KEY,
    trade_timestamp TIMESTAMP,
    instrument VARCHAR(50),
    side VARCHAR(4) CHECK (side IN ('BUY', 'SELL')),
    quantity DECIMAL(20, 5),
    price DECIMAL(20, 10),
    trader_id INT REFERENCES traders(trader_id),
    venue_id INT REFERENCES venues(venue_id),
    order_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE VIEW v_latest_trades AS
SELECT 
    t.trade_id,
    t.trade_timestamp,
    t.instrument,
    t.side,
    t.quantity,
    t.price,
    tr.name AS trader_name,
    v.name AS venue_name
FROM trades t
JOIN traders tr ON t.trader_id = tr.trader_id
JOIN venues v ON t.venue_id = v.venue_id
WHERE t.trade_timestamp >= CURRENT_DATE - INTERVAL '1 day';

CREATE OR REPLACE PROCEDURE sp_insert_trade (
    IN _trade_id BIGINT,
    IN _timestamp TIMESTAMP,
    IN _instrument VARCHAR,
    IN _side VARCHAR,
    IN _quantity DECIMAL,
    IN _price DECIMAL,
    IN _trader_id INT,
    IN _venue_id INT,
    IN _order_id BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO trades (
        trade_id, trade_timestamp, instrument, side, quantity, price, trader_id, venue_id, order_id
    )
    VALUES (
        _trade_id, _timestamp, _instrument, _side, _quantity, _price, _trader_id, _venue_id, _order_id
    );
END;
$$;

CREATE OR REPLACE PROCEDURE sp_get_trade_summary(IN _date DATE)
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE 'Trade Summary for %', _date;
    SELECT trader_id, COUNT(*) AS trade_count, SUM(quantity * price) AS notional
    FROM trades
    WHERE DATE(trade_timestamp) = _date
    GROUP BY trader_id;
END;
$$;