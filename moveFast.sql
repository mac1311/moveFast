-- 1. CREACIÓN DE TABLAS

-- 1.1 Sucursales
CREATE TABLE Sucursales (
    sucursal_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    ciudad VARCHAR(100) NOT NULL
);

-- 1.2 Clientes
CREATE TABLE Clientes (
    cliente_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    ciudad VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    email VARCHAR(100)
);

-- 1.3 Vehículos
CREATE TABLE Vehiculos (
    vehiculo_id SERIAL PRIMARY KEY,
    marca VARCHAR(50) NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    anio INT NOT NULL CHECK (anio BETWEEN 2000 AND 2025),
    estado VARCHAR(20) NOT NULL DEFAULT 'Disponible',
    sucursal_id INT NOT NULL,
    CONSTRAINT fk_veh_sucursal
      FOREIGN KEY (sucursal_id)
      REFERENCES Sucursales(sucursal_id)
      ON DELETE CASCADE
      ON UPDATE CASCADE
);

-- 1.4 Alquileres
CREATE TABLE Alquileres (
    alquiler_id SERIAL PRIMARY KEY,
    cliente_id INT NOT NULL,
    vehiculo_id INT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'Activo',
    CONSTRAINT chk_fecha
      CHECK (fecha_fin >= fecha_inicio),
    CONSTRAINT fk_alq_cliente
      FOREIGN KEY (cliente_id)
      REFERENCES Clientes(cliente_id)
      ON DELETE CASCADE
      ON UPDATE CASCADE,
    CONSTRAINT fk_alq_vehiculo
      FOREIGN KEY (vehiculo_id)
      REFERENCES Vehiculos(vehiculo_id)
      ON DELETE CASCADE
      ON UPDATE CASCADE
);

-- 1.5 Pagos
CREATE TABLE Pagos (
    pago_id SERIAL PRIMARY KEY,
    alquiler_id INT NOT NULL,
    monto NUMERIC(10,2) NOT NULL CHECK (monto > 0),
    fecha_pago DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT fk_pago_alquiler
      FOREIGN KEY (alquiler_id)
      REFERENCES Alquileres(alquiler_id)
      ON DELETE CASCADE
      ON UPDATE CASCADE
);


-- 2. INSERCIÓN DE DATOS DE PRUEBA

-- 2.1 Sucursales
INSERT INTO Sucursales (nombre, ciudad) VALUES
('Central', 'Bogotá'),
('Norte', 'Medellín'),
('Occidente', 'Cali');

-- 2.2 Clientes
INSERT INTO Clientes (nombre, ciudad, telefono, email) VALUES
('Juan Pérez', 'Bogotá', '3001234567', 'juan.perez@mail.com'),
('María Gómez', 'Medellín', '3107654321', 'maria.gomez@mail.com');

-- 2.3 Vehículos
INSERT INTO Vehiculos (marca, modelo, anio, sucursal_id) VALUES
('Toyota', 'Corolla', 2020, 1),
('Ford', 'Fiesta', 2018, 2),
('Chevrolet', 'Spark', 2021, 3);

-- Caso que viola CHECK de año (debería FALLAR)
--INSERT INTO Vehiculos (marca, modelo, anio, sucursal_id) VALUES
--('Renault', 'Clio', 1999, 1);


-- 2.4 Alquileres
INSERT INTO Alquileres (cliente_id, vehiculo_id, fecha_inicio, fecha_fin) VALUES
(1, 1, '2025-04-01', '2025-04-05'),
(2, 2, '2025-04-10', '2025-04-12');

-- Caso que viola CHECK de fechas (fecha_fin < fecha_inicio, debería FALLAR)
--INSERT INTO Alquileres (cliente_id, vehiculo_id, fecha_inicio, fecha_fin) VALUES
--(1, 3, '2025-04-15', '2025-04-10');


-- 2.5 Pagos
INSERT INTO Pagos (alquiler_id, monto, fecha_pago) VALUES
(1, 150.00, '2025-04-02'),
(2, 100.50, '2025-04-11');

-- Caso que viola CHECK de monto > 0 (debería FALLAR)
--INSERT INTO Pagos (alquiler_id, monto) VALUES (1, -20.00);


-- 3. PRUEBAS DE CASCADE

-- 3.1 ON DELETE CASCADE (eliminar cliente 1 y ver que borró su alquiler y pago)
DELETE FROM Clientes WHERE cliente_id = 1;
-- SELECT * FROM Alquileres WHERE cliente_id = 1;  -- debe no devolver filas
-- SELECT * FROM Pagos WHERE alquiler_id = 1;      -- debe no devolver filas

-- 3.2 ON UPDATE CASCADE (cambiar sucursal_id 2 → 20 y ver que Vehiculos se actualiza)
UPDATE Sucursales SET sucursal_id = 20 WHERE sucursal_id = 2;
-- SELECT * FROM Vehiculos WHERE marca = 'Ford';   -- debe mostrar sucursal_id = 20

-- 4. CONSULTAS REQUERIDAS

-- 4.1 Vehículos disponibles en una ciudad concreta (ej. 'Bogotá')
SELECT v.*
FROM Vehiculos v
JOIN Sucursales s ON v.sucursal_id = s.sucursal_id
WHERE s.ciudad = 'Bogotá'
  AND v.estado = 'Disponible';

-- 4.2 Alquileres activos con datos de cliente y vehículo
SELECT a.alquiler_id,
       c.nombre   AS cliente,
       v.marca||' '||v.modelo AS vehiculo,
       a.fecha_inicio,
       a.fecha_fin
FROM Alquileres a
JOIN Clientes c ON a.cliente_id = c.cliente_id
JOIN Vehiculos v ON a.vehiculo_id = v.vehiculo_id
WHERE a.estado = 'Activo';

-- 4.3 Ingresos totales por sucursal (solo vehículos con >3 alquileres)
SELECT s.sucursal_id,
       s.nombre,
       SUM(p.monto) AS ingresos_totales
FROM Pagos p
JOIN Alquileres a ON p.alquiler_id = a.alquiler_id
JOIN Vehiculos v ON a.vehiculo_id = v.vehiculo_id
JOIN Sucursales s ON v.sucursal_id = s.sucursal_id
WHERE v.vehiculo_id IN (
    SELECT vehiculo_id
    FROM Alquileres
    GROUP BY vehiculo_id
    HAVING COUNT(*) > 3
)
GROUP BY s.sucursal_id, s.nombre;

-- 4.4 Vehículos con >5 alquileres (subconsulta)
SELECT *
FROM Vehiculos
WHERE vehiculo_id IN (
    SELECT vehiculo_id
    FROM Alquileres
    GROUP BY vehiculo_id
    HAVING COUNT(*) > 5
);

-- 4.5 Sumar montos de todos los pagos
SELECT SUM(monto) AS total_pagado
FROM Pagos;
