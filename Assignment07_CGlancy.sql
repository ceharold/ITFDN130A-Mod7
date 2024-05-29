--*************************************************************************--
-- Title: Assignment07
-- Author: ChristieGlancy
-- Desc: This file demonstrates how to use Functions
-- Change Log: When,Who,What
-- 2017-01-01,ChristieGlancy,Created File
--**************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'Assignment07DB_ChristieGlancy')
	 Begin 
	  Alter Database [Assignment07DB_ChristieGlancy] set Single_user With Rollback Immediate;
	  Drop Database Assignment07DB_ChristieGlancy;
	 End
	Create Database Assignment07DB_ChristieGlancy;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use Assignment07DB_ChristieGlancy;

-- Create Tables (Module 01)-- 
Create Table Categories
([CategoryID] [int] IDENTITY(1,1) NOT NULL 
,[CategoryName] [nvarchar](100) NOT NULL
);
go

Create Table Products
([ProductID] [int] IDENTITY(1,1) NOT NULL 
,[ProductName] [nvarchar](100) NOT NULL 
,[CategoryID] [int] NULL  
,[UnitPrice] [money] NOT NULL
);
go

Create Table Employees -- New Table
([EmployeeID] [int] IDENTITY(1,1) NOT NULL 
,[EmployeeFirstName] [nvarchar](100) NOT NULL
,[EmployeeLastName] [nvarchar](100) NOT NULL 
,[ManagerID] [int] NULL  
);
go

Create Table Inventories
([InventoryID] [int] IDENTITY(1,1) NOT NULL
,[InventoryDate] [Date] NOT NULL
,[EmployeeID] [int] NOT NULL
,[ProductID] [int] NOT NULL
,[ReorderLevel] int NOT NULL -- New Column 
,[Count] [int] NOT NULL
);
go

-- Add Constraints (Module 02) -- 
Begin  -- Categories
	Alter Table Categories 
	 Add Constraint pkCategories 
	  Primary Key (CategoryId);

	Alter Table Categories 
	 Add Constraint ukCategories 
	  Unique (CategoryName);
End
go 

Begin -- Products
	Alter Table Products 
	 Add Constraint pkProducts 
	  Primary Key (ProductId);

	Alter Table Products 
	 Add Constraint ukProducts 
	  Unique (ProductName);

	Alter Table Products 
	 Add Constraint fkProductsToCategories 
	  Foreign Key (CategoryId) References Categories(CategoryId);

	Alter Table Products 
	 Add Constraint ckProductUnitPriceZeroOrHigher 
	  Check (UnitPrice >= 0);
End
go

Begin -- Employees
	Alter Table Employees
	 Add Constraint pkEmployees 
	  Primary Key (EmployeeId);

	Alter Table Employees 
	 Add Constraint fkEmployeesToEmployeesManager 
	  Foreign Key (ManagerId) References Employees(EmployeeId);
End
go

Begin -- Inventories
	Alter Table Inventories 
	 Add Constraint pkInventories 
	  Primary Key (InventoryId);

	Alter Table Inventories
	 Add Constraint dfInventoryDate
	  Default GetDate() For InventoryDate;

	Alter Table Inventories
	 Add Constraint fkInventoriesToProducts
	  Foreign Key (ProductId) References Products(ProductId);

	Alter Table Inventories 
	 Add Constraint ckInventoryCountZeroOrHigher 
	  Check ([Count] >= 0);

	Alter Table Inventories
	 Add Constraint fkInventoriesToEmployees
	  Foreign Key (EmployeeId) References Employees(EmployeeId);
End 
go

-- Adding Data (Module 04) -- 
Insert Into Categories 
(CategoryName)
Select CategoryName 
 From Northwind.dbo.Categories
 Order By CategoryID;
go

Insert Into Products
(ProductName, CategoryID, UnitPrice)
Select ProductName,CategoryID, UnitPrice 
 From Northwind.dbo.Products
  Order By ProductID;
go

