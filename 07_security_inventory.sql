-- SECURITIES INVENTORY

CREATE TABLE security_inventory (
    inventory_id SERIAL PRIMARY KEY,
    security_id VARCHAR(50),
    available_quantity DECIMAL(20, 5),
    borrowed_quantity DECIMAL(20, 5),
    location VARCHAR(50),
    valuation DECIMAL(20, 10),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE VIEW v_security_availability AS
SELECT
    security_id,
    available_quantity,
    borrowed_quantity,
    (available_quantity - borrowed_quantity) AS net_quantity,
    location,
    valuation
FROM security_inventory;

CREATE OR REPLACE PROCEDURE sp_update_inventory (
    IN _security_id VARCHAR,
    IN _delta_available DECIMAL,
    IN _delta_borrowed DECIMAL,
    IN _location VARCHAR,
    IN _valuation DECIMAL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM security_inventory WHERE security_id = _security_id AND location = _location) THEN
        UPDATE security_inventory
        SET available_quantity = available_quantity + _delta_available,
            borrowed_quantity = borrowed_quantity + _delta_borrowed,
            valuation = _valuation,
            updated_at = CURRENT_TIMESTAMP
        WHERE security_id = _security_id AND location = _location;
    ELSE
        INSERT INTO security_inventory (security_id, available_quantity, borrowed_quantity, location, valuation)
        VALUES (_security_id, _delta_available, _delta_borrowed, _location, _valuation);
    END IF;
END;
$$;