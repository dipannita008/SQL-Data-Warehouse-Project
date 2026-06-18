
/*
===========================================================
DDL Script: Create Gold Views
===========================================================

Script Purpose:
The script creates views for the Gold layer in the data warehouse.
The Gold layer represents the final dimension and fact tables (Star Schema)

Each view performs transformations and combines data from the Silver layer
to produce a clean, enriched, and business-ready dataset.

Usage:
- These views can be queried directly for analytics and reporting.
===========================================================
*/

--================================================================================
--================================================================================

--Create Dim Table : gold.dim_customers

--================================================================================
--================================================================================

IF object_id('gold.dim_customers','V') is not null
	drop view gold.dim_customers;

GO

create view gold.dim_customers as
select 
	ROW_NUMBER() over(order by cst_id) as customer_key,
	ci.cst_id as customer_id,
	ci.cst_key as customer_number,
	ci.cst_firstname as first_name,
	ci.cst_lastname as last_name,
	cl.CNTRY as country,
	ci.cst_marital_status as marital_status,
	case when ci.cst_gndr != 'N/A' then ci.cst_gndr
		 else coalesce(ca.GEN, 'N/A')
    end as gender,
	ca.BDATE as birthdate,
	ci.cst_create_date as create_date
from silver.crm_cust_info ci
left join silver.erp_CUST_AZ12 ca
on ci.cst_key = ca.CID
left join silver.erp_LOC_A101 cl
on ci.cst_key = cl.CID

GO

--================================================================================
--================================================================================

--Create Dim Table : gold.dim_products

--================================================================================
--================================================================================

IF object_id('gold.dim_products','V') is not null
	drop view gold.dim_products;

GO

create view gold.dim_products as
select 
	ROW_NUMBER() over(order by prd_key) as product_key,
	p1.prd_id as product_id,
	p1.prd_key as product_number,
	p1.prd_nm as product_name,
	p1.cat_id as category_id,
	p2.CAT as category,
	p2.SUBCAT as subcategory,
	p2.MAINTENANCE as maintenance,
	p1.prd_cost as product_cost,
	p1.prd_line as product_line,
	p1.prd_start_dt as product_start_date
from silver.crm_prd_info p1  --master data
left join 
silver.erp_PX_CAT_G1V2 p2
on p1.cat_id = p2.ID
where p1.prd_end_dt is null -- Filtering out all historical data, i.e the records that are current,that donot have an end date.(depending on business requirement)

GO


--================================================================================
--================================================================================

--Create Fact Table : gold.fact_sales

--================================================================================
--================================================================================

IF object_id('gold.fact_sales','V') is not null
	drop view gold.fact_sales;

GO

create view gold.fact_sales as 
select 
	sls_ord_num as order_number,
	pr.product_key,
	cs.customer_key,
	sls_order_dt as order_date,
	sls_ship_dt as shipping_date,
	sls_due_dt as due_date,
	sls_sales as sales,
	sls_quantity as quantity,
	sls_price as price
from silver.crm_sales_details sd
left join gold.dim_customers cs
on sd.sls_cust_id = cs.customer_id
left join gold.dim_products pr
on sd.sls_prd_key = pr.product_number