Insert Into Employees
(EmployeeFirstName, EmployeeLastName, ManagerID)
Select E.FirstName, E.LastName, IsNull(E.ReportsTo, E.EmployeeID) 
 From Northwind.dbo.Employees as E
  Order By E.EmployeeID;
go

Insert Into Inventories
(InventoryDate, EmployeeID, ProductID, [Count], [ReorderLevel]) -- New column added this week
Select '20170101' as InventoryDate, 5 as EmployeeID, ProductID, UnitsInStock, ReorderLevel
From Northwind.dbo.Products
UNIOn
Select '20170201' as InventoryDate, 7 as EmployeeID, ProductID, UnitsInStock + 10, ReorderLevel -- Using this is to create a made up value
From Northwind.dbo.Products
UNIOn
Select '20170301' as InventoryDate, 9 as EmployeeID, ProductID, abs(UnitsInStock - 10), ReorderLevel -- Using this is to create a made up value
From Northwind.dbo.Products
Order By 1, 2
go


-- Adding Views (Module 06) -- 
Create View vCategories With SchemaBinding
 AS
  Select CategoryID, CategoryName From dbo.Categories;
go
Create View vProducts With SchemaBinding
 AS
  Select ProductID, ProductName, CategoryID, UnitPrice From dbo.Products;
go
Create View vEmployees With SchemaBinding
 AS
  Select EmployeeID, EmployeeFirstName, EmployeeLastName, ManagerID From dbo.Employees;
go
Create View vInventories With SchemaBinding 
 AS
  Select InventoryID, InventoryDate, EmployeeID, ProductID, ReorderLevel, [Count] From dbo.Inventories;
go

-- Show the Current data in the Categories, Products, and Inventories Tables
Select * From vCategories;
go
Select * From vProducts;
go
Select * From vEmployees;
go
Select * From vInventories;
go

/********************************* Questions and Answers *********************************/
Print
'NOTES------------------------------------------------------------------------------------ 
 1) You must use the BASIC views for each table.
 2) Remember that Inventory Counts are Randomly Generated. So, your counts may not match mine
 3) To make sure the Dates are sorted correctly, you can use Functions in the Order By clause!
------------------------------------------------------------------------------------------'
-- Question 1 (5% of pts):
-- Show a list of Product names and the price of each product.
-- Use a function to format the price as US dollars.
-- Order the result by the product name.

-- <Put Your Code Here> --
-- SELECT 
-- ProductName
-- ,UnitPrice
-- FROM dbo.vProducts
-- ORDER BY ProductName ASC
-- ;

CREATE FUNCTION dbo.fProducts()
RETURNS TABLE
AS
 Return(
    SELECT TOP 1000000000
    ProductName
    ,FORMAT (UnitPrice, 'c', 'en-US') AS UnitPrice
    FROM dbo.vProducts
    ORDER BY ProductName ASC
 );
go

SELECT * FROM dbo.fProducts();
go

-- Question 2 (10% of pts): 
-- Show a list of Category and Product names, and the price of each product.
-- Use a function to format the price as US dollars.
-- Order the result by the Category and Product.
-- <Put Your Code Here> --
-- SELECT
-- c.CategoryName
-- ,p.ProductName
-- ,p.UnitPrice
-- FROM dbo.vCategories AS c
-- JOIN dbo.vProducts AS p
-- ON c.CategoryID = p.CategoryID
-- ORDER BY c.CategoryName, p.ProductName ASC
-- ;

CREATE FUNCTION dbo.fProductCategory ()
RETURNS TABLE
AS
 RETURN (
    SELECT TOP 1000000000
    c.CategoryName
    ,p.ProductName
    ,FORMAT (UnitPrice, 'c', 'en-US') AS UnitPrice
    FROM dbo.vCategories AS c
    JOIN dbo.vProducts AS p
    ON c.CategoryID = p.CategoryID
    ORDER BY c.CategoryName, p.ProductName ASC
 );
 go

 SELECT * FROM dbo.fProductCategory();
 go

