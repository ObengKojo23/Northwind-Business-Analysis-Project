-- Investigating the structure for each table in the database
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Customers';

SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Orders';

SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'OrderDetails';

SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Products';

SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Employees';



-- Explore Foreign Key Constraints Using SQL Queries:
SELECT 
    tc.TABLE_NAME AS ChildTable,
    kcu.COLUMN_NAME AS ChildColumn,
    ccu.TABLE_NAME AS ParentTable,
    ccu.COLUMN_NAME AS ParentColumn
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS tc
JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS kcu
    ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE AS ccu
    ON ccu.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
WHERE tc.CONSTRAINT_TYPE = 'FOREIGN KEY';



-- Detailed Examination of Individual Table Relationships:
EXEC sp_fkeys @pktable_name = 'Orders';



-- Customers with most orders
SELECT  TOP 15 c.CustomerID, c.CompanyName, COUNT(o.OrderID) AS "Total Orders"
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CompanyName
ORDER BY "Total Orders" DESC;



-- Total Revenue by product category
SELECT cat.CategoryName, ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2) AS TotalRevenue
FROM Categories cat
JOIN Products p ON cat.CategoryID = p.CategoryID
JOIN "Order Details" od ON p.ProductID = od.ProductID
GROUP BY cat.CategoryName
ORDER BY TotalRevenue DESC;



-- Most popular products by sales quantity
SELECT p.ProductID, p.ProductName, SUM(od.Quantity) AS TotalQuantitySold
FROM Products p
JOIN "Order Details" od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY TotalQuantitySold DESC;



-- Top-performing employees based on the total number of orders handled
SELECT e.EmployeeID, e.FirstName + ' ' + e.LastName AS EmployeeName, COUNT(o.OrderID) AS OrdersHandled
FROM Employees e
JOIN Orders o ON e.EmployeeID = o.EmployeeID
GROUP BY e.EmployeeID, e.FirstName, e.LastName
ORDER BY OrdersHandled DESC;



--  Sales trends over time 
SELECT YEAR(OrderDate) AS Year, MONTH(OrderDate) AS Month, 
ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2) AS MonthlySales
FROM Orders o
JOIN "Order Details" od ON o.OrderID = od.OrderID
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY Year, Month;



-- How discounts affect the order frequency and quantity of purchased products
WITH OrderDiscountAnalysis AS (
    -- Step 1: Categorize orders based on discount presence
    SELECT 
        CASE WHEN od.Discount > 0 THEN 'Discounted' ELSE 'Non-Discounted' END AS DiscountType,
        COUNT(DISTINCT o.OrderID) AS OrderCount,
        SUM(od.Quantity) AS TotalQuantity,
        AVG(od.Quantity) AS AvgQuantity
    FROM Orders o
    JOIN "Order Details" od ON o.OrderID = od.OrderID
    GROUP BY CASE WHEN od.Discount > 0 THEN 'Discounted' ELSE 'Non-Discounted' END
)

-- Final Selection: Compare results
SELECT 
    DiscountType,
    OrderCount,
    TotalQuantity,
    AvgQuantity
FROM OrderDiscountAnalysis;



-- Percentage of orders include a discount, and how it impacts overall revenue
SELECT 
    CONCAT(FORMAT(ROUND(SUM(CASE WHEN [Order Details].Discount > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2), '0.##'), '%') AS DiscountedOrdersPercent,
    ROUND(SUM([Order Details].UnitPrice * [Order Details].Quantity * (1 - [Order Details].Discount)), 2) AS DiscountedRevenue,
    ROUND(SUM([Order Details].UnitPrice * [Order Details].Quantity), 2) AS TotalRevenue
FROM [Order Details];



-- Regions (by customer location) that generate the highest revenue
SELECT 
    c.Region, 
    ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2) AS TotalRevenue
FROM 
    Orders o
JOIN 
    Customers c ON o.CustomerID = c.CustomerID
JOIN 
    [Order Details] od ON o.OrderID = od.OrderID
GROUP BY 
    c.Region
ORDER BY 
    TotalRevenue DESC;



-- Top products in each high-revenue region
WITH RegionalProductRevenue AS (
    SELECT 
        c.Region AS Region,
        p.ProductName,
        ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2) AS TotalRevenue
    FROM 
        Customers c
    JOIN 
        Orders o ON c.CustomerID = o.CustomerID
    JOIN 
        "Order Details" od ON o.OrderID = od.OrderID
    JOIN 
        Products p ON od.ProductID = p.ProductID
    GROUP BY 
        c.Region, p.ProductName
)
SELECT 
    Region, 
    ProductName, 
    TotalRevenue
FROM (
    SELECT 
        Region, 
        ProductName, 
        TotalRevenue,
        ROW_NUMBER() OVER (PARTITION BY Region ORDER BY TotalRevenue DESC) AS RevenueRank
    FROM 
        RegionalProductRevenue
) AS RankedProducts
WHERE 
    RevenueRank = 1
ORDER BY 
    Region;



-- The customer retention rate over a given period
WITH CustomerOrders AS (
    SELECT CustomerID, COUNT(OrderID) AS OrdersCount
    FROM Orders
    GROUP BY CustomerID
)
SELECT 
    CONCAT(FORMAT(COUNT(CASE WHEN OrdersCount > 1 THEN 1 END) * 100.0 / COUNT(*), '0.##'), '%') AS RetentionRatePercent
FROM CustomerOrders;



-- Employee productivity and customer satisfaction relate (based on order completeness and delivery time)
WITH OrderProcessingTime AS (
    -- Calculating processing time for each order
    SELECT 
        o.OrderID,
        o.EmployeeID,
        DATEDIFF(day, o.OrderDate, o.ShippedDate) AS ProcessingTime
    FROM Orders o
    WHERE o.ShippedDate IS NOT NULL  -- This Line ensures I only consider completed orders
),

EmployeeAverageProcessing AS (
    -- Calculating average processing time for each employee
    SELECT 
        e.EmployeeID,
        e.FirstName + ' ' + e.LastName AS EmployeeName,
        AVG(op.ProcessingTime) AS AvgProcessingTime
    FROM OrderProcessingTime op
    JOIN Employees e ON op.EmployeeID = e.EmployeeID
    GROUP BY e.EmployeeID, e.FirstName, e.LastName
)

-- Selecting and ordering by average processing time to see productivity ranking
SELECT 
    EmployeeID,
    EmployeeName,
    AvgProcessingTime
FROM EmployeeAverageProcessing
ORDER BY AvgProcessingTime;
