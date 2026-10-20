USE master;
GO

IF DB_ID('BI_Nanoparuro') IS NOT NULL
BEGIN
    ALTER DATABASE BI_Nanoparuro SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BI_Nanoparuro;
END;
GO

CREATE DATABASE BI_Nanoparuro;
GO

USE BI_Nanoparuro;
GO

/* =========================   DIM_CLIENTE   ========================= */
CREATE TABLE DIM_CLIENTE (
    ClienteKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID VARCHAR(50) NOT NULL UNIQUE,
    NombreCliente VARCHAR(150),
    TipoCliente VARCHAR(50)
);
GO

/* =========================   DIM_PRODUCTO   ========================= */
CREATE TABLE DIM_PRODUCTO (
    ProductoKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductID VARCHAR(50) NOT NULL UNIQUE,
    NombreProducto VARCHAR(150),
    Categoria VARCHAR(100),
    Subcategoria VARCHAR(100)
);
GO

/* =========================   DIM_FECHA   ========================= */
CREATE TABLE DIM_FECHA (
    FechaKey INT PRIMARY KEY,
    Fecha DATE NOT NULL UNIQUE,
    Dia TINYINT NOT NULL,
    Mes TINYINT NOT NULL,
    NombreMes VARCHAR(20) NOT NULL,
    Trimestre TINYINT NOT NULL,
    Año SMALLINT NOT NULL
);
GO

/* =========================   DIM_GEOGRAFIA   ========================= */
CREATE TABLE DIM_GEOGRAFIA (
    GeografiaKey INT IDENTITY(1,1) PRIMARY KEY,
    Ciudad VARCHAR(100) NOT NULL,
    Estado VARCHAR(100) NOT NULL,
    Region VARCHAR(100) NOT NULL,
    CodigoPostal VARCHAR(20) NOT NULL,

    CONSTRAINT UQ_DIM_GEOGRAFIA
    UNIQUE (Ciudad, Estado, Region, CodigoPostal)
);
GO

/* =========================   DIM_VENDEDOR   ========================= */
CREATE TABLE DIM_VENDEDOR (
    VendedorKey INT IDENTITY(1,1) PRIMARY KEY,
    SellerID VARCHAR(50) NOT NULL UNIQUE,
    NombreVendedor VARCHAR(150),
    CiudadVendedor VARCHAR(100),
    RegionVendedor VARCHAR(100)
);
GO

/* =========================   STG_Ventas   ========================= */
CREATE TABLE STG_Ventas (
    OrderID VARCHAR(50) PRIMARY KEY,
    CustomerID VARCHAR(50) NOT NULL,
    NombreCliente VARCHAR(150),
    TipoCliente VARCHAR(50),

    ProductID VARCHAR(50) NOT NULL,
    NombreProducto VARCHAR(150),
    Categoria VARCHAR(100),
    Subcategoria VARCHAR(100),

    FechaVenta DATE NOT NULL,

    Ciudad VARCHAR(100),
    Estado VARCHAR(100),
    Region VARCHAR(100),
    CodigoPostal VARCHAR(20),

    SellerID VARCHAR(50) NOT NULL,
    NombreVendedor VARCHAR(150),

    Cantidad INT NOT NULL,
    Precio DECIMAL(18,2) NOT NULL,
    CostoFlete DECIMAL(18,2) NOT NULL
);
GO

/* =========================   DATOS STG_Ventas   ========================= */
INSERT INTO STG_Ventas VALUES(
    'ORD-1001', 'CLI-01', ' Juan Perez ', 'Empresa',
    'PROD-01', 'Arduino Uno R3', 'Microcontroladores', 'Placas',
    '2026-03-01', 'Lima', 'Lima', 'Cercado', '15001',
    'VEN-01', 'Carlos Gomez', 5, 45.00, 10.00
),
(
    'ORD-1002', 'CLI-02', 'Maria Lopez', 'Final',
    'PROD-02', 'Sensor DHT11', 'Sensores', 'Temperatura',
    '2026-03-02', 'Arequipa', 'Arequipa', 'Arequipa', '04001',
    'VEN-02', 'Ana Torres', 2, 12.50, 5.00
),
(
    'ORD-1003', 'CLI-01', 'Juan Perez', 'Empresa',
    'PROD-02', 'Sensor DHT11', 'Sensores', 'Temperatura',
    '2026-03-03', 'Lima', 'Lima', 'Cercado', '15001',
    'VEN-01', 'Carlos Gomez', 10, 12.00, 8.00
),
(
    'ORD-1004', 'CLI-03', '  Tech Solutions ', 'Empresa',
    'PROD-03', 'ESP32 Wi-Fi', 'Microcontroladores', 'Placas',
    '2026-03-04', 'Trujillo', 'La Libertad', 'Trujillo', '13001',
    'VEN-01', 'Carlos Gomez', 20, 28.00, 15.00
);
GO

/* =========================   CARGAR DIM_CLIENTE   ========================= */
INSERT INTO DIM_CLIENTE(CustomerID, NombreCliente, TipoCliente)
SELECT
    TRIM(CustomerID),
    TRIM(NombreCliente),
    TRIM(TipoCliente)
FROM STG_Ventas
GROUP BY
    TRIM(CustomerID),
    TRIM(NombreCliente),
    TRIM(TipoCliente);
GO