-- Question 3 (10% of pts): 
-- Use functions to show a list of Product names, each Inventory Date, and the Inventory Count.
-- Format the date like 'January, 2017'.
-- Order the results by the Product and Date.

-- <Put Your Code Here> --
-- SELECT
-- p.ProductName
-- ,i.InventoryDate
-- ,i.Count AS InventoryCount
-- FROM dbo.vProducts AS p
-- JOIN dbo.vInventories AS i
-- ON p.ProductID = i.ProductID
-- ORDER BY p.ProductName, i.InventoryDate ASC
-- ;
-- go

-- SELECT
-- p.ProductName
-- ,DATENAME(MM, i.InventoryDate) + ',' + DATENAME(YY, i.InventoryDate) AS InventoryDate
-- ,i.Count AS InventoryCount
-- FROM dbo.vProducts AS p
-- JOIN dbo.vInventories AS i
-- ON p.ProductID = i.ProductID
-- ORDER BY p.ProductName, i.InventoryDate ASC
-- ;
-- go

CREATE FUNCTION dbo.fProductDate ()
RETURNS TABLE
AS
 RETURN (SELECT TOP 1000000000
    p.ProductName
    ,DATENAME(MM, i.InventoryDate) + ',' + DATENAME(YY, i.InventoryDate) AS InventoryDate
    ,i.Count AS InventoryCount
    FROM dbo.vProducts AS p
    JOIN dbo.vInventories AS i
    ON p.ProductID = i.ProductID
    ORDER BY p.ProductName, i.InventoryDate ASC)
;
go

SELECT * FROM dbo.fProductDate();

-- Question 4 (10% of pts): 
-- CREATE A VIEW called vProductInventories. 
-- Shows a list of Product names, each Inventory Date, and the Inventory Count. 
-- Format the date like 'January, 2017'.
-- Order the results by the Product and Date.
-- <Put Your Code Here> --

-- SELECT TOP 1000000000
-- p.ProductName
-- ,DATENAME(MM, i.InventoryDate) + ',' + DATENAME(YY, i.InventoryDate) AS InventoryDate
-- ,i.Count AS InventoryCount
-- FROM dbo.vProducts AS p
-- JOIN dbo.vInventories AS i
-- ON p.ProductID = i.ProductID
-- ORDER BY p.ProductName, i.InventoryDate ASC
-- ;

CREATE VIEW vProductInventories
AS
 SELECT TOP 1000000000
    p.ProductName
    ,DATENAME(MM, i.InventoryDate) + ',' + DATENAME(YY, i.InventoryDate) AS InventoryDate
    ,i.Count AS InventoryCount
    FROM dbo.vProducts AS p
    JOIN dbo.vInventories AS i
    ON p.ProductID = i.ProductID
    ORDER BY p.ProductName, i.InventoryDate ASC
;
go

-- Check that it works: Select * From vProductInventories;

SELECT * FROM vProductInventories;
go



-- Question 5 (10% of pts): 
-- CREATE A VIEW called vCategoryInventories. 
-- Shows a list of Category names, Inventory Dates, and a TOTAL Inventory Count BY CATEGORY
-- Format the date like 'January, 2017'.
-- Order the results by the Product and Date.

-- <Put Your Code Here> --
-- SELECT
-- c.CategoryName
-- ,DATENAME(MM, i.InventoryDate) + ',' + DATENAME(YY, i.InventoryDate) AS InventoryDate
-- ,i.Count AS InventoryCount
-- FROM dbo.vCategories AS c
-- JOIN dbo.vProducts AS p
-- ON c.CategoryID = p.CategoryID
-- JOIN dbo.vInventories AS i
-- ON p.ProductID = i.ProductID
-- ORDER BY c.CategoryName, InventoryDate ASC
-- ;
-- go

-- SELECT
-- c.CategoryName
-- ,DATENAME(MM, i.InventoryDate) + ',' + DATENAME(YY, i.InventoryDate) AS InventoryDate
-- ,SUM(i.Count) AS InventoryCountByCategory
-- FROM dbo.vCategories AS c
-- JOIN dbo.vProducts AS p
-- ON c.CategoryID = p.CategoryID
-- JOIN dbo.vInventories AS i
-- ON p.ProductID = i.ProductID
-- GROUP BY InventoryDate, c.CategoryName
-- ORDER BY c.CategoryName, InventoryDate ASC
-- ;
-- go

