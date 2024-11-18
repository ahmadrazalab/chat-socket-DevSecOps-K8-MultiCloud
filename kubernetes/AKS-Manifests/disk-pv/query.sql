CREATE DATABASE testdb1;
USE testdb1;

CREATE TABLE employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    position VARCHAR(100),
    salary DECIMAL(10, 2)
);

INSERT INTO employees (name, position, salary) VALUES
('Alice', 'Developer', 70000),
('Bob', 'Designer', 60000),
('Charlie', 'Manager', 80000);

CREATE DATABASE testdb2;
USE testdb2;

CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100),
    price DECIMAL(10, 2)
);

INSERT INTO products (product_name, price) VALUES
('Laptop', 1200.00),
('Phone', 800.00),
('Tablet', 600.00);



#########################


SELECT * FROM testdb1.employees;
SELECT * FROM testdb2.products;