/* =========================   CARGAR DIM_PRODUCTO   ========================= */
INSERT INTO DIM_PRODUCTO(ProductID, NombreProducto, Categoria, Subcategoria)
SELECT
    TRIM(ProductID),
    TRIM(NombreProducto),
    TRIM(Categoria),
    TRIM(Subcategoria)
FROM STG_Ventas
GROUP BY
    TRIM(ProductID),
    TRIM(NombreProducto),
    TRIM(Categoria),
    TRIM(Subcategoria);
GO

/* =========================   CARGAR DIM_FECHA   ========================= */
INSERT INTO DIM_FECHA(
    FechaKey,
    Fecha,
    Dia,
    Mes,
    NombreMes,
    Trimestre,
    Año
)
SELECT
    CONVERT(INT, CONVERT(VARCHAR(8), FechaVenta, 112)),
    FechaVenta,
    DAY(FechaVenta),
    MONTH(FechaVenta),
    DATENAME(MONTH, FechaVenta),
    DATEPART(QUARTER, FechaVenta),
    YEAR(FechaVenta)
FROM STG_Ventas
GROUP BY FechaVenta;
GO

/* =========================   CARGAR DIM_GEOGRAFIA   ========================= */
INSERT INTO DIM_GEOGRAFIA(
    Ciudad,
    Estado,
    Region,
    CodigoPostal
)
SELECT
    TRIM(Ciudad),
    TRIM(Estado),
    TRIM(Region),
    TRIM(CodigoPostal)
FROM STG_Ventas
GROUP BY
    TRIM(Ciudad),
    TRIM(Estado),
    TRIM(Region),
    TRIM(CodigoPostal);
GO

/* =========================   CARGAR DIM_VENDEDOR   ========================= */
INSERT INTO DIM_VENDEDOR(
    SellerID,
    NombreVendedor,
    CiudadVendedor,
    RegionVendedor
)
SELECT
    TRIM(SellerID),
    MAX(TRIM(NombreVendedor)),
    MAX(TRIM(Ciudad)),
    MAX(TRIM(Region))
FROM STG_Ventas
GROUP BY
    TRIM(SellerID);
GO

/* =========================   FACT_VENTAS   ========================= */
CREATE TABLE FACT_VENTAS (
    VentaKey BIGINT IDENTITY(1,1) PRIMARY KEY,

    ClienteKey INT NOT NULL,
    ProductoKey INT NOT NULL,
    FechaKey INT NOT NULL,
    GeografiaKey INT NOT NULL,
    VendedorKey INT NOT NULL,

    OrderID VARCHAR(50) NOT NULL UNIQUE,
    Cantidad INT NOT NULL,
    Precio DECIMAL(18,2) NOT NULL,
    CostoFlete DECIMAL(18,2) NOT NULL,

    ImporteTotal AS (
        CONVERT(
            DECIMAL(18,2),
            (Cantidad * Precio) + CostoFlete
        )
    ) PERSISTED,

    CONSTRAINT FK_FACT_CLIENTE
        FOREIGN KEY (ClienteKey)
        REFERENCES DIM_CLIENTE(ClienteKey),

    CONSTRAINT FK_FACT_PRODUCTO
        FOREIGN KEY (ProductoKey)
        REFERENCES DIM_PRODUCTO(ProductoKey),

    CONSTRAINT FK_FACT_FECHA
        FOREIGN KEY (FechaKey)
        REFERENCES DIM_FECHA(FechaKey),

    CONSTRAINT FK_FACT_GEOGRAFIA
        FOREIGN KEY (GeografiaKey)
        REFERENCES DIM_GEOGRAFIA(GeografiaKey),

    CONSTRAINT FK_FACT_VENDEDOR
        FOREIGN KEY (VendedorKey)
        REFERENCES DIM_VENDEDOR(VendedorKey)
);
GO

/* =========================   CARGAR FACT_VENTAS   ========================= */
INSERT INTO FACT_VENTAS(
    ClienteKey,
    ProductoKey,
    FechaKey,
    GeografiaKey,
    VendedorKey,
    OrderID,
    Cantidad,
    Precio,
    CostoFlete
)
SELECT
    c.ClienteKey,
    p.ProductoKey,
    f.FechaKey,
    g.GeografiaKey,
    v.VendedorKey,
    s.OrderID,
    s.Cantidad,
    s.Precio,
    s.CostoFlete
FROM STG_Ventas s
INNER JOIN DIM_CLIENTE c
    ON TRIM(s.CustomerID) = c.CustomerID
INNER JOIN DIM_PRODUCTO p
    ON TRIM(s.ProductID) = p.ProductID
INNER JOIN DIM_FECHA f
    ON CONVERT(INT, CONVERT(VARCHAR(8), s.FechaVenta, 112)) = f.FechaKey
INNER JOIN DIM_GEOGRAFIA g
    ON TRIM(s.Ciudad) = g.Ciudad
    AND TRIM(s.Estado) = g.Estado
    AND TRIM(s.Region) = g.Region
    AND TRIM(s.CodigoPostal) = g.CodigoPostal
INNER JOIN DIM_VENDEDOR v
    ON TRIM(s.SellerID) = v.SellerID;
GO

SELECT * FROM FACT_VENTAS;
GO

SELECT * FROM DIM_CLIENTE;
go

SELECT * FROM DIM_PRODUCTO;
GO

SELECT * FROM DIM_FECHA;
GO

SELECT * FROM DIM_GEOGRAFIA;
GO

SELECT * FROM DIM_VENDEDOR;
