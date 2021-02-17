CREATE SCHEMA dw;

-- ************************************** calendar_dim
DROP TABLE IF EXISTS dw.calendar_dim CASCADE;
CREATE TABLE dw.calendar_dim
(
 date_id serial NOT NULL,
 year    int NOT NULL,
 quarter int NOT NULL,
 month   int NOT NULL,
 week    int NOT NULL,
 weekday varchar(20) NOT NULL,
 dates  date NOT NULL,
 leap    varchar(20) NOT NULL,
 CONSTRAINT PK_calendar_dim PRIMARY KEY ( date_id )
);

--deleting rows
TRUNCATE TABLE dw.calendar_dim;

--insert rows
INSERT INTO dw.calendar_dim
SELECT 
TO_CHAR(date,'yyyymmdd')::int AS date_id,  
       EXTRACT('year' FROM date)::int AS year,
       EXTRACT('quarter' FROM date)::int AS quarter,
       EXTRACT('month' FROM date)::int AS month,
       EXTRACT('week' FROM date)::int AS week,
       TO_CHAR(date, 'dy') AS week_day,
       date::date,
       EXTRACT('day' FROM
               (date + interval '2 month - 1 day')
              ) = 29
       AS leap
  FROM generate_series(date '2000-01-01',
                       date '2030-01-01',
                       interval '1 day')
       AS t(date);
	   
--checking
SELECT * FROM dw.calendar_dim; 

-- ************************************** customer

DROP TABLE IF EXISTS dw.customer CASCADE;
CREATE TABLE dw.customer
(
 customer_number  serial NOT NULL,
 customer_id      varchar(15) NOT NULL,
 customer_name    varchar(50) NOT NULL,
 segment          varchar(50) NOT NULL,
 first_order_date date NOT NULL,
 CONSTRAINT PK_customer PRIMARY KEY ( customer_number )
);

--deleting rows
TRUNCATE TABLE dw.customer CASCADE;

--inserting
INSERT INTO dw.customer 
SELECT 0+ROW_NUMBER() OVER(),
	   customer_id,
	   customer_name,
	   segment,
	   first_order_date
FROM (SELECT DISTINCT customer_id,
			 customer_name,
			 segment,
			 MIN(order_date) OVER (PARTITION BY customer_id) AS first_order_date
	  FROM public.orders
	  ORDER BY first_order_date
	 ) a;

--checking
SELECT * FROM dw.customer;

-- ************************************** people

DROP TABLE IF EXISTS dw.people CASCADE;
CREATE TABLE dw.people
(
 region_id int NOT NULL,
 person    varchar(50) NOT NULL,
 region    varchar(50) NOT NULL,
 CONSTRAINT PK_people PRIMARY KEY (region_id)
);

--deleting rows
TRUNCATE TABLE dw.people CASCADE;

--inserting
INSERT INTO dw.people 
SELECT 0+ROW_NUMBER() OVER() AS region_id,
	   person,
	   region
FROM public.people
;

--checking
SELECT * FROM dw.people;
	   
 -- ************************************** geography

DROP TABLE IF EXISTS dw.geography CASCADE;
CREATE TABLE dw.geography
(
 geo_id      serial NOT NULL,
 country     varchar(50) NOT NULL,
 region_id   int NOT NULL,
 state       varchar(25) NOT NULL,
 city        varchar(50) NOT NULL,
 postal_code varchar(10) NOT NULL,
 CONSTRAINT PK_geography PRIMARY KEY ( geo_id ),
 CONSTRAINT FK_86 FOREIGN KEY ( region_id ) REFERENCES dw.people ( region_id )
);

CREATE INDEX fkIdx_87 ON dw.geography
(
 region_id
);

--deleting rows
TRUNCATE TABLE dw.geography CASCADE;

-- City Burlington, Vermont doesn't have postal code
UPDATE public.orders
SET postal_code = '05401'
WHERE city = 'Burlington'  AND postal_code IS NULL;

SELECT * FROM dw.geography
WHERE city = 'Burlington';

--inserting
INSERT INTO dw.geography 
SELECT 0+ROW_NUMBER() OVER() AS geo_id,
	   country,
	   region_id,
	   state,
	   city,
	   postal_code
FROM (SELECT DISTINCT country,
	   		 region_id,
	   		 state,
	   		 city,
	   		 postal_code
	  FROM public.orders LEFT JOIN dw.people ON public.orders.region = dw.people.region
	  ORDER BY postal_code
	 ) a;


--checking
SELECT * FROM dw.geography;