-- SELECT
-- c.CategoryName
-- ,DATENAME(MM, i.InventoryDate) + ',' + DATENAME(YY, i.InventoryDate) AS InventoryDate
-- ,SUM(i.Count) AS InventoryCountByCategory
-- FROM dbo.vCategories AS c
-- JOIN dbo.vProducts AS p
-- ON c.CategoryID = p.CategoryID
-- JOIN dbo.vInventories AS i
-- ON p.ProductID = i.ProductID
-- GROUP BY InventoryDate, c.CategoryName
-- ORDER BY c.CategoryName, cast(InventoryDate AS date) ASC
-- ;
-- go

CREATE VIEW vCategoryInventories
AS
 SELECT TOP 1000000000
    c.CategoryName
    ,DATENAME(MM, i.InventoryDate) + ',' + DATENAME(YY, i.InventoryDate) AS InventoryDate
    ,SUM(i.Count) AS InventoryCountByCategory
    FROM dbo.vCategories AS c
    JOIN dbo.vProducts AS p
    ON c.CategoryID = p.CategoryID
    JOIN dbo.vInventories AS i
    ON p.ProductID = i.ProductID
    GROUP BY InventoryDate, c.CategoryName
    ORDER BY c.CategoryName, CAST(InventoryDate AS date) ASC
;
go

-- Check that it works: Select * From vCategoryInventories;
SELECT * FROM vCategoryInventories;
go

-- Question 6 (10% of pts): 
-- CREATE ANOTHER VIEW called vProductInventoriesWithPreviouMonthCounts. 
-- Show a list of Product names, Inventory Dates, Inventory Count, AND the Previous Month Count.
-- Use functions to set any January NULL counts to zero. 
-- Order the results by the Product and Date. 
-- This new view must use your vProductInventories view.

-- <Put Your Code Here> --
-- SELECT
-- ProductName
-- ,InventoryDate
-- ,InventoryCount
-- ,ISNULL(LAG(InventoryCount,1) OVER (ORDER BY CONVERT (datetime, InventoryDate)), 0) AS PreviousMonthCount --previous totals wrong
-- FROM vProductInventories
-- GROUP BY ProductName, InventoryDate, InventoryCount
-- ORDER BY ProductName, cast(InventoryDate AS date) ASC
-- ;

-- SELECT
-- ProductName
-- ,InventoryDate
-- ,InventoryCount
-- ,ISNULL(LAG(InventoryCount,1) OVER (PARTITION BY ProductName ORDER BY CONVERT (datetime, InventoryDate)), 0) AS PreviousMonthCount
-- FROM vProductInventories
-- GROUP BY ProductName, InventoryDate, InventoryCount
-- ORDER BY ProductName, cast(InventoryDate AS date) ASC
-- ;
-- go

-- SELECT
-- ProductName
-- ,InventoryDate
-- ,InventoryCount
-- ,PreviousMonthCount = IIF(InventoryDate LIKE ('January%'),0,LAG(InventoryCount,1) OVER (ORDER BY ProductName, CONVERT (datetime, InventoryDate)))
-- FROM vProductInventories
-- GROUP BY ProductName, InventoryDate, InventoryCount
-- ORDER BY ProductName, cast(InventoryDate AS date) ASC
-- ;

CREATE VIEW vProductInventoriesWithPreviousMonthCounts
AS
 SELECT TOP 1000000000
 ProductName
 ,InventoryDate
 ,InventoryCount
 ,PreviousMonthCount = IIF(InventoryDate LIKE ('January%'),0,LAG(InventoryCount,1) OVER (ORDER BY ProductName, CONVERT (datetime, InventoryDate)))
 FROM vProductInventories
 GROUP BY ProductName, InventoryDate, InventoryCount
 ORDER BY ProductName, CAST(InventoryDate AS date) ASC
