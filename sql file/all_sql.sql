-- All the sql commands I used for the project

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



-- Q1. Customers with most orders
SELECT TOP 15 
    c.CustomerID,                   -- Selects the Customer ID from the Customers table
    c.CompanyName,                  -- Selects the Company Name from the Customers table
    COUNT(o.OrderID) AS "Total Orders" -- Counts the number of orders for each customer and aliases it as "Total Orders"
FROM 
    Customers c                     -- Specifies the Customers table with an alias 'c'
JOIN 
    Orders o ON c.CustomerID = o.CustomerID -- Joins the Orders table on matching CustomerID to find each customer's orders
GROUP BY 
    c.CustomerID,                   -- Groups results by CustomerID to aggregate orders per customer
    c.CompanyName                   -- Groups by CompanyName to align with CustomerID and display the company name
ORDER BY 
    "Total Orders" DESC;            -- Orders the results in descending order by total number of orders



-- Q2. Total Revenue by product category
SELECT 
    cat.CategoryName,                                       -- Selects the Category Name from the Categories table
    ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2) AS TotalRevenue -- Calculates total revenue by multiplying Unit Price, Quantity, and Discount; rounds to 2 decimal places
FROM 
    Categories cat                                          -- Specifies the Categories table with an alias 'cat'
JOIN 
    Products p ON cat.CategoryID = p.CategoryID             -- Joins the Products table on matching CategoryID to link products with their categories
JOIN 
    "Order Details" od ON p.ProductID = od.ProductID        -- Joins the Order Details table on matching ProductID to access order details for each product
GROUP BY 
    cat.CategoryName                                        -- Groups the results by CategoryName to aggregate revenue per category
ORDER BY 
    TotalRevenue DESC;                                      -- Orders the results in descending order by Total Revenue




-- Q3. Most popular products by sales quantity
SELECT 
    p.ProductID,                              -- Selects the Product ID from the Products table
    p.ProductName,                            -- Selects the Product Name from the Products table
    SUM(od.Quantity) AS TotalQuantitySold     -- Sums the Quantity from Order Details for each product and aliases it as "TotalQuantitySold"
FROM 
    Products p                                -- Specifies the Products table with an alias 'p'
JOIN 
    "Order Details" od ON p.ProductID = od.ProductID -- Joins the Order Details table on matching ProductID to access quantities sold for each product
GROUP BY 
    p.ProductID,                              -- Groups by ProductID to aggregate total quantities for each product
    p.ProductName                             -- Groups by ProductName to align with ProductID and display the product name
ORDER BY 
    TotalQuantitySold DESC;                   -- Orders the results in descending order by total quantity sold




-- Q4. Top-performing employees based on the total number of orders handled
SELECT 
    e.EmployeeID,                                         -- Selects the Employee ID from the Employees table
    e.FirstName + ' ' + e.LastName AS EmployeeName,       -- Concatenates FirstName and LastName to create a full name, aliasing it as "EmployeeName"
    COUNT(o.OrderID) AS OrdersHandled                     -- Counts the number of orders handled by each employee and aliases it as "OrdersHandled"
FROM 
    Employees e                                           -- Specifies the Employees table with an alias 'e'
JOIN 
    Orders o ON e.EmployeeID = o.EmployeeID               -- Joins the Orders table on matching EmployeeID to link orders to employees
GROUP BY 
    e.EmployeeID,                                         -- Groups results by EmployeeID to aggregate orders for each employee
    e.FirstName,                                          -- Groups by FirstName to match the SELECT clause (needed for concatenation)
    e.LastName                                            -- Groups by LastName for the same reason
ORDER BY 
    OrdersHandled DESC;                                   -- Orders the results in descending order by the number of orders handled




--  Q5. Sales trends over time 
SELECT 
    YEAR(OrderDate) AS Year,                                  -- Extracts the year from OrderDate and aliases it as "Year"
    MONTH(OrderDate) AS Month,                                -- Extracts the month from OrderDate and aliases it as "Month"
    ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2) AS MonthlySales -- Calculates monthly sales by summing (UnitPrice * Quantity * (1 - Discount)) and rounds to 2 decimal places
FROM 
    Orders o                                                  -- Specifies the Orders table with an alias 'o'
JOIN 
    "Order Details" od ON o.OrderID = od.OrderID              -- Joins the Order Details table on matching OrderID to access order details for each order
