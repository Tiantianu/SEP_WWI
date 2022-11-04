
--Q1
SELECT p.FullName,p.FaxNumber,p.PhoneNumber, c.PhoneNumber AS CompanyPhone, c.FaxNumber AS CompanyFax
FROM [WideWorldImporters].[Application].[People] p
LEFT JOIN [WideWorldImporters].[Sales].[Customers] c ON p.PersonID=c.PrimaryContactPersonID OR p.PersonID=c.AlternateContactPersonID;

--Q2
SELECT CustomerName AS Company
FROM [WideWorldImporters].[Sales].[Customers] c
WHERE PrimaryContactPersonID IN
	(SELECT C.PrimaryContactPersonID FROM [WideWorldImporters].[Sales].[Customers] C
	JOIN  [WideWorldImporters].[Application].[People] P ON  P.PersonID=C.PrimaryContactPersonID
	WHERE C.PhoneNumber=P.PhoneNumber);

--Q3
SELECT DISTINCT CustomerID FROM [WideWorldImporters].[Sales].[Orders]
GROUP BY  CustomerID,OrderDate
HAVING MAX(OrderDate) < '2016-01-01'
order by CustomerID;


--Q4
SELECT StockItemID, SUM(OrderedOuters) AS total_q
FROM  [WideWorldImporters].[Purchasing].[PurchaseOrderLines] pol

WHERE LastReceiptDate BETWEEN '2013-01-01' AND '2013-12-31'
GROUP BY StockItemID
ORDER BY StockItemID;

--Q5
SELECT StockItemID FROM [WideWorldImporters].[Purchasing].[PurchaseOrderLines]
WHERE LEN(Description) >= 10
GROUP BY StockItemID
ORDER BY StockItemID ;

--Q6
SELECT DISTINCT StockItemID FROM 
 [WideWorldImporters].[Sales].[OrderLines] ol
join [WideWorldImporters].[Sales].[Orders] o on ol.OrderID=o.OrderID
JOIN [WideWorldImporters].[Sales].[Customers] C ON o.CustomerID=C.CustomerID
JOIN [WideWorldImporters].[Application].[Cities] CI ON C.DeliveryCityID=CI.CityID
JOIN [WideWorldImporters].[Application].[StateProvinces] SP ON SP.StateProvinceID=CI.StateProvinceID
WHERE SP.StateProvinceName != 'Alabama' AND SP.StateProvinceName!='Georgia'
AND year(OrderDate)=2014
ORDER BY StockItemID;

-- Q7
SELECT StateProvinceCode,AVG(DATEDIFF(day,OrderDate,ConfirmedDeliveryTime)) AS avg_days
FROM [WideWorldImporters].[Sales].[Invoices] I
JOIN [WideWorldImporters].[Sales].[Orders] O ON I.OrderID =O.OrderID
JOIN [WideWorldImporters].[Sales].[Customers] C ON O.CustomerID=C.CustomerID
JOIN [WideWorldImporters].[Application].[Cities] CI ON C.DeliveryCityID=CI.CityID
JOIN [WideWorldImporters].[Application].[StateProvinces] SP ON SP.StateProvinceID=CI.StateProvinceID
GROUP BY StateProvinceCode;

--Q8
SELECT *
FROM
(SELECT MONTH(ConfirmedDeliveryTime) AS avg_month,StateProvinceCode,DATEDIFF(day,OrderDate,ConfirmedDeliveryTime) AS avg_days
FROM [WideWorldImporters].[Sales].[Invoices] I
JOIN [WideWorldImporters].[Sales].[Orders] O ON I.OrderID =O.OrderID
JOIN [WideWorldImporters].[Sales].[Customers] C ON O.CustomerID=C.CustomerID
JOIN [WideWorldImporters].[Application].[Cities] CI ON C.DeliveryCityID=CI.CityID
JOIN [WideWorldImporters].[Application].[StateProvinces] SP ON SP.StateProvinceID=CI.StateProvinceID) p
PIVOT 
( AVG(avg_days) FOR avg_month IN
([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12]))
AS pvt
;


