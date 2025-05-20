-- LIMIT BREACH

CREATE TABLE trading_limits (
    limit_id SERIAL PRIMARY KEY,
    trader_id INT REFERENCES traders(trader_id),
    limit_type VARCHAR(50),
    limit_value DECIMAL(20, 5),
    currency VARCHAR(10),
    effective_from DATE,
    effective_to DATE
);

CREATE TABLE limit_breaches (
    breach_id SERIAL PRIMARY KEY,
    trader_id INT REFERENCES traders(trader_id),
    limit_type VARCHAR(50),
    limit_value DECIMAL(20, 5),
    actual_value DECIMAL(20, 5),
    breach_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE VIEW v_limit_violations AS
SELECT 
    lb.trader_id,
    tr.name AS trader_name,
    lb.limit_type,
    lb.limit_value,
    lb.actual_value,
    lb.breach_time
FROM limit_breaches lb
JOIN traders tr ON lb.trader_id = tr.trader_id;

CREATE OR REPLACE PROCEDURE sp_check_limits (
    IN _trader_id INT,
    IN _limit_type VARCHAR,
    IN _actual_value DECIMAL
)
LANGUAGE plpgsql
AS $$
DECLARE
    _limit_value DECIMAL;
BEGIN
    SELECT limit_value INTO _limit_value
    FROM trading_limits
    WHERE trader_id = _trader_id AND limit_type = _limit_type
      AND CURRENT_DATE BETWEEN effective_from AND effective_to
    LIMIT 1;

    IF _actual_value > _limit_value THEN
        INSERT INTO limit_breaches (trader_id, limit_type, limit_value, actual_value)
        VALUES (_trader_id, _limit_type, _limit_value, _actual_value);
    END IF;
END;
$$;