# Advanced SQL Analytics — Data Warehouse Reporting

> *From raw transactional data to business-ready insights — trend analysis, customer segmentation, product performance, and analytical views built entirely in T-SQL.*

---

## Overview

This project demonstrates **advanced SQL analytics** built on top of a Data Warehouse `gold` schema. Using T-SQL window functions, CTEs, and business logic, it transforms raw fact and dimension tables into a rich analytical reporting layer covering sales trends, product performance, category contribution, and customer behavior.

The project culminates in two **production-ready SQL Views** — `gold.report_customers` and `gold.vwProductReport` — that serve as the analytical foundation for BI reporting tools like Power BI.

---

## Objectives

-  Perform **time-series trend analysis** — yearly and monthly sales patterns
-  Analyze **product performance** against historical averages using window functions
-  Calculate **category contribution** to total revenue using proportional analysis
-  Segment **products by cost range** and **customers by spending behavior**
-  Build **reusable analytical views** for reporting and BI consumption

---

## Source Schema

All queries operate on the `gold` layer — the curated analytics schema of the data warehouse:

| Table | Description |
|---|---|
| `gold.fact_sales` | Core transactional sales data |
| `gold.dim_products` | Product catalog with category and cost |
| `gold.dim_customers` | Customer profiles with demographics |

---

## Analyses Performed

### 1. Sales Trend Analysis (Year & Month)

**Yearly Summary** — aggregates total sales, unique customers, and quantity by year:
```sql
SELECT YEAR(order_date), SUM(sales_amount), COUNT(DISTINCT customer_key), SUM(quantity)
FROM gold.fact_sales
GROUP BY YEAR(order_date)
```

**Monthly Breakdown** — granular month-year view for seasonality detection.

**Running Total** — cumulative sales within each year using a window function:
```sql
SUM(TotalSales) OVER (PARTITION BY YEAR(Month_Name) ORDER BY YEAR(Month_Name), MONTH(Month_Name))
```

---

### 2. Yearly Product Performance Analysis

Using a **CTE + window functions**, each product's annual sales are compared against:

| Metric | Logic |
|---|---|
| **Average Sales** | `AVG(TotalSales) OVER (PARTITION BY product_name)` |
| **Avg Deviation** | `TotalSales - AvgSales` → labeled `Above Avg / Below Avg / Avg` |
| **Year-over-Year Change** | `LAG(TotalSales) OVER (PARTITION BY product_name ORDER BY YearName)` → labeled `Increasing / Decreasing / No Change` |

>  Identifies which products are growing, declining, or plateauing relative to their own historical average.

---

### 3. Category Revenue Contribution

Calculates each product category's **share of total revenue** using a proportional window function:

```sql
ROUND((CAST(TotalSales AS FLOAT) / SUM(TotalSales) OVER()) * 100, 2)
```

>  Instantly surfaces which categories drive the business and which are underperforming.

---

### 4. Product Cost Segmentation

Products are bucketed into cost tiers using CASE logic:

| Segment | Cost Range |
|---|---|
| **Low Cost** | $0 – $723 |
| **Medium Cost** | $724 – $1,447 |
| **High Cost** | $1,448+ |

>  Enables pricing strategy analysis and margin management across the catalog.

---

### 5. Customer Segmentation (RFM-Style)

Customers are classified into three behavioral segments based on **purchase history and spending**:

| Segment | Rule |
|---|---|
|  **VIP** | Lifespan > 12 months AND Total Sales > $5,000 |
|  **Regular** | Lifespan ≥ 12 months AND Total Sales ≤ $5,000 |
|  **New** | Lifespan < 12 months |

>  Supports targeted marketing, loyalty programs, and retention strategies.

---

## Analytical Views

### `gold.report_customers`

A comprehensive customer analytics view exposing:

| Column | Description |
|---|---|
| `Customer_Name` | Full name (first + last concatenated) |
| `Age` / `AgeGroup` | Calculated age and bracket (`Under 20`, `20-29`, ..., `50+`) |
| `CustomerSegments` | VIP / Regular / New |
| `Recency` | Months since last order |
| `AvgOrderValue` | `TotalSales / TotalOrders` |
| `AvgMonthlySpent` | `TotalSales / LifeSpan` |
| `TotalOrders`, `TotalSales`, `TotalProducts` | Core activity metrics |
| `LifeSpan` | Months between first and last order |

---

### `gold.vwProductReport`

A product analytics view exposing:

| Column | Description |
|---|---|
| `ProductSegments` | Low Performer / Mid Range / High Performer |
| `Recency` | Months since last sale |
| `AverageOrderRevenue` | `TotalSales / TotalOrders` |
| `AvgMonthlyRevenue` | `TotalSales / LifeSpan` |
| `TotalOrders`, `TotalSales`, `TotalQuantity` | Core performance metrics |
| `CustomerCount` | Unique customers who purchased the product |
| `LifeSpan` | Months between first and last order of the product |

---

## Advanced SQL Concepts Used

| Concept | Applied In |
|---|---|
| **Window Functions** | `SUM() OVER`, `AVG() OVER`, `LAG() OVER` for running totals, averages, and YoY comparison |
| **CTEs** | Multi-step query decomposition in all complex analyses |
| **CASE Expressions** | Customer segments, product segments, age groups, trend labels |
| **DATEDIFF** | Lifespan, recency, and age calculations |
| **CONCAT + FORMAT** | Month-year labels and full customer names |
| **Proportional Aggregation** | `CAST / SUM() OVER()` for category contribution % |
| **DISTINCT COUNT** | Unique customer and order counting |
| **SQL Views** | Reusable reporting layer for BI tools |

---

## Tools & Technologies

| Tool | Purpose |
|---|---|
| **SQL Server** | Database engine and query execution |
| **T-SQL** | All analytics, segmentation, and view logic |
| **Gold Schema** | Curated analytics layer of the data warehouse |
| **SQL Views** | Abstraction layer for Power BI / BI consumption |

---

## Use Cases

This project is ideal for:

-  Learning **advanced T-SQL analytics** beyond basic aggregations
-  Practicing **window functions** in real business scenarios
-  Building a **reporting layer** to connect a data warehouse to Power BI
-  Understanding **RFM-style customer segmentation** in SQL
-  Portfolio projects demonstrating **production-grade SQL reporting**

---

## Outcome

-  Built a complete **SQL analytics layer** on top of a star schema data warehouse
-  Implemented **trend, performance, contribution, and segmentation** analyses
-  Delivered two **production-ready views** ready for direct BI tool consumption
-  Demonstrated advanced T-SQL skills: **window functions, CTEs, dynamic segmentation**

---

## Connect

If you found this project useful or have suggestions, feel free to open an **Issue** or submit a **Pull Request**.
