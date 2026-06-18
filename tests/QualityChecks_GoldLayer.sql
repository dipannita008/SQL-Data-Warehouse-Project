
--Transformation Logic for Customer Object

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

--Checking if there are duplicates produced due to joining the tables

select cst_id, count(*) from (
select 
	ci.cst_id,
	ci.cst_key,
	ci.cst_firstname,
	ci.cst_lastname,
	ci.cst_marital_status,
	case when ci.cst_gndr != 'N/A' then ci.cst_gndr
		 else coalesce(ca.GEN, 'N/A')
    end as new_gen,
	ci.cst_create_date,
	ca.BDATE,
	cl.CNTRY
from silver.crm_cust_info ci
left join silver.erp_CUST_AZ12 ca
on ci.cst_key = ca.CID
left join silver.erp_LOC_A101 cl
on ci.cst_key = cl.CID
)t group by cst_id
having count(*) > 1


--Check if there is disparity between the two gender columns from the two different tables 
--Between erp and crm, we will be choosing crm as the primary one as it is about the customers, 
--incase the value is n/a then we will go with the erp table

--Data Integration
select 
	case when ci.cst_gndr != 'N/A' then ci.cst_gndr
		 else coalesce(ca.GEN, 'N/A')
    end as new_gen
from silver.crm_cust_info ci
left join silver.erp_CUST_AZ12 ca
on ci.cst_key = ca.CID
left join silver.erp_LOC_A101 cl
on ci.cst_key = cl.CID


--Gold Layer checks on the view gold.dim_customers

select distinct gender from gold.dim_customers

--Transformation Logic for Product Object

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

--Check the uniqueness of the data

select prd_key, count(*) from (
select 
	p1.prd_id,
	p1.cat_id,
	p1.prd_key,
	p1.prd_nm,
	p1.prd_cost,
	p1.prd_line,
	p1.prd_start_dt,
	p2.CAT,
	p2.SUBCAT,
	p2.MAINTENANCE
from silver.crm_prd_info p1  --master data
left join 
silver.erp_PX_CAT_G1V2 p2
on p1.cat_id = p2.ID 
where p1.prd_end_dt is null
)t
group by prd_key
having count(*)> 1

--Transformation Logic for Sales Object

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

--Final Check after the Fact table has been built

--Foreign Key Integrity (Dimensions)

select * from gold.dim_customers
select * from gold.dim_products
select * from gold.fact_sales

select * from gold.fact_sales s
left join gold.dim_customers c
on s.customer_key = c.customer_key
left join gold.dim_products p
on s.product_key = p.product_key
where c.customer_key is null