--Q9 
SELECT StockItemID
FROM [WideWorldImporters].[Warehouse].[StockItemTransactions]
WHERE YEAR(TransactionOccurredWhen)=2015
GROUP BY StockItemID
HAVING SUM(Quantity)>0
ORDER BY StockItemID;


--Q10
SELECT C.CustomerID, P.PhoneNumber, FullName
FROM [WideWorldImporters].[Application].[People] p
LEFT JOIN [WideWorldImporters].[Sales].[Customers] c ON p.PersonID=c.PrimaryContactPersonID
LEFT JOIN [WideWorldImporters].[Sales].[Invoices] I ON c.CustomerID=i.CustomerID
LEFT JOIN [WideWorldImporters].[Warehouse].[StockItemTransactions] ST ON ST.InvoiceID=I.InvoiceID
JOIN [WideWorldImporters].[Warehouse].[StockItems] S ON ST.StockItemID=S.StockItemID
WHERE YEAR(TransactionOccurredWhen)=2016
AND S.StockItemName LIKE '%mug%' 
AND PrimaryContactPersonID=PersonID
GROUP BY C.CustomerID, P.PhoneNumber,FullName
Having ABS(SUM(quantity))<=10;


--Q11
SELECT CityName
FROM [WideWorldImporters].[Application].[Cities]
WHERE ValidFrom >'2015-01-01 00:00:00.0000000';


--Q12
SELECT s.StockItemName,c.DeliveryAddressLine2, c.DeliveryAddressLine1,  SP.StateProvinceName, 
CI.CityName, CountryName,C.CustomerName,p.FullName,c.PhoneNumber, floor(ST.Quantity) AS Quantity
FROM [WideWorldImporters].[Sales].[Orders] O
JOIN [WideWorldImporters].[Sales].[Invoices] I ON O.OrderID=I.OrderID
JOIN [WideWorldImporters].[Sales].[Customers] c on c.CustomerID=i.CustomerID
JOIN [WideWorldImporters].[Application].[People] p ON p.PersonID=c.PrimaryContactPersonID
JOIN [WideWorldImporters].[Warehouse].[StockItemTransactions] ST ON ST.InvoiceID=I.InvoiceID
JOIN [WideWorldImporters].[Warehouse].[StockItems] S ON ST.StockItemID=S.StockItemID
JOIN [WideWorldImporters].[Application].[Cities] CI ON C.DeliveryCityID=CI.CityID
JOIN [WideWorldImporters].[Application].[StateProvinces] SP ON SP.StateProvinceID=CI.StateProvinceID
JOIN [WideWorldImporters].[Application].[Countries] CT ON SP.CountryID=CT.CountryID
WHERE O.OrderDate = '2014-07-01';


--Q13 
WITH CTE AS(
SELECT sg.StockGroupID,sg.StockItemID,
SUM(CASE WHEN Quantity<0 THEN Quantity else 0 END) AS Sold,
SUM(CASE WHEN Quantity>0 THEN Quantity else 0 END) AS Pruchased,
sum(LastStocktakeQuantity) as quantity
FROM [WideWorldImporters].[Warehouse].[StockItemTransactions] st
JOIN [WideWorldImporters].[Warehouse].[StockItemStockGroups] sg on ST.StockItemID=SG.StockItemID
JOIN [WideWorldImporters].[Warehouse].[StockItemHoldings] SH ON SH.StockItemID=ST.StockItemID
WHERE TransactionOccurredWhen<SH.LastEditedWhen
GROUP BY sg.StockGroupID,SG.StockItemID
)

SELECT StockGroupID, sum(sold) as totals, sum(pruchased) as totalp, SUM(sold+pruchased+quantity) as rem
FROM CTE
GROUP BY StockGroupID
ORDER BY StockGroupID




