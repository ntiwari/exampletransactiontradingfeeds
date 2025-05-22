-- CASH MOVEMENT

CREATE TABLE cash_movements (
    movement_id SERIAL PRIMARY KEY,
    account_id INT,
    amount DECIMAL(20, 5),
    currency VARCHAR(10),
    movement_type VARCHAR(50),
    reference_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE VIEW v_cash_balance AS
SELECT
    account_id,
    currency,
    SUM(CASE WHEN movement_type IN ('DEPOSIT', 'MARGIN_CALL') THEN amount ELSE -amount END) AS current_balance
FROM cash_movements
GROUP BY account_id, currency;

CREATE OR REPLACE PROCEDURE sp_record_cash_movement (
    IN _account_id INT,
    IN _amount DECIMAL,
    IN _currency VARCHAR,
    IN _movement_type VARCHAR,
    IN _reference_id VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO cash_movements (account_id, amount, currency, movement_type, reference_id)
    VALUES (_account_id, _amount, _currency, _movement_type, _reference_id);
END;
$$;