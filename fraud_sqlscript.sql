create table banksim_raw (
step int,
customer varchar(50),
age varchar(20),
gender varchar(10),
zipcodeOri varchar(20),
merchant varchar(50),
zipMerchant varchar(20),
category varchar(50),
amount decimal(12,2),
fraud int
);

select count(*) from banksim_raw;
set global local_infile = 1;
truncate table banksim_raw;

show variables like 'local_infile';

LOAD DATA LOCAL INFILE 'C:/Users/Gowri/Downloads/banksim/frauddataset.csv.csv'
INTO TABLE banksim_raw
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

CREATE TABLE banksim_clean AS
SELECT
    step,
    customer,
    age,
    gender,
    zipcodeOri,
    merchant,
    zipMerchant,
    category,
    amount,
    fraud,

    /* Time Buckets */
    FLOOR(step / 30) AS day_bucket,
    FLOOR(step / 7) AS week_bucket,

    /* Amount Bands */
    CASE
        WHEN amount < 20 THEN 'Low'
        WHEN amount BETWEEN 20 AND 80 THEN 'Medium'
        ELSE 'High'
    END AS amount_band

FROM banksim_raw;

-- feat1 customer velocity--

create table customer_velocity as 
select customer,day_bucket,count(*) as tx_per_day 
from banksim_clean
group by customer,day_bucket;

select count(*) from customer_spend_baseline ;

-- customer spend baseline--
create table customer_spend_baseline as
select customer, avg(amount) as avg_amount,
max(amount) as max_amount
from banksim_clean 
group by customer;

-- catogory fraud risk--

create table category_risk as
select category,
count(*) as total_tx,
sum(fraud) as fraud_tx,
sum(fraud)/count(*) as fraud_rate
from banksim_clean
group by category;

-- zip risk--

create table zipcode_risk as
select zipcodeOri,
count(*) as total_tx,
sum(fraud) as fraud_tx,
sum(fraud)/count(*) as fraud_rate from banksim_clean 
group by zipcodeOri;


select count(*) from zipcode_risk;

CREATE TABLE transaction_risk_score AS
SELECT
    c.step,
    c.customer,
    c.merchant,
    c.category,
    c.amount,
    c.fraud,
    c.day_bucket,

    /* Velocity feature */
    v.tx_per_day,

    /* Spend baseline */
    b.avg_amount,
    b.max_amount,

    /* Category risk */
    cr.fraud_rate AS category_fraud_rate,

    /* --- Risk Components --- */

    /* Velocity Risk */
    CASE
        WHEN v.tx_per_day >= 5 THEN 30
        WHEN v.tx_per_day >= 3 THEN 20
        ELSE 5
    END AS velocity_risk,

    /* Amount Deviation Risk */
    CASE
        WHEN c.amount >= 2 * b.avg_amount THEN 40
        WHEN c.amount >= 1.5 * b.avg_amount THEN 25
        ELSE 5
    END AS amount_risk,

    /* Category Risk */
    CASE
        WHEN cr.fraud_rate >= 0.10 THEN 30
        WHEN cr.fraud_rate >= 0.05 THEN 20
        ELSE 5
    END AS category_risk

FROM banksim_clean c
LEFT JOIN customer_velocity v
    ON c.customer = v.customer
    AND c.day_bucket = v.day_bucket
LEFT JOIN customer_spend_baseline b
    ON c.customer = b.customer
LEFT JOIN category_risk cr
    ON c.category = cr.category;
    
    ALTER TABLE transaction_risk_score
ADD COLUMN total_risk_score INT;

set sql_safe_updates =0;

UPDATE transaction_risk_score
SET total_risk_score =
    velocity_risk + amount_risk + category_risk;
    
    ALTER TABLE transaction_risk_score
ADD COLUMN risk_tier varchar(10);


UPDATE transaction_risk_score
SET risk_tier =
    CASE
        WHEN total_risk_score >= 85 THEN 'High'
        WHEN total_risk_score >= 55 THEN 'Medium'
        ELSE 'Low'
    END;
    
    SELECT risk_tier, COUNT(*) 
FROM transaction_risk_score
GROUP BY risk_tier;

-- detection accuracy and false positives --

select 
risk_tier, count(*) as total_txns, sum(fraud) as fraud_txns, 
round(sum(fraud)/count(*) * 100,2) as fraud_rate_pct
from transaction_risk_score
group by risk_tier
order by fraud_rate_pct desc;

-- precision--
select round(sum(fraud)/count(*) * 100,2) as precision_high_pct
from transaction_risk_score
where risk_tier='High';

-- recall--
SELECT
    ROUND(
        SUM(CASE WHEN risk_tier = 'High' THEN fraud ELSE 0 END) /
        SUM(fraud) * 100, 2
    ) AS recall_high_pct
FROM transaction_risk_score;

-- false positive rate--
SELECT
    ROUND(
        (COUNT(*) - SUM(fraud)) / COUNT(*) * 100, 2
    ) AS false_positive_rate_pct
FROM transaction_risk_score
WHERE risk_tier = 'High';