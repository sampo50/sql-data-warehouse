# PostgreSQL Data Warehouse (Bronze–Silver–Gold)

End-to-end SQL data warehouse built in PostgreSQL using a layered architecture (Bronze, Silver, Gold) and consumed in Looker Studio for BI reporting.

This repository is published as a **portfolio case study** and is intentionally maintained in read-only mode.

---

## Project Overview

This project demonstrates how to design and implement a scalable analytics warehouse using:

- PostgreSQL as the warehouse engine  
- DBeaver for SQL development  
- A Bronze–Silver–Gold layering pattern  
- Star schema modeling in the Gold layer  
- BI consumption via Looker Studio  

The focus is on **data modeling, transformation structure, and analytical readiness**, not only SQL querying.

---

## Architecture

### Layered Design

| Layer | Purpose |
|------|--------|
| Bronze | Raw source extracts, minimally transformed |
| Silver | Cleaned, standardized, conformed data |
| Gold | Analytics-ready star schema and semantic views |

### Gold Layer Structure

- `dim_customers` – customer dimension  
- `dim_products` – product dimension  
- `fact_sales` – sales fact table  
- `vw_customer_profile` – customer analytical mart  
- `vw_product_profile` – product analytical mart  

The Gold layer is implemented as **views** for transparency and fast iteration and can be materialized if required for performance.

---

## Data Model

The Gold layer follows a star schema:

dim_customers 1 ────< fact_sales >──── 1 dim_products

yaml
Kopioi koodi

Derived analytical views:

- `vw_customer_profile` aggregates customer KPIs  
- `vw_product_profile` aggregates product KPIs  

This structure enables consistent business metrics and scalable BI reporting.

---

## Transformations

### Bronze → Silver
- Type casting  
- Deduplication  
- Null handling  
- Standardized naming  
- Conformed business keys  

### Silver → Gold
- Surrogate key generation  
- Star schema shaping  
- Business metric derivation  
- Analytical segmentation logic  

All transformations are written as deterministic SQL views.

---

## BI Consumption

The Gold layer is consumed in **Looker Studio**, providing:

- Customer segmentation analysis  
- Product performance analysis  
- Sales aggregation and filtering  
- Self-service exploration  

Screenshots and exports are available in the `/bi` folder.

---

## Repository Structure

/sql
/bronze
/silver
/gold

/diagrams
architecture.png
data_flow.png
erd.png

/bi
dashboard_screenshots

/docs
PostgreSQL_Bronze_Silver_Gold_Case_Study.pdf
PostgreSQL_Bronze_Silver_Gold_Case_Study.pptx

yaml
Kopioi koodi

---

## Key Design Principles

- Separation of concerns by layer  
- Business-ready modeling in Gold  
- Reusable transformations  
- BI-first schema design  
- Transparent SQL logic  

---

## Limitations

- No orchestration layer  
- No automated data quality tests  
- No incremental loading logic  

These are intentionally left as future extensions.

---

## Next Steps

- Add data quality checks (freshness, uniqueness, referential integrity)  
- Implement incremental loads and change tracking  
- Introduce orchestration and SQL migrations  
- Materialize Gold views if performance requires  

---

## Portfolio Intent

This repository is published as a **portfolio case study** to demonstrate:

- SQL transformation design  
- Warehouse modeling skills  
- Analytical thinking  
- BI enablement capability  

It is not intended as a production deployment template, but as an analytical architecture demonstration.

---

## Author

[Your Name]  
Data Analyst / Analytics Engineer  

---

## License

This project is shared for educational and portfolio purposes.
