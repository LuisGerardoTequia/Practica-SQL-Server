CREATE DATABASE Farmaceutica;
GO
--- Crear Tablas
CREATE TABLE Empleados(
id_empleado  INT PRIMARY KEY IDENTITY,
nombre VARCHAR(50),
apellido VARCHAR(20),
puesto VARCHAR(50),
salario DECIMAL(10,2),
fecha_contratacion DATE,
id_departamento INT,
correo_electronico VARCHAR(90) UNIQUE,
activo BIT,
);

CREATE TABLE Departamentos(
id_departamento INT PRIMARY KEY IDENTITY,
nombre_departamento VARCHAR(50),
ubicacion VARCHAR(59),
presupuesto DECIMAL(10,2),
jefe_departamento INT,
FOREIGN KEY (jefe_departamento) REFERENCES Empleados(id_empleado));

ALTER TABLE Empleados
ADD CONSTRAINT FK_Empleados_Departamentos FOREIGN KEY (id_departamento)
REFERENCES Departamentos (id_departamento);

CREATE TABLE Categorias (
id_categoria INT PRIMARY KEY IDENTITY,
nombre_categoria VARCHAR(50),
descripcion VARCHAR(50),
fecha_creacion DATE,
activo BIT);

CREATE TABLE Productos (
id_producto INT PRIMARY KEY IDENTITY,
nombre_producto VARCHAR(50),
descripcion VARCHAR(40),
precio DECIMAL (15,2),
stock INT,
id_categoria INT,
fecha_creacion DATE,
activo BIT,
FOREIGN KEY (id_categoria) REFERENCES Categorias (id_categoria));

CREATE TABLE Ventas (
id_venta INT PRIMARY KEY IDENTITY,
id_producto INT,
cantidad INT,
fecha_venta DATE,
id_empleado INT,
precio_total DECIMAL(10,2),
FOREIGN KEY (id_producto) REFERENCES Productos(id_producto),
FOREIGN KEY (id_empleado) REFERENCES Empleados(id_empleado)
);

CREATE TABLE Proveedores (
id_proveedor INT PRIMARY KEY IDENTITY,
nombre_proveedor VARCHAR(50), 
direcccion VARCHAR(50),
telefono VARCHAR(20),
correo_electronico VARCHAR(25) UNIQUE,
contacto VARCHAR(50),
id_categoria INT,
FOREIGN KEY (id_categoria) REFERENCES Categorias (id_categoria)
);

CREATE TABLE Compras (
id_compras INT PRIMARY KEY IDENTITY,
id_proveedor INT,
id_producto INT,
cantidad INT,
fecha_compra DATE,
precio_total DECIMAL(10,2),
FOREIGN KEY (id_proveedor) REFERENCES Proveedores (id_proveedor),
FOREIGN KEY (id_producto) REFERENCES Productos (id_producto));

--- Insertar Datos
INSERT INTO Empleados(nombre,apellido,puesto,salario,fecha_contratacion,id_departamento,correo_electronico,activo)VALUES 
('Luis', 'Pérez', 'Vendedor', 2000.00, '2024-01-01', NULL, 'luis.perez@farmaceutica.com', 1),
('Ana', 'Gómez', 'Jefe de Producción', 3500.00, '2023-03-15', NULL, 'ana.gomez@farmaceutica.com', 1);

INSERT INTO Departamentos(nombre_departamento,ubicacion,presupuesto,jefe_departamento)VALUES
('Ventas', 'Bogotá', 50000.00, 1),
('Producción', 'Cali', 120000.00, 2);

INSERT INTO Productos(nombre_producto,descripcion,precio,stock,id_categoria,fecha_creacion,activo) VALUES
('Ibuprofeno', 'Anti-inflamatorio', 5.00, 100, 1, GETDATE(), 1),
('Vitamina C', 'Suplemento alimenticio', 10.00, 50, 2, GETDATE(), 1);

INSERT INTO Categorias(nombre_categoria,descripcion,fecha_creacion,activo) VALUES 
('Medicamentos', 'Productos para la salud', GETDATE(), 1),
('Suplementos', 'Vitaminas y minerales', GETDATE(), 1);

