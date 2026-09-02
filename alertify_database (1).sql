-- ============================================================
-- ALERTIFY - COMPLETE DATABASE
-- Compatible with XAMPP (MySQL / MariaDB)
-- Ready for full application development
-- ============================================================

CREATE DATABASE IF NOT EXISTS alertify
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE alertify;

-- ============================================================
-- 1. USERS & AUTHENTICATION
-- ============================================================

CREATE TABLE users (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name       VARCHAR(120) NOT NULL,
    email           VARCHAR(150) NOT NULL UNIQUE,
    phone           VARCHAR(20) DEFAULT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    role            ENUM('citizen', 'operator', 'admin', 'emergency') NOT NULL DEFAULT 'citizen',
    document_type   ENUM('CC', 'CE', 'TI', 'PAS') DEFAULT 'CC',
    document_number VARCHAR(30) DEFAULT NULL,
    profile_photo   VARCHAR(255) DEFAULT NULL,
    is_active       TINYINT(1) NOT NULL DEFAULT 1,
    last_login      DATETIME DEFAULT NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_role (role),
    INDEX idx_email (email)
) ENGINE=InnoDB;

CREATE TABLE user_sessions (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         INT UNSIGNED NOT NULL,
    token           VARCHAR(255) NOT NULL UNIQUE,
    device_info     VARCHAR(255) DEFAULT NULL,
    ip_address      VARCHAR(45) DEFAULT NULL,
    expires_at      DATETIME NOT NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_session_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE device_tokens (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         INT UNSIGNED NOT NULL,
    token           VARCHAR(255) NOT NULL,
    platform        ENUM('android', 'ios', 'web') NOT NULL DEFAULT 'android',
    is_active       TINYINT(1) NOT NULL DEFAULT 1,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_device_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uk_user_token (user_id, token)
) ENGINE=InnoDB;

-- ============================================================
-- 2. CATALOGS
-- ============================================================

CREATE TABLE accident_types (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(80) NOT NULL UNIQUE,
    description VARCHAR(255) DEFAULT NULL,
    severity    ENUM('low', 'medium', 'high', 'critical') NOT NULL DEFAULT 'medium',
    icon        VARCHAR(50) DEFAULT NULL,
    color       VARCHAR(20) DEFAULT '#FFD60A',
    is_active   TINYINT(1) NOT NULL DEFAULT 1,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE departments (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    code        VARCHAR(10) DEFAULT NULL
) ENGINE=InnoDB;

CREATE TABLE cities (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    department_id   INT UNSIGNED NOT NULL,
    name            VARCHAR(100) NOT NULL,
    CONSTRAINT fk_city_department FOREIGN KEY (department_id) REFERENCES departments(id),
    UNIQUE KEY uk_city_dept (department_id, name)
) ENGINE=InnoDB;

-- ============================================================
-- 3. INCIDENTS (CORE)
-- ============================================================

CREATE TABLE incidents (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    public_code         VARCHAR(20) NOT NULL UNIQUE,
    accident_type_id    INT UNSIGNED NOT NULL,
    reported_by         INT UNSIGNED DEFAULT NULL,
    title               VARCHAR(150) NOT NULL,
    description         TEXT,
    latitude            DECIMAL(10, 8) NOT NULL,
    longitude           DECIMAL(11, 8) NOT NULL,
    address             VARCHAR(255) DEFAULT NULL,
    city_id             INT UNSIGNED DEFAULT NULL,
    status              ENUM('reported', 'confirmed', 'in_progress', 'resolved', 'false_alarm', 'cancelled') 
                        NOT NULL DEFAULT 'reported',
    severity            ENUM('low', 'medium', 'high', 'critical') NOT NULL DEFAULT 'medium',
    victims_count       INT UNSIGNED DEFAULT 0,
    injured_count       INT UNSIGNED DEFAULT 0,
    deceased_count      INT UNSIGNED DEFAULT 0,
    is_live             TINYINT(1) NOT NULL DEFAULT 1,
    is_verified         TINYINT(1) NOT NULL DEFAULT 0,
    weather_conditions  VARCHAR(100) DEFAULT NULL,
    road_conditions     VARCHAR(100) DEFAULT NULL,
    reported_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    confirmed_at        DATETIME DEFAULT NULL,
    resolved_at         DATETIME DEFAULT NULL,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_incident_type FOREIGN KEY (accident_type_id) REFERENCES accident_types(id),
    CONSTRAINT fk_incident_user FOREIGN KEY (reported_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_incident_city FOREIGN KEY (city_id) REFERENCES cities(id) ON DELETE SET NULL,

    INDEX idx_status (status),
    INDEX idx_live (is_live),
    INDEX idx_severity (severity),
    INDEX idx_location (latitude, longitude),
    INDEX idx_reported_at (reported_at)
) ENGINE=InnoDB;

CREATE TABLE incident_photos (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    incident_id     INT UNSIGNED NOT NULL,
    user_id         INT UNSIGNED DEFAULT NULL,
    photo_url       VARCHAR(255) NOT NULL,
    caption         VARCHAR(255) DEFAULT NULL,
    is_main         TINYINT(1) NOT NULL DEFAULT 0,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_photo_incident FOREIGN KEY (incident_id) REFERENCES incidents(id) ON DELETE CASCADE,
    CONSTRAINT fk_photo_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE incident_vehicles (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    incident_id     INT UNSIGNED NOT NULL,
    vehicle_type    ENUM('car', 'motorcycle', 'truck', 'bus', 'bicycle', 'other') NOT NULL DEFAULT 'car',
    plate           VARCHAR(15) DEFAULT NULL,
    brand           VARCHAR(50) DEFAULT NULL,
    color           VARCHAR(30) DEFAULT NULL,
    model_year      YEAR DEFAULT NULL,
    damage_level    ENUM('none', 'minor', 'moderate', 'severe', 'total') DEFAULT 'moderate',
    occupants       INT UNSIGNED DEFAULT 1,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_vehicle_incident FOREIGN KEY (incident_id) REFERENCES incidents(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE incident_updates (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    incident_id     INT UNSIGNED NOT NULL,
    user_id         INT UNSIGNED DEFAULT NULL,
    old_status      VARCHAR(30) DEFAULT NULL,
    new_status      VARCHAR(30) NOT NULL,
    note            TEXT,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_update_incident FOREIGN KEY (incident_id) REFERENCES incidents(id) ON DELETE CASCADE,
    CONSTRAINT fk_update_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE community_reports (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    incident_id     INT UNSIGNED NOT NULL,
    user_id         INT UNSIGNED DEFAULT NULL,
    comment         TEXT NOT NULL,
    photo_url       VARCHAR(255) DEFAULT NULL,
    is_anonymous    TINYINT(1) NOT NULL DEFAULT 0,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_community_incident FOREIGN KEY (incident_id) REFERENCES incidents(id) ON DELETE CASCADE,
    CONSTRAINT fk_community_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================
-- 4. ALERTS TO 123
-- ============================================================

CREATE TABLE alerts (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    incident_id     INT UNSIGNED NOT NULL,
    alert_code      VARCHAR(30) NOT NULL UNIQUE,
    sent_to         VARCHAR(20) NOT NULL DEFAULT '123',
    channel         ENUM('api', 'sms', 'call', 'radio', 'system') NOT NULL DEFAULT 'api',
    message         TEXT NOT NULL,
    status          ENUM('pending', 'sent', 'acknowledged', 'failed', 'cancelled') NOT NULL DEFAULT 'pending',
    priority        ENUM('normal', 'high', 'urgent') NOT NULL DEFAULT 'high',
    response_notes  TEXT DEFAULT NULL,
    sent_at         DATETIME DEFAULT NULL,
    acknowledged_at DATETIME DEFAULT NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_alert_incident FOREIGN KEY (incident_id) REFERENCES incidents(id) ON DELETE CASCADE,
    INDEX idx_alert_status (status)
) ENGINE=InnoDB;

CREATE TABLE alert_logs (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    alert_id        INT UNSIGNED NOT NULL,
    event           VARCHAR(50) NOT NULL,
    details         TEXT,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_log_alert FOREIGN KEY (alert_id) REFERENCES alerts(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 5. EMERGENCY UNITS & ASSIGNMENTS
-- ============================================================

CREATE TABLE emergency_units (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    unit_code       VARCHAR(20) NOT NULL UNIQUE,
    unit_type       ENUM('ambulance', 'police', 'fire', 'transit', 'other') NOT NULL,
    name            VARCHAR(100) NOT NULL,
    phone           VARCHAR(20) DEFAULT NULL,
    current_lat     DECIMAL(10, 8) DEFAULT NULL,
    current_lng     DECIMAL(11, 8) DEFAULT NULL,
    status          ENUM('available', 'busy', 'offline', 'maintenance') NOT NULL DEFAULT 'available',
    city_id         INT UNSIGNED DEFAULT NULL,
    is_active       TINYINT(1) NOT NULL DEFAULT 1,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_unit_city FOREIGN KEY (city_id) REFERENCES cities(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE unit_assignments (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    incident_id     INT UNSIGNED NOT NULL,
    unit_id         INT UNSIGNED NOT NULL,
    assigned_by     INT UNSIGNED DEFAULT NULL,
    status          ENUM('assigned', 'en_route', 'on_scene', 'finished', 'cancelled') NOT NULL DEFAULT 'assigned',
    assigned_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    arrived_at      DATETIME DEFAULT NULL,
    finished_at     DATETIME DEFAULT NULL,
    notes           TEXT,
    CONSTRAINT fk_assign_incident FOREIGN KEY (incident_id) REFERENCES incidents(id) ON DELETE CASCADE,
    CONSTRAINT fk_assign_unit FOREIGN KEY (unit_id) REFERENCES emergency_units(id),
    CONSTRAINT fk_assign_user FOREIGN KEY (assigned_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================
-- 6. NOTIFICATIONS
-- ============================================================

CREATE TABLE notifications (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         INT UNSIGNED NOT NULL,
    title           VARCHAR(150) NOT NULL,
    body            TEXT NOT NULL,
    type            ENUM('incident', 'alert', 'system', 'assignment') NOT NULL DEFAULT 'system',
    reference_id    INT UNSIGNED DEFAULT NULL,
    is_read         TINYINT(1) NOT NULL DEFAULT 0,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notif_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_read (user_id, is_read)
) ENGINE=InnoDB;

-- ============================================================
-- 7. ZONES & COVERAGE
-- ============================================================

CREATE TABLE coverage_zones (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    city_id         INT UNSIGNED DEFAULT NULL,
    description     TEXT,
    geojson         JSON DEFAULT NULL,
    is_active       TINYINT(1) NOT NULL DEFAULT 1,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_zone_city FOREIGN KEY (city_id) REFERENCES cities(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================
-- 8. SYSTEM & AUDIT
-- ============================================================

CREATE TABLE system_settings (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    setting_key     VARCHAR(80) NOT NULL UNIQUE,
    setting_value   TEXT,
    description     VARCHAR(255) DEFAULT NULL,
    updated_at      DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE audit_logs (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         INT UNSIGNED DEFAULT NULL,
    action          VARCHAR(80) NOT NULL,
    table_name      VARCHAR(50) DEFAULT NULL,
    record_id       INT UNSIGNED DEFAULT NULL,
    old_values      JSON DEFAULT NULL,
    new_values      JSON DEFAULT NULL,
    ip_address      VARCHAR(45) DEFAULT NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_audit_action (action),
    INDEX idx_audit_date (created_at)
) ENGINE=InnoDB;

-- ============================================================
-- SAMPLE DATA
-- ============================================================

INSERT INTO departments (name, code) VALUES
('Cundinamarca', '25'),
('Antioquia', '05'),
('Valle del Cauca', '76'),
('Atlántico', '08');

INSERT INTO cities (department_id, name) VALUES
(1, 'Bogotá'),
(1, 'Chía'),
(1, 'Soacha'),
(2, 'Medellín'),
(3, 'Cali'),
(4, 'Barranquilla');

INSERT INTO users (full_name, email, phone, password_hash, role, document_number) VALUES
('Admin Alertify', 'admin@alertify.co', '3001234567', '$2y$10$examplehashadmin123', 'admin', '10000001'),
('Operador Central', 'operador@alertify.co', '3009876543', '$2y$10$examplehashoperator', 'operator', '10000002'),
('Juan Pérez', 'juan.perez@email.com', '3105551234', '$2y$10$examplehashcitizen1', 'citizen', '10000003'),
('María Gómez', 'maria.gomez@email.com', '3204449876', '$2y$10$examplehashcitizen2', 'citizen', '10000004'),
('Unidad Emergencias', 'emergencias@alertify.co', '6011234567', '$2y$10$examplehashemergency', 'emergency', '10000005');

INSERT INTO accident_types (name, description, severity, icon, color) VALUES
('Choque vehicular', 'Colisión entre dos o más vehículos', 'high', 'car-crash', '#FF6B00'),
('Atropello', 'Persona atropellada por un vehículo', 'critical', 'pedestrian', '#EF4444'),
('Volcamiento', 'Vehículo que se volcó', 'high', 'rollover', '#F59E0B'),
('Incendio vehicular', 'Vehículo en llamas', 'critical', 'fire', '#DC2626'),
('Accidente de moto', 'Accidente que involucra motocicletas', 'high', 'motorcycle', '#F97316'),
('Caída de árbol / objeto', 'Obstáculo en la vía', 'medium', 'obstacle', '#84CC16'),
('Derrumbe / Deslizamiento', 'Material que bloquea la vía', 'high', 'landslide', '#A855F7'),
('Otro', 'Otro tipo de incidente', 'medium', 'other', '#64748B');

INSERT INTO emergency_units (unit_code, unit_type, name, phone, status, city_id) VALUES
('AMB-01', 'ambulance', 'Ambulancia Norte 1', '3101112233', 'available', 1),
('AMB-02', 'ambulance', 'Ambulancia Centro 2', '3101112244', 'busy', 1),
('POL-15', 'police', 'Patrulla Policía 15', '3102223344', 'available', 1),
('BOM-03', 'fire', 'Bomberos Estación 3', '3103334455', 'available', 1),
('TRA-07', 'transit', 'Agentes de Tránsito 07', '3104445566', 'available', 1);

INSERT INTO incidents 
(public_code, accident_type_id, reported_by, title, description, latitude, longitude, address, city_id, status, severity, victims_count, injured_count, is_live, is_verified) 
VALUES
('INC-2026-0001', 1, 3, 'Choque en Autopista Norte', 'Colisión entre carro y camión en el carril central', 4.73500000, -74.05000000, 'Autopista Norte con Calle 127', 1, 'confirmed', 'high', 2, 2, 1, 1),
('INC-2026-0002', 2, 4, 'Atropello cerca a TransMilenio', 'Peatón atropellado en zona de paradero', 4.64860000, -74.08330000, 'Avenida Caracas con Calle 72', 1, 'in_progress', 'critical', 1, 1, 1, 1),
('INC-2026-0003', 5, 3, 'Accidente de moto en vía a Chía', 'Motociclista caído en la vía', 4.86000000, -74.06000000, 'Autopista Norte Km 12', 2, 'reported', 'high', 1, 1, 1, 0),
('INC-2026-0004', 1, 4, 'Choque múltiple en Calle 26', 'Tres vehículos involucrados', 4.63000000, -74.09000000, 'Calle 26 con Carrera 50', 1, 'resolved', 'medium', 0, 0, 0, 1);

INSERT INTO incident_vehicles (incident_id, vehicle_type, plate, brand, color, damage_level, occupants) VALUES
(1, 'car', 'ABC123', 'Mazda', 'Rojo', 'moderate', 2),
(1, 'truck', 'XYZ987', 'Kenworth', 'Blanco', 'minor', 1),
(2, 'bus', 'TM-045', 'TransMilenio', 'Rojo', 'none', 1),
(3, 'motorcycle', 'MOT456', 'Yamaha', 'Negro', 'severe', 1);

INSERT INTO alerts (incident_id, alert_code, sent_to, channel, message, status, priority, sent_at, acknowledged_at) VALUES
(1, 'ALT-2026-0001', '123', 'api', 'ALERTA ALERTIFY: Choque vehicular en Autopista Norte con Calle 127. 2 posibles afectados. Coordenadas: 4.735, -74.050', 'sent', 'high', NOW(), NULL),
(2, 'ALT-2026-0002', '123', 'api', 'ALERTA ALERTIFY CRÍTICA: Atropello en Avenida Caracas con Calle 72. 1 persona afectada. Coordenadas: 4.6486, -74.0833', 'acknowledged', 'urgent', NOW(), NOW()),
(3, 'ALT-2026-0003', '123', 'api', 'ALERTA ALERTIFY: Accidente de moto en Autopista Norte Km 12 (Chía). 1 afectado. Coordenadas: 4.860, -74.060', 'pending', 'high', NULL, NULL);

INSERT INTO unit_assignments (incident_id, unit_id, assigned_by, status, assigned_at) VALUES
(1, 1, 2, 'en_route', NOW()),
(2, 2, 2, 'on_scene', NOW()),
(2, 3, 2, 'en_route', NOW());

INSERT INTO incident_updates (incident_id, user_id, old_status, new_status, note) VALUES
(1, 2, 'reported', 'confirmed', 'Confirmado por operador. Ambulancia en camino.'),
(2, 2, 'reported', 'in_progress', 'Unidad de emergencias asignada y en el lugar.'),
(4, 2, 'in_progress', 'resolved', 'Incidente cerrado. Vía despejada.');

INSERT INTO community_reports (incident_id, user_id, comment) VALUES
(1, 4, 'Hay mucho tráfico. El camión está bloqueando el carril izquierdo.'),
(2, 3, 'La persona está consciente pero no se puede levantar.');

INSERT INTO system_settings (setting_key, setting_value, description) VALUES
('app_name', 'Alertify', 'Nombre de la aplicación'),
('emergency_number', '123', 'Número de emergencia nacional'),
('auto_alert_enabled', '1', 'Enviar alerta automática al 123'),
('default_city', 'Bogotá', 'Ciudad por defecto'),
('map_default_lat', '4.7110', 'Latitud por defecto del mapa'),
('map_default_lng', '-74.0721', 'Longitud por defecto del mapa'),
('alert_retry_minutes', '5', 'Minutos para reintentar alerta fallida');

INSERT INTO notifications (user_id, title, body, type, reference_id) VALUES
(3, 'Tu reporte fue recibido', 'El incidente INC-2026-0001 ha sido registrado correctamente.', 'incident', 1),
(2, 'Nueva alerta crítica', 'Atropello reportado en Avenida Caracas. Requiere atención inmediata.', 'alert', 2);
-- ============================================================
-- ROLES
-- ============================================================

CREATE TABLE roles (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255) DEFAULT NULL,
    is_active   TINYINT(1) NOT NULL DEFAULT 1,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO roles (name, description) VALUES
('citizen',   'Ciudadano que reporta incidentes'),
('operator',  'Operador de la central de monitoreo'),
('admin',     'Administrador del sistema'),
('emergency', 'Personal de unidades de emergencia');
-- ============================================================
-- USO DE LA APP (primer acceso / ya utilizó la app)
-- ============================================================

CREATE TABLE user_app_usage (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         INT UNSIGNED NOT NULL,
    first_used_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_used_at    DATETIME DEFAULT NULL,
    usage_count     INT UNSIGNED NOT NULL DEFAULT 1,
    platform        ENUM('android', 'ios', 'web') DEFAULT NULL,
    app_version     VARCHAR(20) DEFAULT NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_usage_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uk_user_usage (user_id)
) ENGINE=InnoDB;
