-- DAILY P&L

CREATE TABLE daily_pnl (
    pnl_id SERIAL PRIMARY KEY,
    account_id INT,
    instrument VARCHAR(50),
    trade_date DATE,
    realized_pnl DECIMAL(20, 5),
    unrealized_pnl DECIMAL(20, 5),
    fees DECIMAL(20, 5),
    commissions DECIMAL(20, 5)
);

CREATE VIEW v_pnl_overview AS
SELECT
    account_id,
    instrument,
    trade_date,
    realized_pnl,
    unrealized_pnl,
    fees,
    commissions,
    (realized_pnl + unrealized_pnl - fees - commissions) AS net_pnl
FROM daily_pnl;

CREATE OR REPLACE PROCEDURE sp_calculate_daily_pnl(IN _date DATE)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO daily_pnl (account_id, instrument, trade_date, realized_pnl, unrealized_pnl, fees, commissions)
    SELECT
        trader_id AS account_id,
        instrument,
        _date,
        SUM(CASE WHEN side = 'SELL' THEN quantity * price ELSE 0 END) -
        SUM(CASE WHEN side = 'BUY' THEN quantity * price ELSE 0 END) AS realized_pnl,
        0 AS unrealized_pnl,
        0 AS fees,
        0 AS commissions
    FROM trades
    WHERE DATE(trade_timestamp) = _date
    GROUP BY trader_id, instrument;
END;
$$;