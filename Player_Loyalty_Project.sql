USE Assignment;

SELECT * FROM raw_deposit;
SELECT * FROM raw_withdraw;
SELECT * FROM raw_gameplay;

CREATE TABLE master_data AS
SELECT
    COALESCE(d.`User Id`, w.`User Id`, g.`User Id`) AS Player_ID,
    COALESCE(d.Datetime, w.Datetime, g.Datetime) AS Activity_Date,
    IFNULL(d.Amount, 0) AS Deposit_Amount,
    IFNULL(w.Amount, 0) AS Withdraw_Amount,
    IFNULL(g.`Games Played`, 0) AS Number_of_Games_Played
FROM raw_deposit d
LEFT JOIN raw_withdraw w
    ON d.`User Id` = w.`User Id` AND d.Datetime = w.Datetime
LEFT JOIN raw_gameplay g
    ON d.`User Id` = g.`User Id` AND d.Datetime = g.Datetime

UNION

SELECT
    COALESCE(d.`User Id`, w.`User Id`, g.`User Id`),
    COALESCE(d.Datetime, w.Datetime, g.Datetime),
    IFNULL(d.Amount, 0),
    IFNULL(w.Amount, 0),
    IFNULL(g.`Games Played`, 0)
FROM raw_withdraw w
LEFT JOIN raw_deposit d
    ON w.`User Id` = d.`User Id` AND w.Datetime = d.Datetime
LEFT JOIN raw_gameplay g
    ON w.`User Id` = g.`User Id` AND w.Datetime = g.Datetime

UNION

SELECT
    COALESCE(d.`User Id`, w.`User Id`, g.`User Id`),
    COALESCE(d.Datetime, w.Datetime, g.Datetime),
    IFNULL(d.Amount, 0),
    IFNULL(w.Amount, 0),
    IFNULL(g.`Games Played`, 0)
FROM raw_gameplay g
LEFT JOIN raw_deposit d
    ON g.`User Id` = d.`User Id` AND g.Datetime = d.Datetime
LEFT JOIN raw_withdraw w
    ON g.`User Id` = w.`User Id` AND g.Datetime = w.Datetime;

ALTER TABLE master_data
ADD Loyalty_Points INT;

UPDATE master_data
SET Loyalty_Points = (Deposit_Amount / 100) - (Withdraw_Amount / 100) + (Number_of_Games_Played * 2);

CREATE TABLE final_ranking AS
SELECT 
    Player_ID,
    Deposit_Amount,
    Withdraw_Amount,
    Number_of_Games_Played,
    Loyalty_Points,
    RANK() OVER (ORDER BY Loyalty_Points DESC) AS Rank_Position
FROM master_data;

CREATE TABLE bonus_table AS
SELECT 
    Player_ID,
    Loyalty_Points,
    Rank_Position,
    CASE 
        WHEN Rank_Position = 1 THEN 500
        WHEN Rank_Position = 2 THEN 400
        WHEN Rank_Position = 3 THEN 300
        WHEN Rank_Position BETWEEN 4 AND 10 THEN 200
        WHEN Rank_Position BETWEEN 11 AND 20 THEN 100
        ELSE 50
    END AS Bonus_Amount
FROM final_ranking;