GROUP BY 
    YEAR(OrderDate),                                          -- Groups results by year of the OrderDate to calculate monthly sales
    MONTH(OrderDate)                                          -- Groups by month of the OrderDate to get monthly aggregation
ORDER BY 
    Year, Month;                                              -- Orders results by year and month in ascending order




-- Q6. How discounts affect the order frequency and quantity of purchased products
WITH OrderDiscountAnalysis AS (
    -- Step 1: Categorize orders based on whether a discount was applied
    SELECT 
        CASE WHEN od.Discount > 0 THEN 'Discounted' ELSE 'Non-Discounted' END AS DiscountType, -- Labels each order as "Discounted" or "Non-Discounted" based on whether Discount > 0
        COUNT(DISTINCT o.OrderID) AS OrderCount,                  -- Counts unique orders within each discount category, aliasing it as "OrderCount"
        SUM(od.Quantity) AS TotalQuantity,                        -- Sums the total quantity of items for each category, aliasing it as "TotalQuantity"
        AVG(od.Quantity) AS AvgQuantity                           -- Calculates the average quantity per order for each category, aliasing it as "AvgQuantity"
    FROM 
        Orders o                                                  -- Specifies the Orders table with alias 'o'
    JOIN 
        "Order Details" od ON o.OrderID = od.OrderID              -- Joins the Order Details table on OrderID to link each order with its details
    GROUP BY 
        CASE WHEN od.Discount > 0 THEN 'Discounted' ELSE 'Non-Discounted' END -- Groups results by discount presence to separate discounted and non-discounted orders
)
    -- Step 2: Categorize orders based on whether a discount was applied
SELECT 
    DiscountType,                                                 -- Selects the DiscountType label (Discounted or Non-Discounted)
    OrderCount,                                                   -- Displays the count of orders in each discount category
    TotalQuantity,                                                -- Displays the total quantity of items in each discount category
    AvgQuantity                                                   -- Displays the average quantity per order in each discount category
FROM 
    OrderDiscountAnalysis;                                        -- Retrieves the categorized and aggregated results from the CTE



-- Q7. Percentage of orders include a discount, and how it impacts overall revenue
SELECT 
    CONCAT(
        FORMAT(ROUND(SUM(CASE WHEN [Order Details].Discount > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2), '0.##'), '%'
    ) AS DiscountedOrdersPercent,  -- Calculates the percentage of orders with a discount by dividing discounted orders by total orders, rounding to 2 decimal places, and formatting as a percentage
    ROUND(SUM([Order Details].UnitPrice * [Order Details].Quantity * (1 - [Order Details].Discount)), 2) AS DiscountedRevenue, 
    -- Calculates total revenue from discounted orders by multiplying UnitPrice, Quantity, and (1 - Discount), and rounds to 2 decimal places
    ROUND(SUM([Order Details].UnitPrice * [Order Details].Quantity), 2) AS TotalRevenue 
    -- Calculates total revenue without discount adjustments by summing UnitPrice * Quantity for all orders, rounded to 2 decimal places
FROM 
    [Order Details];  -- Specifies the Order Details table for calculations




-- Q8. Regions (by customer location) that generate the highest revenue
SELECT 
    c.Region,  -- Selects the Region from the Customers table to group revenue by region
    ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2) AS TotalRevenue -- Calculates total revenue for each region by multiplying UnitPrice, Quantity, and (1 - Discount), then rounding to 2 decimal places
FROM 
    Orders o  -- Specifies the Orders table with alias 'o'
JOIN 
    Customers c ON o.CustomerID = c.CustomerID  -- Joins the Customers table on CustomerID to link orders to customer regions
JOIN 
    [Order Details] od ON o.OrderID = od.OrderID  -- Joins the Order Details table on OrderID to get product details for each order
GROUP BY 
    c.Region  -- Groups results by customer region to calculate total revenue per region
ORDER BY 
    TotalRevenue DESC;  -- Orders the results in descending order based on the total revenue for each region




