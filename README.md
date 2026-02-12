Transaction Fraud Risk Intelligence Analytics

Overview

This project builds an end-to-end fraud risk analytics pipeline using the BankSim synthetic transaction dataset.
The objective is to identify high-risk transactions through engineered behavioral signals and translate model output into business decision intelligence via a multi-page Power BI dashboard.

The workflow covers:

- SQL-based data preparation
- Feature engineering
- Risk scoring framework
- Performance evaluation metrics
- Operational and financial impact visualization

This simulates a real financial risk analytics use case aligned with card network / digital payment monitoring environments.

---

Business Problem

Financial institutions process large transaction volumes where manual review capacity is limited.
The challenge is to:

- Detect fraudulent behavior early
- Prioritize transactions for investigation
- Minimize financial losses
- Control operational review cost

This project builds a rule-driven risk scoring system to:

- Segment transactions into actionable risk tiers
- Evaluate detection performance
- Quantify financial tradeoffs between intervention and loss

---

Dataset

- Source: BankSim synthetic transaction dataset
- Transaction-level behavioral data
- Includes customer, merchant, amount, category, and fraud labels

Used for realistic fraud analytics experimentation without exposing sensitive financial data.

---

Architecture

CSV Dataset
    ↓
MySQL Ingestion (banksim_raw)
    ↓
Feature Engineering Tables
    ├── customer_velocity
    ├── customer_spend_baseline
    ├── category_risk
    └── zipcode_risk
    ↓
Risk Scoring Table
    └── transaction_risk_score
    ↓
Power BI Semantic Model
    ↓
Interactive Executive Dashboard

---

Risk Logic (Implemented)

This project uses interpretable rule-based scoring derived from behavioral signals.

1️⃣ Velocity Risk

Measures transaction frequency concentration.

- tx_per_day ≥ 5 → Score 30
- tx_per_day ≥ 3 → Score 20
- Otherwise → Score 5

---

2️⃣ Amount Deviation Risk

Detects abnormal spending relative to user baseline.

- amount ≥ 2× average → Score 40
- amount ≥ 1.5× average → Score 25
- Otherwise → Score 5

---

3️⃣ Category Risk

Captures systemic fraud exposure by transaction category.

- fraud_rate ≥ 10% → Score 30
- fraud_rate ≥ 5% → Score 20
- Otherwise → Score 5

---

4️⃣ Final Risk Score

total_risk_score =
    velocity_risk
  + amount_risk
  + category_risk

---

5️⃣ Risk Tier Assignment

- High → Score ≥ 85
- Medium → Score ≥ 55
- Low → Otherwise

This tier drives downstream prioritization and analytics.

---

Model Evaluation Metrics

Calculated using SQL aggregation:

- Precision (High Risk)
- Recall / Fraud Capture Rate
- False Positive Rate
- Tier-wise Fraud Rate

These metrics support assessment of detection effectiveness and operational impact.

---

