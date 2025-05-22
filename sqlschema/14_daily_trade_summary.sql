-- DAILY TRADE SUMMARY

CREATE TABLE daily_trade_summary (
    summary_id SERIAL PRIMARY KEY,
    trader_id INT REFERENCES traders(trader_id),
    trade_date DATE,
    instrument VARCHAR(50),
    buy_volume DECIMAL(20, 5),
    sell_volume DECIMAL(20, 5),
    total_trades INT,
    pnl DECIMAL(20, 5)
);

CREATE VIEW v_trader_daily_summary AS
SELECT
    dts.trade_date,
    dts.trader_id,
    tr.name AS trader_name,
    dts.instrument,
    dts.buy_volume,
    dts.sell_volume,
    dts.pnl
FROM daily_trade_summary dts
JOIN traders tr ON dts.trader_id = tr.trader_id;

CREATE OR REPLACE PROCEDURE sp_generate_daily_summary(IN _date DATE)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO daily_trade_summary (trader_id, trade_date, instrument, buy_volume, sell_volume, total_trades, pnl)
    SELECT
        trader_id,
        _date,
        instrument,
        SUM(CASE WHEN side = 'BUY' THEN quantity ELSE 0 END) AS buy_volume,
        SUM(CASE WHEN side = 'SELL' THEN quantity ELSE 0 END) AS sell_volume,
        COUNT(*) AS total_trades,
        SUM(CASE WHEN side = 'SELL' THEN quantity * price ELSE 0 END) -
        SUM(CASE WHEN side = 'BUY' THEN quantity * price ELSE 0 END) AS pnl
    FROM trades
    WHERE DATE(trade_timestamp) = _date
    GROUP BY trader_id, instrument;
END;
$$;