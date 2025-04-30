-- =====================================================
-- 1. ESQUEMA DE TABLAS
-- =====================================================

-- 1.1 Clientes
CREATE TABLE Clientes (
    cliente_id     SERIAL PRIMARY KEY,
    nombre         VARCHAR(100) NOT NULL,
    apellido       VARCHAR(100) NOT NULL,
    fecha_registro DATE        NOT NULL DEFAULT CURRENT_DATE
);

-- 1.2 Meseros
CREATE TABLE Meseros (
    mesero_id   SERIAL PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL,
    apellido    VARCHAR(100) NOT NULL,
    fecha_ingreso DATE      NOT NULL
);

-- 1.3 Mesas
CREATE TABLE Mesas (
    mesa_id      SERIAL PRIMARY KEY,
    numero       INT         NOT NULL UNIQUE,
    piso         INT         NOT NULL,
    num_comensales INT       NOT NULL CHECK (num_comensales > 0)
);

-- 1.4 Platillos
CREATE TABLE Platillos (
    platillo_id SERIAL PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL,
    precio      NUMERIC(12,2) NOT NULL CHECK (precio >= 0)
);

-- 1.5 Bebidas
CREATE TABLE Bebidas (
    bebida_id   SERIAL PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL,
    precio      NUMERIC(12,2) NOT NULL CHECK (precio >= 0)
);

