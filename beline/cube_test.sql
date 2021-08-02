--- local server - paul_test  database

---- experiment with CUBEs

-- first make a big fact table with a handfull of dimentions and one measure
drop table locations;
drop table DimProducts;
drop table DimClients;
drop table FactSales;

CREATE TABLE Locations
 (LocationID int,
  LocationState varchar(20),
  LocationCity varchar(20));

INSERT INTO Locations (LocationID, LocationState, LocationCity) VALUES (1, 'Colorado', 'Denver');
INSERT INTO Locations (LocationID, LocationState, LocationCity) VALUES (2, 'Colorado', 'Boulder');
INSERT INTO Locations (LocationID, LocationState, LocationCity) VALUES (3, 'Colorado', 'Fort Collins');
INSERT INTO Locations (LocationID, LocationState, LocationCity) VALUES (4, 'Nevada', 'Las Vegas');
INSERT INTO Locations (LocationID, LocationState, LocationCity) VALUES (5, 'Nebraska', 'Lincoln');
INSERT INTO Locations (LocationID, LocationState, LocationCity) VALUES (6, 'Wyoming', 'Gillete');
INSERT INTO Locations (LocationID, LocationState, LocationCity) VALUES (7, 'Arizona', 'Mesa');
INSERT INTO Locations (LocationID, LocationState, LocationCity) VALUES (8, 'Arizona', 'Phoenix');

CREATE TABLE DimProducts
 (ProductID       int not null,
  ProductCategory varchar(20) not null,
  ProductName     varchar(20) not null)
;

Insert into DimProducts (ProductID, ProductCategory, ProductName) VALUES (1, 'Office', 'Printer paper');
Insert into DimProducts (ProductID, ProductCategory, ProductName) VALUES (2, 'Office', 'Printer ink');
Insert into DimProducts (ProductID, ProductCategory, ProductName) VALUES (3, 'Office', 'Stapler');
Insert into DimProducts (ProductID, ProductCategory, ProductName) VALUES (4, 'Office', 'Pencils');
Insert into DimProducts (ProductID, ProductCategory, ProductName) VALUES (5, 'Automobile', 'Wipers');
Insert into DimProducts (ProductID, ProductCategory, ProductName) VALUES (6, 'Automobile', 'Battery cable');
Insert into DimProducts (ProductID, ProductCategory, ProductName) VALUES (7, 'Automobile', 'Spark plugs');
Insert into DimProducts (ProductID, ProductCategory, ProductName) VALUES (8, 'Automobile', 'Gas cap');
Insert into DimProducts (ProductID, ProductCategory, ProductName) VALUES (9, 'Automobile', 'Tires');
Insert into DimProducts (ProductID, ProductCategory, ProductName) VALUES (10, 'Automobile', 'Brake pads');
Insert into DimProducts (ProductID, ProductCategory, ProductName) VALUES (11, 'Restaurant Supply', 'Fry pan 10"');
Insert into DimProducts (ProductID, ProductCategory, ProductName) VALUES (12, 'Restaurant Supply', 'Fry pan 12"');
Insert into DimProducts (ProductID, ProductCategory, ProductName) VALUES (13, 'Restaurant Supply', 'Wok 20"');
Insert into DimProducts (ProductID, ProductCategory, ProductName) VALUES (14, 'Restaurant Supply', 'Old Fashoned glass');
Insert into DimProducts (ProductID, ProductCategory, ProductName) VALUES (15, 'Restaurant Supply', 'Highball glass');
Insert into DimProducts (ProductID, ProductCategory, ProductName) VALUES (16, 'Restaurant Supply', 'Ice scoop');
Insert into DimProducts (ProductID, ProductCategory, ProductName) VALUES (17, 'Restaurant Supply', 'Bucket 5 gallon');

CREATE table DimClients
 (ClientID       int not null,
  ClientName     varchar(20) not null);

Insert into DimClients (ClientID, ClientName) VALUES (1, 'Apple');
Insert into DimClients (ClientID, ClientName) VALUES (2, 'Microsoft');
Insert into DimClients (ClientID, ClientName) VALUES (3, 'McDonalds');

--- one COULD (should?) separate the city and state into one dimension.  I'll leave them unlinked for now.
CREATE TABLE FactSales
  (salesPK       uniqueidentifier not null,
   clientID      int not null,
   saleDate      datetime  not null,
   saleCity      varchar(20) not null,
   saleState     varchar(20) not null,
   productID     int not null,
   paymentMethod varchar(20) not null,
   amount        money not null);


  with RowGenerator -- just over 1M rows (as of now - this will increase over time!)
    as (select ROW_NUMBER() over (order by a.name) as x
	     from sys.columns a 
              cross join sys.columns b)
INSERT INTO FactSales
select salesPK = NEWID(),
	   ClientID = CASE 
	                WHEN cast(crypt_gen_random(1) as INT) < 178 then 1
		            WHEN cast(crypt_gen_random(1) as INT) < 229 then 2
		            else 3
	              END,
       saleDate = DATEADD(day, cast(crypt_gen_random(2) as int) % 1100, '20170101'),
	   SaleCity = l.LocationCity,
	   SaleState = l.LocationState,
	   productID = 1 + (x % 17),
	   PaymentMethod = CASE 
	                     WHEN cast(crypt_gen_random(1) as INT) < 178 then 'credit card'
		                 WHEN cast(crypt_gen_random(1) as INT) < 229 then 'sales rep' 
		                 when cast(crypt_gen_random(1) as INT) < 240 then 'cash'
		                 else 'cheque' 
	                   end,
       Amount = CAST(10 + cast(crypt_gen_random(2) as INT) / 100.0 AS money)
  from RowGenerator r
	   inner join Locations l on l.LocationID = ( r.x % 8 ) + 1
  ;


-- We want a structure which has computed the measure - sum(amount) 
-- for any low-level grouping and combination of groupings we might be interested in.
-- We ALWAYS will query with a clientID = clause; so all groups must be within a clientID - never across.
-- So in this case, group by the following:
--   CLIENT ID
--     sale month (can be rolled up to quarter/year), 
--     state/city (can be rolled up to state)
--     product ID (can be rolled up to product category with a join)
--     payment method

SELECT ClientID,
       --Month(saleDate) as saleMonth,
       datename(month, DATEADD(month, Month(saleDate), -1)) as SaleMonth,
	   GROUPING(ProductID) as ProductGroup,
	   GROUPING(PaymentMethod) as PaymentMethodGroup,
--	   GROUPING_ID(ProductID) as ProductGroupID,  -- with one argument, GROUPING_ID is same as GROUPING
--	   GROUPING_ID(PaymentMethod) as PaymentMethodGroupID,
	   GROUPING_ID(ProductID, PaymentMethod) as GroupingVector,  -- with multiple args, this combines multiple GROUP flags into one column
	   -- GROUP and GROUP ID are all 0 for regular GROUP BY.  Only in grouping sets, rollups, or cubes are they non zero
       --SaleCity,
	   --SaleState,
	   productID,
	   PaymentMethod,
	   SUM(Amount) as SumAmount,
	   count(*) as [rowcount]
  FROM FactSales
 WHERE ProductID in (1, 5, 6) -- to reduce the number of products and make the resultset smaller and easier to understand
 GROUP BY ClientID, Month(saleDate), ProductID, PaymentMethod  --404 rows with standard group by
 --GROUP BY ClientID, Month(saleDate), 
   --       GROUPING SETS (  --285 with all three
	--	    (),    --removing results in 249
		--    (ProductID),
	--		(PaymentMethod)
      --    )
;