--Q14 
WITH CTE_1 AS (
SELECT S.StockItemName,C.DeliveryCityID,OL.Quantity
FROM
[WideWorldImporters].[Sales].[Orders] O
JOIN [WideWorldImporters].[Sales].[OrderLines] ol ON o.OrderID = ol.OrderID
JOIN [WideWorldImporters].[Sales].[Customers] c on c.CustomerID=O.CustomerID
JOIN [WideWorldImporters].[Warehouse].[StockItems] S ON OL.StockItemID=S.StockItemID
WHERE
YEAR(ExpectedDeliveryDate)=2016
),
CTE_2 AS (
SELECT CI.CityName,CTE_1.StockItemName,SUM(CTE_1.Quantity) AS CNT
FROM [WideWorldImporters].[Application].[Cities] CI
JOIN CTE_1 ON CI.CityID = CTE_1.DeliveryCityID
GROUP BY CI.CityName,CTE_1.StockItemName
),
RNK AS (
SELECT *, ROW_NUMBER()OVER(PARTITION BY CityName ORDER BY CNT DESC) AS RNK
FROM CTE_2
)
SELECT CityName,
	ISNULL(StockItemName, 'No Sales') AS MaxItems
FROM RNK
WHERE rnk = 1

--Q15 
SELECT OrderID, JSON_VALUE(ReturnedDeliveryData,'$.Events[1].Comment') AS comments
FROM [WideWorldImporters].[Sales].[Invoices]
WHERE JSON_VALUE(ReturnedDeliveryData,'$.Events[1].Comment') IS NOT NULL;


--Q16
SELECT StockItemID,StockItemName
FROM [WideWorldImporters].[Warehouse].[StockItems]
WHERE CustomFields LIKE '%China%'

--Q17
WITH CTE AS(
SELECT 
StockItemID,
(CASE WHEN CustomFields LIKE '%China%' THEN 'China'
		WHEN CustomFields LIKE '%Japan%' THEN 'Japan'
		ELSE 'USA' END) AS Country
FROM [WideWorldImporters].[Warehouse].[StockItems])

SELECT Country, FLOOR(ABS(SUM(quantity))) AS Con_total
FROM [WideWorldImporters].[Sales].[Orders] O
JOIN [WideWorldImporters].[Sales].[Invoices] I ON O.OrderID=I.OrderID
JOIN [WideWorldImporters].[Warehouse].[StockItemTransactions] ST ON ST.InvoiceID=I.InvoiceID
JOIN CTE ON CTE.StockItemID= st.StockItemID
where year(o.OrderDate)=2015
GROUP BY Country;

--Q18
--CREATE VIEW vTOTALQ18
--AS
select *
from 
(SELECT SG.StockGroupName,year(ST.TransactionOccurredWhen) as year,quantity
FROM [WideWorldImporters].[Warehouse].[StockItemTransactions] ST 
JOIN [WideWorldImporters].[Warehouse].[StockItemStockGroups] SSG ON SSG.StockItemID=ST.StockItemID
JOIN [WideWorldImporters].[Warehouse].[StockGroups] SG ON SSG.StockGroupID=SG.StockGroupID
WHERE year(ST.TransactionOccurredWhen) BETWEEN 2013 AND 2017
) as cc
PIVOT( sum(quantity) FOR year IN ([2013],[2014],[2015],[2016],[2017])) as  pvt;
--GO;


