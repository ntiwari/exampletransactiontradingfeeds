-- INSTRUMENT MASTER

CREATE TABLE instruments (
    instrument_id VARCHAR(50) PRIMARY KEY,
    symbol VARCHAR(50),
    ISIN VARCHAR(50),
    asset_class VARCHAR(50),
    expiry_date DATE,
    tick_size DECIMAL(10, 5),
    lot_size DECIMAL(10, 5),
    status VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE VIEW v_active_instruments AS
SELECT * FROM instruments WHERE status = 'ACTIVE';

CREATE OR REPLACE PROCEDURE sp_upsert_instrument (
    IN _instrument_id VARCHAR,
    IN _symbol VARCHAR,
    IN _isin VARCHAR,
    IN _asset_class VARCHAR,
    IN _expiry_date DATE,
    IN _tick_size DECIMAL,
    IN _lot_size DECIMAL,
    IN _status VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM instruments WHERE instrument_id = _instrument_id) THEN
        UPDATE instruments
        SET symbol = _symbol,
            ISIN = _isin,
            asset_class = _asset_class,
            expiry_date = _expiry_date,
            tick_size = _tick_size,
            lot_size = _lot_size,
            status = _status
        WHERE instrument_id = _instrument_id;
    ELSE
        INSERT INTO instruments (
            instrument_id, symbol, ISIN, asset_class, expiry_date,
            tick_size, lot_size, status
        )
        VALUES (
            _instrument_id, _symbol, _isin, _asset_class, _expiry_date,
            _tick_size, _lot_size, _status
        );
    END IF;
END;
$$;