INSERT INTO Ventas(id_producto,cantidad,fecha_venta,id_empleado,precio_total) VALUES 
(2, 15, '2024-11-18', 1, 2250.00),
(2, 10, '2024-11-18', 2, 3000.00),
(3, 20, '2024-11-19', 1, 4000.00);

INSERT INTO Proveedores(nombre_proveedor,direcccion,telefono,correo_electronico,contacto,id_categoria) VALUES 
('Farmacia Alfa', 'Calle 45 #32-10', '3001234567', 'contacto@farmaciaalfa.com', 'María Pérez', 1),
('Distribuidora Beta', 'Avenida 23 #10-90', '3109876543', 'ventas@beta.com', 'Carlos López', 2),
('Medicamentos Gamma', 'Carrera 67 #89-45', '3057890123', 'info@gamma.com', 'Ana Torres', 3);

INSERT INTO Compras(id_proveedor,id_producto,cantidad,fecha_compra,precio_total) VALUES 
(5, 2, 50, '2024-11-17', 5000.00),
(6, 2, 30, '2024-11-17', 2400.00),
(7, 3, 40, '2024-11-18', 3000.00);


--- Validar el cargue haya salido bien
SELECT * FROM Productos;
SELECT * FROM Proveedores;
--- INDEX
CREATE INDEX idx_productos_stock ON Productos(stock);

