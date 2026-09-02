-- ============================================================
-- ALERTIFY DATABASE
-- Compatible with XAMPP (MySQL / MariaDB)
-- ============================================================

CREATE DATABASE IF NOT EXISTS alertify
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE alertify;

-- --------------------------------------------------------
-- Table: users
-- Users of the system (citizens, operators, admins)
-- --------------------------------------------------------
CREATE TABLE users (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name       VARCHAR(120) NOT NULL,
    email           VARCHAR(150) NOT NULL UNIQUE,
    phone           VARCHAR(20) DEFAULT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    role            ENUM('citizen', 'operator', 'admin') NOT NULL DEFAULT 'citizen',
    is_active       TINYINT(1) NOT NULL DEFAULT 1,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- --------------------------------------------------------
-- Table: accident_types
-- Catalog of accident / incident types
-- --------------------------------------------------------
CREATE TABLE accident_types (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(80) NOT NULL UNIQUE,
    description VARCHAR(255) DEFAULT NULL,
    severity    ENUM('low', 'medium', 'high', 'critical') NOT NULL DEFAULT 'medium',
    icon        VARCHAR(50) DEFAULT NULL,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- --------------------------------------------------------
-- Table: incidents
-- Main table: real-time accidents / incidents
-- --------------------------------------------------------
CREATE TABLE incidents (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    accident_type_id    INT UNSIGNED NOT NULL,
    reported_by         INT UNSIGNED DEFAULT NULL,          -- user who reported (can be null if system)
    title               VARCHAR(150) NOT NULL,
    description         TEXT,
    latitude            DECIMAL(10, 8) NOT NULL,
    longitude           DECIMAL(11, 8) NOT NULL,
    address             VARCHAR(255) DEFAULT NULL,
    city                VARCHAR(100) DEFAULT 'Bogotá',
    department          VARCHAR(100) DEFAULT NULL,
    status              ENUM('reported', 'confirmed', 'in_progress', 'resolved', 'false_alarm') 
                        NOT NULL DEFAULT 'reported',
    severity            ENUM('low', 'medium', 'high', 'critical') NOT NULL DEFAULT 'medium',
    victims_count       INT UNSIGNED DEFAULT 0,
    is_live             TINYINT(1) NOT NULL DEFAULT 1,      -- visible in real-time map
    reported_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at         DATETIME DEFAULT NULL,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_incident_type 
        FOREIGN KEY (accident_type_id) REFERENCES accident_types(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_incident_user 
        FOREIGN KEY (reported_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    INDEX idx_status (status),
    INDEX idx_live (is_live),
    INDEX idx_location (latitude, longitude),
    INDEX idx_reported_at (reported_at)
) ENGINE=InnoDB;

-- --------------------------------------------------------
-- Table: alerts
-- Alerts automatically sent to emergency line 123
-- --------------------------------------------------------
CREATE TABLE alerts (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    incident_id     INT UNSIGNED NOT NULL,
    alert_code      VARCHAR(30) NOT NULL,                   -- unique code of the alert
    sent_to         VARCHAR(20) NOT NULL DEFAULT '123',     -- emergency service
    message         TEXT NOT NULL,
    status          ENUM('pending', 'sent', 'acknowledged', 'failed') 
                    NOT NULL DEFAULT 'pending',
    response_notes  TEXT DEFAULT NULL,
    sent_at         DATETIME DEFAULT NULL,
    acknowledged_at DATETIME DEFAULT NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_alert_incident 
        FOREIGN KEY (incident_id) REFERENCES incidents(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    UNIQUE KEY uk_alert_code (alert_code),
    INDEX idx_alert_status (status)
) ENGINE=InnoDB;

-- --------------------------------------------------------
-- Table: incident_updates
-- History of status changes and additional notes
-- --------------------------------------------------------
CREATE TABLE incident_updates (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    incident_id     INT UNSIGNED NOT NULL,
    user_id         INT UNSIGNED DEFAULT NULL,
    old_status      VARCHAR(30) DEFAULT NULL,
    new_status      VARCHAR(30) NOT NULL,
    note            TEXT,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_update_incident 
        FOREIGN KEY (incident_id) REFERENCES incidents(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_update_user 
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- --------------------------------------------------------
-- Table: community_reports
-- Extra reports from citizens about an existing incident
-- --------------------------------------------------------
CREATE TABLE community_reports (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    incident_id     INT UNSIGNED NOT NULL,
    user_id         INT UNSIGNED DEFAULT NULL,
    comment         TEXT NOT NULL,
    photo_url       VARCHAR(255) DEFAULT NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_community_incident 
        FOREIGN KEY (incident_id) REFERENCES incidents(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_community_user 
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- SAMPLE DATA
-- ============================================================

-- Users
INSERT INTO users (full_name, email, phone, password_hash, role) VALUES
('Admin Alertify', 'admin@alertify.co', '3001234567', '$2y$10$examplehashadmin', 'admin'),
('Operador 123', 'operador@alertify.co', '3009876543', '$2y$10$examplehashoperator', 'operator'),
('Juan Pérez', 'juan.perez@email.com', '3105551234', '$2y$10$examplehashcitizen', 'citizen'),
('María Gómez', 'maria.gomez@email.com', '3204449876', '$2y$10$examplehashcitizen2', 'citizen');

-- Accident types
INSERT INTO accident_types (name, description, severity, icon) VALUES
('Choque vehicular', 'Colisión entre dos o más vehículos', 'high', 'car-crash'),
('Atropello', 'Persona atropellada por un vehículo', 'critical', 'pedestrian'),
('Volcamiento', 'Vehículo que se volcó', 'high', 'rollover'),
('Incendio vehicular', 'Vehículo en llamas', 'critical', 'fire'),
('Accidente de moto', 'Accidente que involucra motocicletas', 'high', 'motorcycle'),
('Caída de árbol / objeto', 'Obstáculo en la vía', 'medium', 'obstacle'),
('Otro', 'Otro tipo de incidente', 'medium', 'other');

-- Sample incidents
INSERT INTO incidents 
(accident_type_id, reported_by, title, description, latitude, longitude, address, city, department, status, severity, victims_count, is_live) 
VALUES
(1, 3, 'Choque en Autopista Norte', 'Colisión entre carro y camión en el carril central', 4.73500000, -74.05000000, 'Autopista Norte con Calle 127', 'Bogotá', 'Cundinamarca', 'confirmed', 'high', 2, 1),
(2, 4, 'Atropello cerca a TransMilenio', 'Peatón atropellado en zona de paradero', 4.64860000, -74.08330000, 'Avenida Caracas con Calle 72', 'Bogotá', 'Cundinamarca', 'in_progress', 'critical', 1, 1),
(5, 3, 'Accidente de moto en vía a Chía', 'Motociclista caído en la vía', 4.86000000, -74.06000000, 'Autopista Norte Km 12', 'Chía', 'Cundinamarca', 'reported', 'high', 1, 1),
(1, 4, 'Choque múltiple en Calle 26', 'Tres vehículos involucrados', 4.63000000, -74.09000000, 'Calle 26 con Carrera 50', 'Bogotá', 'Cundinamarca', 'resolved', 'medium', 0, 0);

-- Sample alerts sent to 123
INSERT INTO alerts (incident_id, alert_code, sent_to, message, status, sent_at) VALUES
(1, 'ALT-2026-0001', '123', 'ALERTA ALERTIFY: Choque vehicular en Autopista Norte con Calle 127. 2 posibles afectados. Coordenadas: 4.735, -74.050', 'sent', NOW()),
(2, 'ALT-2026-0002', '123', 'ALERTA ALERTIFY CRÍTICA: Atropello en Avenida Caracas con Calle 72. 1 persona afectada. Coordenadas: 4.6486, -74.0833', 'acknowledged', NOW()),
(3, 'ALT-2026-0003', '123', 'ALERTA ALERTIFY: Accidente de moto en Autopista Norte Km 12 (Chía). 1 afectado. Coordenadas: 4.860, -74.060', 'pending', NULL);

-- Sample updates
INSERT INTO incident_updates (incident_id, user_id, old_status, new_status, note) VALUES
(1, 2, 'reported', 'confirmed', 'Confirmado por operador. Ambulancia en camino.'),
(2, 2, 'reported', 'in_progress', 'Unidad de emergencias asignada.'),
(4, 2, 'in_progress', 'resolved', 'Incidente cerrado. Vía despejada.');

-- Sample community reports
INSERT INTO community_reports (incident_id, user_id, comment) VALUES
(1, 4, 'Hay mucho tráfico. El camión está bloqueando el carril izquierdo.'),
(2, 3, 'La persona está consciente pero no se puede levantar.');