-- ************************************** product

DROP TABLE IF EXISTS dw.product CASCADE;
CREATE TABLE dw.product
(
 product_number serial NOT NULL,
 category       varchar(50) NOT NULL,
 subcategory    varchar(50) NOT NULL,
 product_name   varchar(150) NOT NULL,
 product_id     varchar(50) NOT NULL,
 CONSTRAINT PK_product PRIMARY KEY ( product_number )
);

--deleting rows
TRUNCATE TABLE dw.product CASCADE;

--inserting
INSERT INTO dw.product 
SELECT 0+ROW_NUMBER() OVER() AS product_number,
	   category,
	   subcategory,
	   product_name,
	   product_id
FROM (SELECT DISTINCT category,
	   		 subcategory,
	   		 product_name,
	   		 product_id
	  FROM public.orders
	  ORDER BY product_id
	 ) a;

--checking
SELECT * FROM dw.product;

-- ************************************** shipping_dim

DROP TABLE IF EXISTS dw.shipping_dim CASCADE;
CREATE TABLE dw.shipping_dim
(
 ship_id      serial NOT NULL,
 ship_mode varchar(25) NOT NULL,
 CONSTRAINT PK_shipping PRIMARY KEY ( ship_id )
 );

--deleting rows
TRUNCATE TABLE dw.shipping_dim CASCADE;

--inserting
INSERT INTO dw.shipping_dim 
SELECT 0+ROW_NUMBER() OVER() AS ship_id,
	   ship_mode
FROM (SELECT DISTINCT ship_mode FROM public.orders) a;

--checking
SELECT * FROM dw.shipping_dim;

-- ************************************** sales_fact

DROP TABLE IF EXISTS dw.sales_fact CASCADE;
CREATE TABLE dw.sales_fact
(
 row_id          serial NOT NULL,
 order_id        varchar(20) NOT NULL,
 order_date_id   integer NOT NULL,
 ship_date_id    integer NOT NULL,
 customer_number integer NOT NULL,
 geo_id          integer NOT NULL,
 ship_id         integer NOT NULL,
 product_number  integer NOT NULL,
 sales           numeric(9,4) NOT NULL,
 quantity        int NOT NULL,
 discount        numeric(4,2) NOT NULL,
 profit          numeric(9,4) NOT NULL,
 CONSTRAINT PK_sales_fact PRIMARY KEY ( row_id ),
 CONSTRAINT FK_70 FOREIGN KEY ( customer_number ) REFERENCES dw.customer ( customer_number ),
 CONSTRAINT FK_73 FOREIGN KEY ( geo_id ) REFERENCES dw.geography ( geo_id ),
 CONSTRAINT FK_76 FOREIGN KEY ( ship_id ) REFERENCES dw.shipping_dim ( ship_id ),
 CONSTRAINT FK_79 FOREIGN KEY ( product_number ) REFERENCES dw.product ( product_number )
 );


--deleting rows
TRUNCATE TABLE dw.sales_fact CASCADE;

--inserting
INSERT INTO dw.sales_fact 
SELECT 0+ROW_NUMBER() OVER() AS row_id,
	   order_id,
	   TO_CHAR(order_date,'yyyymmdd')::int AS  order_date_id,
	   TO_CHAR(ship_date,'yyyymmdd')::int AS  ship_date_id,
	   customer_number,
	   geo_id,
	   ship_id,
	   product_number,
	   sales,
	   quantity,
	   discount,
	   profit
FROM public.orders o INNER JOIN dw.customer c ON o.customer_id = c.customer_id AND
												 o.customer_name = c.customer_name AND
												 o.segment = c.segment 
				     INNER JOIN dw.geography g ON o.postal_code = g.postal_code AND
					 							  o.country=g.country AND 
					 							  o.city = g.city AND 
					 							  o.state = g.state
				     INNER JOIN dw.shipping_dim s ON o.ship_mode = s.ship_mode
				     INNER JOIN dw.product p ON o.product_id = p.product_id AND
											    o.product_name = p.product_name AND 
											    o.category = p.category AND 
											    o.subcategory = p.subcategory 
				   

				   --do you get 9994rows?
SELECT COUNT(*) FROM dw.sales_fact sf
INNER JOIN dw.shipping_dim s ON sf.ship_id=s.ship_id
INNER JOIN dw.geography g ON sf.geo_id=g.geo_id
INNER JOIN dw.product p ON sf.product_number =p.product_number
INNER JOIN dw.customer c ON sf.customer_number =c.customer_number 