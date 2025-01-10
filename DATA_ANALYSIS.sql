--task-2

--Create the database 
CREATE DATABASE sales_analysis;
USE sales_analysis;

--  Create Employees Table
CREATE TABLE employees (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    department VARCHAR(100)
);
show tables;
--  Create Sales Table
CREATE TABLE sales (
    sale_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id INT,
    sale_date DATE,
    amount DECIMAL(10, 2),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

--  Insert Data into Employees Table
INSERT INTO employees (first_name, last_name, department)
VALUES
('John', 'Doe', 'Sales'),
('Jane', 'Smith', 'Sales'),
('Alice', 'Brown', 'Sales'),
('Bob', 'Johnson', 'Marketing'),
('Charlie', 'Davis', 'Sales');

--  Insert Data into Sales Table
INSERT INTO sales (employee_id, sale_date, amount)
VALUES
(1, '2024-01-01', 1000),
(1, '2024-01-10', 1500),
(1, '2024-02-15', 2000),
(2, '2024-01-05', 2000),
(2, '2024-01-25', 2500),
(2, '2024-02-05', 1500),
(3, '2024-01-10', 3000),
(3, '2024-01-30', 3500),
(3, '2024-02-10', 4000),
(4, '2024-01-15', 1800),
(5, '2024-01-20', 2200);

-- ===========================================
-- Example 1: Using Window Functions
-- Calculate the running total of sales for each employee by sale date
-- We will use the SUM() window function to get a running total
SELECT 
    e.first_name,
    e.last_name,
    s.sale_date,
    s.amount,
    SUM(s.amount) OVER (PARTITION BY e.employee_id ORDER BY s.sale_date) AS running_total_sales  -- Window function: SUM() for running total
FROM 
    sales s
JOIN 
    employees e ON s.employee_id = e.employee_id
ORDER BY 
    e.employee_id, s.sale_date;

-- Example 2: Using Window Functions for Ranking Employees by Total Sales
-- We will use the RANK() window function to rank employees based on total sales
SELECT 
    e.first_name,
    e.last_name,
    SUM(s.amount) AS total_sales,
    RANK() OVER (ORDER BY SUM(s.amount) DESC) AS sales_rank  -- Window function: RANK() to rank employees by total sales
FROM 
    sales s
JOIN 
    employees e ON s.employee_id = e.employee_id
GROUP BY 
    e.employee_id
ORDER BY 
    sales_rank;

-- ===========================================
-- Example 3: Using Subqueries
-- Subquery to find employees with sales greater than the average sales
SELECT 
    e.first_name,
    e.last_name,
    SUM(s.amount) AS total_sales
FROM 
    sales s
JOIN 
    employees e ON s.employee_id = e.employee_id
GROUP BY 
    e.employee_id
HAVING 
    SUM(s.amount) > (
        SELECT AVG(total_sales)
        FROM (
            SELECT SUM(amount) AS total_sales
            FROM sales
            GROUP BY employee_id
        ) AS avg_sales
    )
ORDER BY 
    total_sales DESC;

-- Example 4: Using Subquery for Monthly Sales Comparison
-- We will compare sales of each employee month-to-month and use a subquery to find if current month sales are higher than last month
SELECT 
    e.first_name,
    e.last_name,
    EXTRACT(MONTH FROM s.sale_date) AS month,
    EXTRACT(YEAR FROM s.sale_date) AS year,
    SUM(s.amount) AS current_month_sales,
    SUM(CASE 
            WHEN EXTRACT(MONTH FROM s.sale_date) = EXTRACT(MONTH FROM CURDATE()) - 1 
            THEN s.amount
            ELSE 0
        END) AS previous_month_sales,
    CASE
        WHEN SUM(s.amount) > 
            SUM(CASE 
                    WHEN EXTRACT(MONTH FROM s.sale_date) = EXTRACT(MONTH FROM CURDATE()) - 1 
                    THEN s.amount
                    ELSE 0
                END) THEN 'Increased'
        ELSE 'Decreased'
    END AS sales_trend
FROM 
    sales s
JOIN 
    employees e ON s.employee_id = e.employee_id
GROUP BY 
    e.employee_id, EXTRACT(YEAR FROM s.sale_date), EXTRACT(MONTH FROM s.sale_date)
ORDER BY 
    e.employee_id, year, month;

-- ===========================================
-- Example 5: Using CTE (Common Table Expressions) for Monthly Sales Summaries
-- We will use a CTE to calculate monthly total sales per employee and then filter out employees with sales below a threshold
WITH MonthlySales AS (
    SELECT 
        e.employee_id,
        e.first_name,
        e.last_name,
        EXTRACT(MONTH FROM s.sale_date) AS month,
        SUM(s.amount) AS total_sales
    FROM 
        sales s
    JOIN 
        employees e ON s.employee_id = e.employee_id
    GROUP BY 
        e.employee_id, EXTRACT(MONTH FROM s.sale_date)
)
SELECT 
    employee_id,
    first_name,
    last_name,
    month,
    total_sales
FROM 
    MonthlySales
WHERE 
    total_sales > 2500  -- Filtering employees with total sales > 2500
ORDER BY 
    total_sales DESC;

-- Example 6: Using CTE for Yearly Sales Summary and Ranking
-- We will use a CTE to calculate yearly sales for employees and then rank them based on sales
WITH YearlySales AS (
    SELECT 
        e.employee_id,
        e.first_name,
        e.last_name,
        SUM(s.amount) AS yearly_sales
    FROM 
        sales s
    JOIN 
        employees e ON s.employee_id = e.employee_id
    GROUP BY 
        e.employee_id
)
SELECT 
    employee_id,
    first_name,
    last_name,
    yearly_sales,
    RANK() OVER (ORDER BY yearly_sales DESC) AS sales_rank  -- Window function: RANK() to rank by total yearly sales
FROM 
    YearlySales
ORDER BY 
    sales_rank;


-- Define a Common Table Expression (CTE) to calculate the total sales per employee
WITH total_sales_per_employee AS (
    SELECT 
        e.employee_id,
        e.first_name,
        e.last_name,
        SUM(s.amount) AS total_sales  -- Calculate the total sales for each employee
    FROM 
        sales s
    JOIN 
        employees e ON s.employee_id = e.employee_id
    GROUP BY 
        e.employee_id, e.first_name, e.last_name  -- Group by employee to get the total sales
)
-- Main query to use the results from the CTE
SELECT 
    employee_id,
    first_name,
    last_name,
    total_sales,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank  -- Rank employees based on total sales in descending order
FROM 
    total_sales_per_employee  -- Referencing the CTE created above
ORDER BY 
    sales_rank;  -- Sort the results by the sales rank

