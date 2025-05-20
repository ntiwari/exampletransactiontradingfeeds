-- SETTLEMENT INSTRUCTION

CREATE TABLE settlement_instructions (
    settlement_id SERIAL PRIMARY KEY,
    trade_id BIGINT REFERENCES trades(trade_id),
    account_id INT,
    counterparty VARCHAR(100),
    settlement_date DATE,
    settlement_amount DECIMAL(20, 10),
    currency VARCHAR(10),
    settlement_status VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE VIEW v_pending_settlements AS
SELECT
    s.settlement_id,
    s.trade_id,
    s.account_id,
    s.counterparty,
    s.settlement_date,
    s.settlement_amount,
    s.currency,
    s.settlement_status
FROM settlement_instructions s
WHERE settlement_status = 'PENDING';

CREATE OR REPLACE PROCEDURE sp_generate_settlement (
    IN _trade_id BIGINT,
    IN _account_id INT,
    IN _counterparty VARCHAR,
    IN _settlement_date DATE,
    IN _currency VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    _amount DECIMAL;
BEGIN
    SELECT quantity * price INTO _amount FROM trades WHERE trade_id = _trade_id;

    INSERT INTO settlement_instructions (
        trade_id, account_id, counterparty, settlement_date,
        settlement_amount, currency, settlement_status
    )
    VALUES (
        _trade_id, _account_id, _counterparty, _settlement_date,
        _amount, _currency, 'PENDING'
    );
END;
$$;