--- Funcion
CREATE FUNCTION TotalVentasProducto (@id_producto INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
DECLARE @total DECIMAL(10,2)
SELECT @total =SUM(precio_total) FROM Ventas WHERE id_producto = @id_producto;
RETURN ISNULL(@total,0);
END;

CREATE FUNCTION VerificarStockMinimo (@id_producto INT)
RETURNS BIT
AS
BEGIN
DECLARE @stock INT
SELECT @stock =stock FROM Productos WHERE id_producto =@id_producto;
RETURN CASE WHEN @stock < 10 THEN 1 ELSE 0 END;
END;

--- TRIGGER
CREATE TRIGGER ActualizarStockVenta
ON Ventas
AFTER INSERT
AS
BEGIN
UPDATE Productos
SET stock = stock - (SELECT cantidad FROM inserted WHERE inserted.id_producto = Productos.id_producto)
WHERE id_producto IN (SELECT id_producto FROM inserted);
END;



CREATE TRIGGER PrevenirStockNegativo
ON Ventas
AFTER INSERT
AS
BEGIN
IF EXISTS (SELECT 1 FROM Productos WHERE stock < 0)
BEGIN
RAISERROR('Stock insuficiente para completar la venta.', 16, 1);
ROLLBACK;
END;
END;

CREATE TRIGGER AuditoriaCompras
ON Compras
AFTER INSERT
AS
BEGIN
    INSERT INTO Auditoria (tabla_afectada, descripcion, fecha)
    VALUES ('Compras', 'Compra registrada', GETDATE());
END;


--- Creación de Usuarios y Permisos
CREATE LOGIN usuario_ventas WITH PASSWORD = 'Ventas123!';
CREATE LOGIN usuario_produccion WITH PASSWORD = 'Produccion123!';
CREATE LOGIN usuario_admin WITH PASSWORD = 'Admin123!';


CREATE USER usuario_ventas FOR LOGIN usuario_ventas;
CREATE USER usuario_produccion FOR LOGIN usuario_produccion;
CREATE USER usuario_admin FOR LOGIN usuario_admin;

GRANT SELECT,INSERT ON Productos TO usuario_ventas;
GRANT SELECT,UPDATE ON Productos TO usuario_produccion;
GRANT ALL ON Productos TO usuario_admin;

--- Creacion de Procedimientos
CREATE PROCEDURE RegistrarVenta
    @id_producto INT,
    @cantidad INT,
    @id_empleado INT
AS
BEGIN
    DECLARE @precio DECIMAL(10,2)
    SELECT @precio = precio FROM Productos WHERE id_producto = @id_producto;

    INSERT INTO Ventas (id_producto, cantidad, fecha_venta, id_empleado, precio_total)
    VALUES (@id_producto, @cantidad, GETDATE(), @id_empleado, @precio * @cantidad);

    UPDATE Productos SET stock = stock - @cantidad WHERE id_producto = @id_producto;
END;

---- CTE
-- CTE para calcular ventas totales por producto

WITH TotalVentas AS(
SELECT id_producto, SUM(cantidad) AS total_vendido
FROM Ventas
GROUP BY id_producto
)

SELECT p.nombre_producto, t.total_vendido
FROM TotalVentas t 
JOIN Productos p ON p.id_producto = t.id_producto;

-- CTE para productos con bajo stock

WITH ProductosBajoStock AS(
SELECT id_producto, nombre_producto, stock
FROM Productos
WHERE stock >20
)
SELECT * FROM ProductosBajoStock;

--- Particiones 
-- Ranking Ventas
SELECT id_empleado, id_producto, cantidad,
RANK() OVER(PARTITION BY id_empleado ORDER BY cantidad DESC) AS ranking_ventas
FROM Ventas;

-- Suma Acumulada por Categorias
SELECT c.nombre_categoria, p.nombre_producto,
SUM(p.stock) OVER(PARTITION BY c.id_categoria) AS stock_total_categoria
FROM Productos p 
JOIN Categorias c ON p.id_categoria =c.id_categoria;

-- Partición para conteo de compras por Proveedor

SELECT id-proveedor, cantidad,
COUNT(*) OVER (PARTITION BY id_proveedor) AS total_compras_proveedor
FROM Compras;

--- Windows Functions 
-- WFS Ventas Acumuladas por producto
SELECT id_producto, cantidad,
SUM(cantidad) OVER(ORDER BY fecha_venta ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS ventas_acunuladas
FROM Ventas;


-- WFS Promedio de precio por producto
SELECT nombre_producto, precio,
AVG(precio) OVER(PARTITION BY id_categoria) AS precio_promedio_categoria
FROM Productos;


--- Vistas Materializadas (Simulación en tablas)
-- Ventas Totales por producto
CREATE TABLE Ventastotales AS 
SELECT id_producto, SUM(precio_total) AS Venta_Total
FROM Ventas
GROUP BY id_producto
ORDER BY Venta_Total DESC;

-- Compras totales por proveedor
CREATE TABLE Compras Totales AS
SELECT id_proveedor, SUM(precio_total) AS Total_Compras
FROM Compras
GROUP BY id_proveedor
ORDER BY Total_Compras DESC;

-- Stock por Categoria
CREATE TABLE StockCategorias AS
SELECT id_categoria, COUNT(stock) AS stock
FROM Productos
GROUP BY id_categoria
ORDER BY stock DESC;

--- JOINS 
-- INNER JOIN para obtener ventas y nombres de Productos
SELECT v.id_venta,p.nombre_producto, v.cantidad, v.precio_total
FROM ventas v 
INNER JOIN Productos p ON v.id_producto = p.id_producto;

-- LEFT JOIN para proveedores y Categorias
SELECT p.id_proveedor, p.nombre_proveedor, c.nombre_categoria, c.activo 
FROM Proveedores p 
LEFT JOIN Categorias c ON p.id_categoria = c.id_categoria;
GROUP BY nombre_categoria 
ORDER BY COUNT(id_categoria) DESC;

-- RIGHT JOIN para empleados y Departamentos
SELECT e.id_empleado, d.nombre_departamento,e.puesto, d.jefe_departamento
FROM Empleados e
RIGHT JOIN Departamentos d ON e.id_departamento = d.id_departamento
GROUP BY nombre_departamento
ORDER BY Salario DESC;


-- FULL OUTER JOIN para productos y Ventas
SELECT p.id_producto, p.nombre_producto, SUM(v.precio_total) AS Ventas_Totales, SUM(v. cantidad)  AS Cantidad_Total
FROM Productos p
OUTER JOIN Ventas v ON p.id_producto = v.id_producto
GROUP BY nombre_producto
ORDER BY Cantidad_Total DESC;

-- CROSS JOIN para generar combinaciones de categorias y proveedores 
SELECT c.id_categoria, c.nombre_categoria, p.nombre_proveedor, p.contacto
FROM Categorias c
CROSS JOIN Proveedores ON c.id_categoria = p.id_categoria
ORDER BY nombre_categoria DESC;