;
go

-- Check that it works: Select * From vProductInventoriesWithPreviousMonthCounts;

SELECT * FROM vProductInventoriesWithPreviousMonthCounts;
go

-- Question 7 (15% of pts): 
-- CREATE a VIEW called vProductInventoriesWithPreviousMonthCountsWithKPIs.
-- Show columns for the Product names, Inventory Dates, Inventory Count, Previous Month Count. 
-- The Previous Month Count is a KPI. The result can show only KPIs with a value of either 1, 0, or -1. 
-- Display months with increased counts as 1, same counts as 0, and decreased counts as -1. 
-- Varify that the results are ordered by the Product and Date.

-- <Put Your Code Here> --
-- SELECT
--  ProductName
--  ,InventoryDate
--  ,InventoryCount
--  ,PreviousMonthCount
--  ,CASE
--     WHEN InventoryCount > PreviousMonthCount Then 1
--     WHEN InventoryCount = PreviousMonthCount Then 0
--     WHEN InventoryCount < PreviousMonthCount Then -1
--     END AS CountVsPreviousCountKPI
--  FROM vProductInventoriesWithPreviousMonthCounts
--  GROUP BY ProductName, InventoryDate, InventoryCount, PreviousMonthCount
--  ORDER BY ProductName, cast(InventoryDate AS date) ASC
-- ;
-- go

CREATE VIEW vProductInventoriesWithPreviousMonthCountsWithKPIs
AS
SELECT TOP 1000000000
 ProductName
 ,InventoryDate
 ,InventoryCount
 ,PreviousMonthCount
 ,CASE
    WHEN InventoryCount > PreviousMonthCount Then 1
    WHEN InventoryCount = PreviousMonthCount Then 0
    WHEN InventoryCount < PreviousMonthCount Then -1
    END AS CountVsPreviousCountKPI
 FROM vProductInventoriesWithPreviousMonthCounts
 GROUP BY ProductName, InventoryDate, InventoryCount, PreviousMonthCount
 ORDER BY ProductName, CAST(InventoryDate AS date) ASC
;
go

-- Important: This new view must use your vProductInventoriesWithPreviousMonthCounts view!
-- Check that it works: Select * From vProductInventoriesWithPreviousMonthCountsWithKPIs;

SELECT * FROM vProductInventoriesWithPreviousMonthCountsWithKPIs;
go

-- Question 8 (25% of pts): 
-- CREATE a User Defined Function (UDF) called fProductInventoriesWithPreviousMonthCountsWithKPIs.
-- Show columns for the Product names, Inventory Dates, Inventory Count, the Previous Month Count. 
-- The Previous Month Count is a KPI. The result can show only KPIs with a value of either 1, 0, or -1. 
-- Display months with increased counts as 1, same counts as 0, and decreased counts as -1. 
-- The function must use the ProductInventoriesWithPreviousMonthCountsWithKPIs view.
-- Varify that the results are ordered by the Product and Date.

-- <Put Your Code Here> --
CREATE FUNCTION fProductInventoriesWithPreviousMonthCountsWithKPIs
(
    @KPI INT
)
RETURNS TABLE
AS
 RETURN (
   SELECT TOP 1000000000
    ProductName
    ,InventoryDate
    ,InventoryCount
    ,PreviousMonthCount
    ,CountVsPreviousCountKPI
    FROM vProductInventoriesWithPreviousMonthCountsWithKPIs
    WHERE CountVsPreviousCountKPI = @KPI
    ORDER BY ProductName, CAST(InventoryDate AS date) ASC
 )
;
go

/* Check that it works:
Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(1);
Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(0);
Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(-1);
*/
SELECT * FROM fProductInventoriesWithPreviousMonthCountsWithKPIs(1);
go
SELECT * FROM fProductInventoriesWithPreviousMonthCountsWithKPIs(0);
go
SELECT * FROM fProductInventoriesWithPreviousMonthCountsWithKPIs(-1);
go

/***************************************************************************************/