-- 1.6 Facturas
CREATE TABLE Facturas (
    factura_id   SERIAL PRIMARY KEY,
    cliente_id   INT     NOT NULL,
    mesero_id    INT     NOT NULL,
    mesa_id      INT     NOT NULL,
    fecha        DATE    NOT NULL DEFAULT CURRENT_DATE,
    FOREIGN KEY (cliente_id) REFERENCES Clientes(cliente_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    FOREIGN KEY (mesero_id)  REFERENCES Meseros(mesero_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    FOREIGN KEY (mesa_id)    REFERENCES Mesas(mesa_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- 1.7 Detalle Platillos (cada platillo consumido en una factura)
CREATE TABLE DetallePlatillos (
    detalle_id   SERIAL PRIMARY KEY,
    factura_id   INT     NOT NULL,
    platillo_id  INT     NOT NULL,
    cantidad     INT     NOT NULL CHECK (cantidad > 0),
    subtotal     NUMERIC(12,2) NOT NULL CHECK (subtotal >= 0),
    FOREIGN KEY (factura_id)  REFERENCES Facturas(factura_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (platillo_id) REFERENCES Platillos(platillo_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- 1.8 Detalle Bebidas (cada bebida consumida en una factura)
CREATE TABLE DetalleBebidas (
    detalle_id   SERIAL PRIMARY KEY,
    factura_id   INT     NOT NULL,
    bebida_id    INT     NOT NULL,
    cantidad     INT     NOT NULL CHECK (cantidad > 0),
    subtotal     NUMERIC(12,2) NOT NULL CHECK (subtotal >= 0),
    FOREIGN KEY (factura_id) REFERENCES Facturas(factura_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (bebida_id)   REFERENCES Bebidas(bebida_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- =====================================================
-- 2. CONSULTAS SQL BLOQUE 1
-- =====================================================

-- 2.1 Nombre y apellido de clientes que hayan consumido un platillo específico
--    (por ejemplo, platillo_id = 5)
SELECT DISTINCT c.nombre, c.apellido
FROM Clientes c
JOIN Facturas f ON c.cliente_id = f.cliente_id
JOIN DetallePlatillos dp ON f.factura_id = dp.factura_id
WHERE dp.platillo_id = 5;

-- 2.2 Nombre y apellido de clientes que hayan consumido "Arroz a la marinera"
SELECT DISTINCT c.nombre, c.apellido
FROM Clientes c
JOIN Facturas f ON c.cliente_id = f.cliente_id
JOIN DetallePlatillos dp ON f.factura_id = dp.factura_id
JOIN Platillos p ON dp.platillo_id = p.platillo_id
WHERE p.nombre ILIKE 'Arroz a la marinera';

-- 2.3 Nombre del mesero y fecha en que atendió la mesa 10 en el segundo piso
SELECT m.nombre, m.apellido, f.fecha
FROM Facturas f
JOIN Meseros m ON f.mesero_id = m.mesero_id
JOIN Mesas me ON f.mesa_id = me.mesa_id
WHERE me.numero = 10
  AND me.piso   = 2;

-- 2.4 Nombre de clientes junto con nombres de las bebidas que consumieron
SELECT DISTINCT c.nombre, c.apellido, b.nombre AS bebida
FROM Clientes c
JOIN Facturas f ON c.cliente_id = f.cliente_id
JOIN DetalleBebidas db ON f.factura_id = db.factura_id
JOIN Bebidas b ON db.bebida_id = b.bebida_id;

-- 2.5 Todas las facturas que incluyan platillos con importe > $300000
--      mostrando nombre de cliente y platillo
SELECT f.factura_id, c.nombre, c.apellido, p.nombre AS platillo, dp.subtotal
FROM Facturas f
JOIN Clientes c ON f.cliente_id = c.cliente_id
JOIN DetallePlatillos dp ON f.factura_id = dp.factura_id
JOIN Platillos p ON dp.platillo_id = p.platillo_id
WHERE dp.subtotal > 300000;

-- 2.6 Total de consumo (platillos + bebidas) del cliente Manuel Pedroza Gonzalez
SELECT c.nombre, c.apellido,
       COALESCE(SUM(dp.subtotal),0) + COALESCE(SUM(db.subtotal),0) AS total_consumo
FROM Clientes c
LEFT JOIN Facturas f ON c.cliente_id = f.cliente_id
LEFT JOIN DetallePlatillos dp ON f.factura_id = dp.factura_id
LEFT JOIN DetalleBebidas db   ON f.factura_id = db.factura_id
WHERE c.nombre = 'Manuel'
  AND c.apellido = 'Pedroza Gonzalez'
GROUP BY c.nombre, c.apellido;

-- 2.7 Listado de mesas usadas al menos una vez, indicando ubicación y número de comensales
SELECT DISTINCT me.numero, me.piso, me.num_comensales
FROM Mesas me
JOIN Facturas f ON me.mesa_id = f.mesa_id;

-- =====================================================
-- 3. DEFINICIÓN DE VISTAS BLOQUE 2
-- =====================================================

-- 3.1 Vista: Cliente, bebida, platillo, fecha y montos consumidos
CREATE VIEW VistaConsumosTotales AS
SELECT
  c.cliente_id,
  c.nombre,
  c.apellido,
  f.factura_id,
  f.fecha,
  p.nombre   AS platillo,
  dp.cantidad AS cant_platillo,
  dp.subtotal AS subtotal_platillo,
  b.nombre   AS bebida,
  db.cantidad AS cant_bebida,
  db.subtotal AS subtotal_bebida
FROM Clientes c
JOIN Facturas f ON c.cliente_id = f.cliente_id
LEFT JOIN DetallePlatillos dp ON f.factura_id = dp.factura_id
LEFT JOIN Platillos p         ON dp.platillo_id = p.platillo_id
LEFT JOIN DetalleBebidas db   ON f.factura_id = db.factura_id
LEFT JOIN Bebidas b           ON db.bebida_id = b.bebida_id;

-- 3.2 Vista: Mesero, número de factura, fecha y mesa atendida
CREATE VIEW VistaAtencionMeseros AS
SELECT
  m.mesero_id,
  m.nombre   AS nombre_mesero,
  m.apellido AS apellido_mesero,
  f.factura_id,
  f.fecha,
  me.numero  AS numero_mesa,
  me.piso    AS piso_mesa
FROM Meseros m
JOIN Facturas f ON m.mesero_id = f.mesero_id
JOIN Mesas me   ON f.mesa_id   = me.mesa_id;

-- 3.3 Vista: Valor total de compra por cliente (platillos + bebidas)
CREATE VIEW VistaTotalPorCliente AS
SELECT
  c.cliente_id,
  c.nombre,
  c.apellido,
  SUM(dp.subtotal) + SUM(db.subtotal) AS total_consumido
FROM Clientes c
LEFT JOIN Facturas f         ON c.cliente_id = f.cliente_id
LEFT JOIN DetallePlatillos dp ON f.factura_id = dp.factura_id
LEFT JOIN DetalleBebidas db   ON f.factura_id = db.factura_id
GROUP BY c.cliente_id, c.nombre, c.apellido;

-- 3.4 Vista para total de consumo de Manuel Pedroza Gonzalez (consulta 6)
CREATE VIEW VistaConsumoManuelPedroza AS
SELECT *
FROM VistaTotalPorCliente
WHERE nombre = 'Manuel'
  AND apellido = 'Pedroza Gonzalez';

-- 3.5 Vista para listado de mesas usadas al menos una vez (consulta 7)
CREATE VIEW VistaMesasUsadas AS
SELECT DISTINCT
  me.mesa_id,
  me.numero,
  me.piso,
  me.num_comensales
FROM Mesas me
JOIN Facturas f ON me.mesa_id = f.mesa_id;