--Q19 
CREATE VIEW vTOTALQ19
AS
select *
from 
(SELECT SG.StockGroupName as  StockGroupName,year(ST.TransactionOccurredWhen) as year,quantity
FROM [WideWorldImporters].[Warehouse].[StockItemTransactions] ST 
JOIN [WideWorldImporters].[Warehouse].[StockItemStockGroups] SSG ON SSG.StockItemID=ST.StockItemID
JOIN [WideWorldImporters].[Warehouse].[StockGroups] SG ON SSG.StockGroupID=SG.StockGroupID
WHERE year(ST.TransactionOccurredWhen) BETWEEN 2013 AND 2017
) as cc
PIVOT( sum(quantity) FOR StockGroupName IN ([Novelty Items],
[Clothing],
[Mugs],
[T-Shirts],
[Airline Novelties],
[Computing Novelties],
[USB Novelties],
[Furry Footwear],
[Toys],
[Packaging Materials])) as  pvt;

SELECT * FROM vTOTALQ19


--Q20
DROP FUNCTION IF EXISTS DBO.udf;

CREATE FUNCTION DBO.udf(@OrderID int)
RETURNS int AS BEGIN

RETURN
(SELECT SUM(IL.ExtendedPrice)
FROM [WideWorldImporters].[Sales].[InvoiceLines] IL
JOIN [WideWorldImporters].[Sales].[Invoices] I  ON IL.InvoiceID=I.InvoiceID
AND I.OrderID=@OrderID
)
END;

SELECT InvoiceID, OrderID, DBO.udf(OrderID) AS OrderTotal
FROM [WideWorldImporters].[Sales].[Invoices];

--Q21 
IF OBJECT_ID('sp_gettotal', 'P') IS NOT NULL  
    DROP PROCEDURE sp_gettotal;  
 DROP TABLE Orders
 
 CREATE TABLE Orders
 ( orderid INT  NOT NULL,
 orderdate date  NOT NULL,
 ordertotal FLOAT, 
 customerid INT  NOT NULL,
 PRIMARY KEY(orderid,orderdate,customerid)
);

CREATE PROCEDURE sp_gettotal  @OrderDate DATE
AS
BEGIN TRANSACTION
IF  EXISTS(SELECT Orderid FROM Orders WHERE orderdate=@OrderDate)
  BEGIN
   PRINT('ERROR REPEAT DATE')
   ROLLBACK TRAN
   RETURN
  END

INSERT INTO Orders(orderid,orderdate,customerid,ordertotal)
SELECT O.OrderID,O.OrderDate,o.CustomerID,SUM(ExtendedPrice) AS Total
FROM [WideWorldImporters].[Sales].[Orders] o
JOIN [WideWorldImporters].[Sales].[Invoices] i ON i.orderid=o.orderid
JOIN [WideWorldImporters].[Sales].[InvoiceLines] IL ON IL.InvoiceID=I.InvoiceID 
WHERE O.OrderDate = @OrderDate
GROUP BY O.OrderID,O.OrderDate,o.CustomerID

COMMIT TRANSACTION
GO

SELECT * FROM [WideWorldImporters].[Sales].[Invoices]
-- EXECUTE
EXECUTE sp_gettotal '2013-01-01' ;
EXECUTE sp_gettotal '2013-01-02' ;
EXECUTE sp_gettotal '2013-01-03' ;
EXECUTE sp_gettotal '2013-01-04' ;
EXECUTE sp_gettotal '2013-01-05' ;

SELECT * FROM Orders;

DELETE FROM Orders;

--Q22 
SELECT
	[StockItemID], 
	[StockItemName],
	[SupplierID],
	[ColorID],
	[UnitPackageID],
	[OuterPackageID],
	[Brand],
	[Size],
	[LeadTimeDays],
	[QuantityPerOuter],
	[IsChillerStock],
	[Barcode],
	[TaxRate],
	[UnitPrice],
	[RecommendedRetailPrice],
	[TypicalWeightPerUnit],
	[MarketingComments],
	[InternalComments],
	JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture,
	JSON_VALUE(CustomFields,'$.Range') AS Range, 
	JSON_VALUE(CustomFields,'$.ShelfLife') AS ShelfLife
INTO  ODS.StockItem
FROM [WideWorldImporters].[Warehouse].[StockItems];

