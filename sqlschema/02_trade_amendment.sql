-- TRADE AMENDMENT

CREATE TABLE trade_amendments (
    amendment_id SERIAL PRIMARY KEY,
    trade_id BIGINT REFERENCES trades(trade_id),
    field_changed VARCHAR(50),
    old_value TEXT,
    new_value TEXT,
    amended_by INT REFERENCES traders(trader_id),
    amended_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE VIEW v_trade_amendment_log AS
SELECT 
    ta.amendment_id,
    ta.trade_id,
    ta.field_changed,
    ta.old_value,
    ta.new_value,
    tr.name AS amended_by,
    ta.amended_at
FROM trade_amendments ta
JOIN traders tr ON ta.amended_by = tr.trader_id;

CREATE OR REPLACE PROCEDURE sp_amend_trade (
    IN _trade_id BIGINT,
    IN _field VARCHAR,
    IN _new_value TEXT,
    IN _amended_by INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    _old_value TEXT;
BEGIN
    EXECUTE format('SELECT %I FROM trades WHERE trade_id = $1', _field) INTO _old_value USING _trade_id;
    EXECUTE format('UPDATE trades SET %I = $1 WHERE trade_id = $2', _field) USING _new_value, _trade_id;

    INSERT INTO trade_amendments (trade_id, field_changed, old_value, new_value, amended_by)
    VALUES (_trade_id, _field, _old_value, _new_value, _amended_by);
END;
$$;