-- Q9. Top products in each high-revenue region
WITH RegionalProductRevenue AS (
    -- Step 1: Calculate the total revenue for each product within each region
    SELECT 
        c.Region AS Region,                                -- Selects the Region from the Customers table
        p.ProductName,                                     -- Selects the Product Name from the Products table
        ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2) AS TotalRevenue -- Calculates the total revenue for each product in each region, considering discounts and rounding to 2 decimal places
    FROM 
        Customers c                                        -- Specifies the Customers table with alias 'c'
    JOIN 
        Orders o ON c.CustomerID = o.CustomerID             -- Joins the Orders table to link orders to customers
    JOIN 
        "Order Details" od ON o.OrderID = od.OrderID        -- Joins the Order Details table to access product details for each order
    JOIN 
        Products p ON od.ProductID = p.ProductID           -- Joins the Products table to get product names for the order details
    GROUP BY 
        c.Region, p.ProductName                            -- Groups by Region and ProductName to calculate revenue for each product within each region
)
SELECT 
    Region,                                              -- Selects the Region from the CTE (Common Table Expression)
    ProductName,                                         -- Selects the ProductName from the CTE
    TotalRevenue                                         -- Selects the calculated TotalRevenue for each product in the region
FROM (
    SELECT 
        Region,                                          -- Selects Region from the CTE
        ProductName,                                     -- Selects ProductName from the CTE
        TotalRevenue,                                    -- Selects TotalRevenue from the CTE
        ROW_NUMBER() OVER (PARTITION BY Region ORDER BY TotalRevenue DESC) AS RevenueRank 
        -- Assigns a rank to each product within a region, ordered by descending total revenue
    FROM 
        RegionalProductRevenue                           -- Uses the previously defined CTE
) AS RankedProducts
WHERE 
    RevenueRank = 1                                     -- Filters the results to include only the top product in each region
ORDER BY 
    Region;                                             -- Orders the final results by Region




-- 10. The customer retention rate over a given period
WITH CustomerOrders AS (
    -- Step 1: Calculate the total number of orders placed by each customer
    SELECT 
        CustomerID,                                           -- Selects the CustomerID from the Orders table
        COUNT(OrderID) AS OrdersCount                          -- Counts the total number of orders for each customer
    FROM 
        Orders                                                -- Specifies the Orders table
    GROUP BY 
        CustomerID                                            -- Groups by CustomerID to calculate the total number of orders per customer
)
SELECT 
    CONCAT(
        FORMAT(COUNT(CASE WHEN OrdersCount > 1 THEN 1 END) * 100.0 / COUNT(*), '0.##'), '%'
    ) AS RetentionRatePercent   -- Calculates the percentage of customers who placed more than 1 order (i.e., retained customers) and formats it as a percentage
FROM 
    CustomerOrders;           -- Uses the previously calculated customer order data to compute the retention rate




-- 11. Employee productivity and customer satisfaction relate (based on order completeness and delivery time)
WITH OrderProcessingTime AS (
    -- Step 1: Calculate processing time for each order
    SELECT 
        o.OrderID,                                           -- Selects the OrderID from the Orders table
        o.EmployeeID,                                        -- Selects the EmployeeID who processed the order
        DATEDIFF(day, o.OrderDate, o.ShippedDate) AS ProcessingTime  -- Calculates the processing time in days between OrderDate and ShippedDate
    FROM 
        Orders o                                              -- Specifies the Orders table
    WHERE 
        o.ShippedDate IS NOT NULL                            -- Filters to consider only completed orders with a non-null ShippedDate
),

EmployeeAverageProcessing AS (
    -- Step 2: Calculate the average processing time for each employee
    SELECT 
        e.EmployeeID,                                       -- Selects EmployeeID from Employees table
        e.FirstName + ' ' + e.LastName AS EmployeeName,      -- Concatenates FirstName and LastName to show full employee name
        AVG(op.ProcessingTime) AS AvgProcessingTime           -- Calculates the average processing time for each employee
    FROM 
        OrderProcessingTime op                               -- Uses the previous CTE (OrderProcessingTime) to get the processing times
    JOIN 
        Employees e ON op.EmployeeID = e.EmployeeID          -- Joins the Employees table to retrieve employee details
    GROUP BY 
        e.EmployeeID, e.FirstName, e.LastName                -- Groups by EmployeeID and Name to get the average for each employee
)

-- Step 3: Select employee details and order by average processing time to see productivity ranking
SELECT 
    EmployeeID,                                           -- Selects EmployeeID for reference
    EmployeeName,                                         -- Selects EmployeeName to display full name of employees
    AvgProcessingTime                                     -- Selects the calculated average processing time for each employee
FROM 
    EmployeeAverageProcessing                              -- Uses the previous CTE (EmployeeAverageProcessing) to retrieve the data
ORDER BY 
    AvgProcessingTime;                                    -- Orders the results by average processing time in ascending order (lower is better)