SELECT * FROM ODS.StockItem;


--Q23
DROP TABLE IF EXISTS ods.Orders;

CREATE TABLE ods.Orders(
	OrderID INT NOT NULL,
	OrderDate DATE NOT NULL,
	OrderTotal INT NOT NULL,
	CustomerID INT NOT NULL);

DROP PROCEDURE IF EXISTS dbo.GetOrderInfo; 

CREATE PROCEDURE dbo.GetOrderInfo
	@OrderDate date
AS
	BEGIN TRY
		BEGIN TRANSACTION 
		IF EXISTS (SELECT * FROM ods.Orders WHERE OrderDate = @OrderDate)





--Q24
DECLARE @json NVARCHAR(MAX) = N'
{
   "PurchaseOrders":[
      {
         "StockItemName":"Panzer Video Game",
         "Supplier":"7",
         "UnitPackageId":"1",
         "OuterPackageId":[
            6,
            7
         ],
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
		 "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-01",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"WWI2308"
      },
      {
         "StockItemName":"Panzer Video Game",
         "Supplier":"5",
         "UnitPackageId":"1",
         "OuterPackageId":"7",
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-025",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"269622390"
      }
   ]
}'

INSERT INTO [WideWorldImporters].[Warehouse].[StockItems]
SELECT * 
FROM OPENJSON(@json)
WITH  (
        StockItemName  varchar(600)   '$[0].StockItemName',  
        SupplierID   INT     '$[0].Supplier', 
        UnitPackageId      INT      '$[0].UnitPackageId', 
        OuterPackageId      INT   '$[0].OuterPackageId'
    );


--Q25
SELECT * FROM vTOTALQ19
FOR JSON AUTO

--Q26
SELECT * FROM vTOTALQ19
FOR XML AUTO,ELEMENTS

--Q27
DROP TABLE IF EXISTS ods.ConfirmedDeviveryJson;

CREATE TABLE ConfirmedDeviveryJson(
	id INT IDENTITY,
	date DATE,
	value nvarchar(MAX)
);

CREATE PROCEDURE sp_totali
	@OrderDate date
AS
	DECLARE @json nvarchar(MAX);
	SET @json = (
	SELECT 
       i.InvoiceID
      ,i.CustomerID
      ,i.BillToCustomerID
      ,i.OrderID
      ,i.DeliveryMethodID
      ,i.ContactPersonID
      ,i.AccountsPersonID
      ,i.SalespersonPersonID
      ,i.PackedByPersonID
      ,i.InvoiceDate
      ,i.CustomerPurchaseOrderNumber
      ,i.IsCreditNote
      ,i.CreditNoteReason
      ,i.Comments
      ,i.DeliveryInstructions
      ,i.InternalComments
      ,i.TotalDryItems
      ,i.TotalChillerItems
      ,i.DeliveryRun
      ,i.RunPosition
      ,i.ReturnedDeliveryData
      ,i.ConfirmedDeliveryTime
      ,i.ConfirmedReceivedBy
      ,i.LastEditedBy
      ,i.LastEditedWhen
	  ,il.InvoiceLineID
      ,il.StockItemID
      ,il.Description
      ,il.PackageTypeID
      ,il.Quantity
      ,il.UnitPrice
      ,il.TaxRate
      ,il.TaxAmount
      ,il.LineProfit
      ,il.ExtendedPrice
      ,il.LastEditedBy as LEB
      ,il.LastEditedWhen AS LBW
FROM [WideWorldImporters].[Sales].[Invoices] AS i
JOIN [WideWorldImporters].[Sales].[InvoiceLines] AS il
ON i.InvoiceID = il.InvoiceID AND i.InvoiceDate = @OrderDate
FOR JSON PATH)

INSERT INTO ConfirmedDeviveryJson(date,value) VALUES(@OrderDate,@json)
GO

EXEC sp_totali;

SELECT * FROM ConfirmedDeviveryJson;