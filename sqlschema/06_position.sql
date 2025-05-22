-- POSITION

CREATE TABLE positions (
    position_id SERIAL PRIMARY KEY,
    account_id INT,
    instrument VARCHAR(50),
    net_position DECIMAL(20, 5),
    average_price DECIMAL(20, 10),
    mark_to_market DECIMAL(20, 10),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE position_movements (
    movement_id SERIAL PRIMARY KEY,
    account_id INT,
    instrument VARCHAR(50),
    delta_quantity DECIMAL(20, 5),
    delta_value DECIMAL(20, 10),
    source_trade_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE VIEW v_position_summary AS
SELECT
    p.account_id,
    p.instrument,
    p.net_position,
    p.average_price,
    p.mark_to_market,
    p.last_updated
FROM positions p
WHERE net_position != 0;

CREATE OR REPLACE PROCEDURE sp_update_position (
    IN _account_id INT,
    IN _instrument VARCHAR,
    IN _delta_qty DECIMAL,
    IN _price DECIMAL,
    IN _trade_id BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    _existing_qty DECIMAL;
    _existing_value DECIMAL;
    _new_value DECIMAL;
BEGIN
    INSERT INTO position_movements (account_id, instrument, delta_quantity, delta_value, source_trade_id)
    VALUES (_account_id, _instrument, _delta_qty, _delta_qty * _price, _trade_id);

    IF EXISTS (SELECT 1 FROM positions WHERE account_id = _account_id AND instrument = _instrument) THEN
        SELECT net_position, average_price * net_position INTO _existing_qty, _existing_value
        FROM positions
        WHERE account_id = _account_id AND instrument = _instrument;

        _new_value := _existing_value + (_delta_qty * _price);
        UPDATE positions
        SET net_position = net_position + _delta_qty,
            average_price = CASE 
                WHEN (net_position + _delta_qty) = 0 THEN 0
                ELSE _new_value / (net_position + _delta_qty)
            END,
            last_updated = CURRENT_TIMESTAMP
        WHERE account_id = _account_id AND instrument = _instrument;

    ELSE
        INSERT INTO positions (account_id, instrument, net_position, average_price, mark_to_market)
        VALUES (_account_id, _instrument, _delta_qty, _price, 0);
    END IF;
END;
$$;