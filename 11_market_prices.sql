-- MARKET PRICES

CREATE TABLE market_prices (
    instrument_id VARCHAR(50) REFERENCES instruments(instrument_id),
    timestamp TIMESTAMP,
    open DECIMAL(20, 10),
    high DECIMAL(20, 10),
    low DECIMAL(20, 10),
    close DECIMAL(20, 10),
    last_price DECIMAL(20, 10),
    volume BIGINT,
    PRIMARY KEY (instrument_id, timestamp)
);

CREATE VIEW v_price_summary AS
SELECT
    instrument_id,
    DATE_TRUNC('day', timestamp) AS day,
    MAX(high) AS high,
    MIN(low) AS low,
    FIRST_VALUE(open) OVER (PARTITION BY instrument_id, DATE_TRUNC('day', timestamp) ORDER BY timestamp) AS open,
    LAST_VALUE(close) OVER (
        PARTITION BY instrument_id, DATE_TRUNC('day', timestamp)
        ORDER BY timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS close,
    SUM(volume) AS daily_volume
FROM market_prices
GROUP BY instrument_id, DATE_TRUNC('day', timestamp);

CREATE OR REPLACE PROCEDURE sp_upsert_market_price (
    IN _instrument_id VARCHAR,
    IN _timestamp TIMESTAMP,
    IN _open DECIMAL,
    IN _high DECIMAL,
    IN _low DECIMAL,
    IN _close DECIMAL,
    IN _last_price DECIMAL,
    IN _volume BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM market_prices
        WHERE instrument_id = _instrument_id AND timestamp = _timestamp
    ) THEN
        UPDATE market_prices
        SET open = _open,
            high = _high,
            low = _low,
            close = _close,
            last_price = _last_price,
            volume = _volume
        WHERE instrument_id = _instrument_id AND timestamp = _timestamp;
    ELSE
        INSERT INTO market_prices (
            instrument_id, timestamp, open, high, low, close, last_price, volume
        ) VALUES (
            _instrument_id, _timestamp, _open, _high, _low, _close, _last_price, _volume
        );
    END IF;
END;
$$;