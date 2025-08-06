cat > cmipro/backend/sql/threshold_configs.sql << 'EOF'
-- =====================================================
-- TABLA DE CONFIGURACIÓN DE UMBRALES - CMIPRO
-- Archivo: backend/sql/threshold_configs.sql
-- Versión: 2.0 (Umbrales actualizados)
-- =====================================================

-- Crear tabla de configuración de umbrales con 6 niveles
CREATE TABLE IF NOT EXISTS threshold_configs (
    station_id VARCHAR(10) NOT NULL,
    season ENUM('dry', 'rainy', 'peak_rainy') NOT NULL,
    normal_max DECIMAL(4,2) NOT NULL DEFAULT 2.0,
    low_max DECIMAL(4,2) NOT NULL DEFAULT 4.0,
    moderate_max DECIMAL(4,2) NOT NULL DEFAULT 6.0,
    high_max DECIMAL(4,2) NOT NULL DEFAULT 8.0,
    very_high_max DECIMAL(4,2) NOT NULL DEFAULT 12.0,
    critical_min DECIMAL(4,2) NOT NULL DEFAULT 12.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    
    PRIMARY KEY (station_id, season),
    
    -- Validaciones de integridad
    CONSTRAINT chk_thresholds_order CHECK (
        normal_max < low_max AND 
        low_max < moderate_max AND 
        moderate_max < high_max AND 
        high_max < very_high_max AND 
        very_high_max <= critical_min
    ),
    
    CONSTRAINT chk_positive_values CHECK (
        normal_max > 0 AND 
        low_max > 0 AND 
        moderate_max > 0 AND 
        high_max > 0 AND 
        very_high_max > 0 AND 
        critical_min > 0
    )
);

-- Índices para optimización
CREATE INDEX idx_threshold_station ON threshold_configs(station_id);
CREATE INDEX idx_threshold_active ON threshold_configs(active);
CREATE INDEX idx_threshold_season ON threshold_configs(season);
CREATE INDEX idx_threshold_updated ON threshold_configs(updated_at);

-- =====================================================
-- INSERTAR CONFIGURACIONES INICIALES
-- =====================================================

-- Estación CHIH3 - Río Ulúa (Chinda)
INSERT INTO threshold_configs (
    station_id, season, normal_max, low_max, moderate_max, 
    high_max, very_high_max, critical_min, notes
) VALUES 
-- Época seca (umbrales base)
('CHIH3', 'dry', 2.0, 4.0, 6.0, 8.0, 12.0, 12.0, 
 'Umbrales base para época seca - Río Ulúa en Chinda'),

-- Época lluviosa (reducción 10%)
('CHIH3', 'rainy', 1.8, 3.6, 5.4, 7.2, 10.8, 10.8, 
 'Umbrales ajustados para época lluviosa (-10%) - Río Ulúa en Chinda'),

-- Pico lluvioso (reducción 15%)
('CHIH3', 'peak_rainy', 1.7, 3.4, 5.1, 6.8, 10.2, 10.2, 
 'Umbrales ajustados para pico lluvioso (-15%) - Río Ulúa en Chinda');

-- Estación SANH3 - Río Ulúa (Santiago)
INSERT INTO threshold_configs (
    station_id, season, normal_max, low_max, moderate_max, 
    high_max, very_high_max, critical_min, notes
) VALUES 
-- Época seca
('SANH3', 'dry', 2.0, 4.0, 6.0, 8.0, 12.0, 12.0, 
 'Umbrales base para época seca - Río Ulúa en Santiago'),

-- Época lluviosa
('SANH3', 'rainy', 1.8, 3.6, 5.4, 7.2, 10.8, 10.8, 
 'Umbrales ajustados para época lluviosa (-10%) - Río Ulúa en Santiago'),

-- Pico lluvioso
('SANH3', 'peak_rainy', 1.7, 3.4, 5.1, 6.8, 10.2, 10.2, 
 'Umbrales ajustados para pico lluvioso (-15%) - Río Ulúa en Santiago');

-- Estación RCHH3 - Río Chamelecón (El Tablón)
INSERT INTO threshold_configs (
    station_id, season, normal_max, low_max, moderate_max, 
    high_max, very_high_max, critical_min, notes
) VALUES 
-- Época seca
('RCHH3', 'dry', 2.0, 4.0, 6.0, 8.0, 12.0, 12.0, 
 'Umbrales base para época seca - Río Chamelecón en El Tablón'),

-- Época lluviosa
('RCHH3', 'rainy', 1.8, 3.6, 5.4, 7.2, 10.8, 10.8, 
 'Umbrales ajustados para época lluviosa (-10%) - Río Chamelecón en El Tablón'),

-- Pico lluvioso
('RCHH3', 'peak_rainy', 1.7, 3.4, 5.1, 6.8, 10.2, 10.2, 
 'Umbrales ajustados para pico lluvioso (-15%) - Río Chamelecón en El Tablón');

-- =====================================================
-- TABLA DE HISTORIAL DE CAMBIOS EN UMBRALES
-- =====================================================

CREATE TABLE IF NOT EXISTS threshold_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    station_id VARCHAR(10) NOT NULL,
    season ENUM('dry', 'rainy', 'peak_rainy') NOT NULL,
    field_changed VARCHAR(50) NOT NULL,
    old_value DECIMAL(4,2),
    new_value DECIMAL(4,2),
    reason TEXT,
    changed_by VARCHAR(100),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_history_station (station_id),
    INDEX idx_history_date (changed_at),
    INDEX idx_history_field (field_changed)
);

-- =====================================================
-- TABLA DE POBLACIÓN EN RIESGO POR UMBRALES
-- =====================================================

CREATE TABLE IF NOT EXISTS population_risk_mapping (
    station_id VARCHAR(10) NOT NULL,
    threshold_level ENUM('normal', 'low', 'moderate', 'high', 'very_high', 'critical') NOT NULL,
    estimated_population INT NOT NULL DEFAULT 0,
    critical_infrastructure TEXT,
    affected_communities TEXT,
    evacuation_centers TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (station_id, threshold_level),
    INDEX idx_population_level (threshold_level)
);

-- Insertar mapeo de población en riesgo
INSERT INTO population_risk_mapping (
    station_id, threshold_level, estimated_population, 
    critical_infrastructure, affected_communities, evacuation_centers
) VALUES 
-- CHIH3 - Río Ulúa (Chinda)
('CHIH3', 'normal', 0, '', '', ''),
('CHIH3', 'low', 3000, 'Caminos rurales', 'Caseríos dispersos', 'Escuela Chinda'),
('CHIH3', 'moderate', 15000, 'Puente Chinda, CA-13', 'La Lima sectores sur', 'Centro comunal La Lima'),
('CHIH3', 'high', 75000, 'Aeropuerto, Hospital La Lima', 'La Lima centro, colonias periféricas', 'Estadio La Lima, Iglesias centrales'),
('CHIH3', 'very_high', 200000, 'Subestación eléctrica, Torres telecomunicaciones', 'La Lima completa, El Progreso sectores', 'Múltiples centros regionales'),
('CHIH3', 'critical', 400000, 'Infraestructura crítica regional', 'Evacuación masiva Valle de Sula', 'Refugios de emergencia nacional'),

-- SANH3 - Río Ulúa (Santiago)
('SANH3', 'normal', 0, '', '', ''),
('SANH3', 'low', 2000, 'Caminos locales', 'Comunidades rurales Santiago', 'Centro comunal Santiago'),
('SANH3', 'moderate', 10000, 'Puente Santiago', 'Barrios ribereños', 'Escuelas locales'),
('SANH3', 'high', 50000, 'Carretera principal', 'El Progreso sectores sur', 'Centro deportivo El Progreso'),
('SANH3', 'very_high', 150000, 'Hospital El Progreso', 'El Progreso mayoría sectores', 'Refugios municipales'),
('SANH3', 'critical', 300000, 'Infraestructura municipal crítica', 'Evacuación total El Progreso', 'Refugios regionales'),

-- RCHH3 - Río Chamelecón (El Tablón)
('RCHH3', 'normal', 0, '', '', ''),
('RCHH3', 'low', 5000, 'Puentes menores', 'Comunidades El Tablón', 'Centro El Tablón'),
('RCHH3', 'moderate', 20000, 'Carretera a Choloma', 'Villanueva sectores oeste', 'Polideportivo Villanueva'),
('RCHH3', 'high', 80000, 'Planta tratamiento agua', 'Villanueva centro, Choloma sectores', 'Múltiples centros Villanueva'),
('RCHH3', 'very_high', 180000, 'Zona industrial Choloma', 'Villanueva completa, Choloma mayoría', 'Refugios industriales, Escuelas'),
('RCHH3', 'critical', 350000, 'Parque industrial completo', 'Evacuación masiva zona industrial', 'Refugios de emergencia regional');

-- =====================================================
-- VISTA PARA CONSULTA RÁPIDA DE UMBRALES ACTUALES
-- =====================================================

CREATE OR REPLACE VIEW current_thresholds AS
SELECT 
    tc.station_id,
    tc.season,
    tc.normal_max,
    tc.low_max,
    tc.moderate_max,
    tc.high_max,
    tc.very_high_max,
    tc.critical_min,
    tc.updated_at
FROM threshold_configs tc
WHERE tc.active = TRUE
ORDER BY tc.station_id, 
         FIELD(tc.season, 'dry', 'rainy', 'peak_rainy');

-- =====================================================
-- TRIGGERS PARA AUDITORÍA DE CAMBIOS
-- =====================================================

DELIMITER //

CREATE TRIGGER trg_threshold_audit_update
AFTER UPDATE ON threshold_configs
FOR EACH ROW
BEGIN
    -- Auditar cambios en normal_max
    IF OLD.normal_max != NEW.normal_max THEN
        INSERT INTO threshold_history (station_id, season, field_changed, old_value, new_value, reason, changed_by)
        VALUES (NEW.station_id, NEW.season, 'normal_max', OLD.normal_max, NEW.normal_max, 'Updated via system', USER());
    END IF;
    
    -- Auditar cambios en low_max
    IF OLD.low_max != NEW.low_max THEN
        INSERT INTO threshold_history (station_id, season, field_changed, old_value, new_value, reason, changed_by)
        VALUES (NEW.station_id, NEW.season, 'low_max', OLD.low_max, NEW.low_max, 'Updated via system', USER());
    END IF;
    
    -- Auditar cambios en moderate_max
    IF OLD.moderate_max != NEW.moderate_max THEN
        INSERT INTO threshold_history (station_id, season, field_changed, old_value, new_value, reason, changed_by)
        VALUES (NEW.station_id, NEW.season, 'moderate_max', OLD.moderate_max, NEW.moderate_max, 'Updated via system', USER());
    END IF;
    
    -- Auditar cambios en high_max
    IF OLD.high_max != NEW.high_max THEN
        INSERT INTO threshold_history (station_id, season, field_changed, old_value, new_value, reason, changed_by)
        VALUES (NEW.station_id, NEW.season, 'high_max', OLD.high_max, NEW.high_max, 'Updated via system', USER());
    END IF;
    
    -- Auditar cambios en very_high_max
    IF OLD.very_high_max != NEW.very_high_max THEN
        INSERT INTO threshold_history (station_id, season, field_changed, old_value, new_value, reason, changed_by)
        VALUES (NEW.station_id, NEW.season, 'very_high_max', OLD.very_high_max, NEW.very_high_max, 'Updated via system', USER());
    END IF;
    
    -- Auditar cambios en critical_min
    IF OLD.critical_min != NEW.critical_min THEN
        INSERT INTO threshold_history (station_id, season, field_changed, old_value, new_value, reason, changed_by)
        VALUES (NEW.station_id, NEW.season, 'critical_min', OLD.critical_min, NEW.critical_min, 'Updated via system', USER());
    END IF;
END//

DELIMITER ;

-- =====================================================
-- PROCEDIMIENTOS PARA MANTENIMIENTO
-- =====================================================

DELIMITER //

-- Procedimiento para obtener umbrales por época automáticamente
CREATE PROCEDURE GetCurrentThresholds(IN p_station_id VARCHAR(10))
BEGIN
    DECLARE current_season VARCHAR(20);
    
    -- Determinar época actual basada en el mes
    SET current_season = CASE 
        WHEN MONTH(NOW()) IN (12, 1, 2, 3, 4, 5) THEN 'dry'
        WHEN MONTH(NOW()) IN (9, 10) THEN 'peak_rainy'
        ELSE 'rainy'
    END;
    
    -- Retornar umbrales para la época actual
    SELECT 
        station_id,
        season,
        normal_max,
        low_max,
        moderate_max,
        high_max,
        very_high_max,
        critical_min,
        current_season as detected_season
    FROM threshold_configs 
    WHERE station_id = p_station_id 
      AND season = current_season
      AND active = TRUE;
END//

-- Procedimiento para actualizar umbrales con validación
CREATE PROCEDURE UpdateThreshold(
    IN p_station_id VARCHAR(10),
    IN p_season VARCHAR(20),
    IN p_field VARCHAR(50),
    IN p_new_value DECIMAL(4,2),
    IN p_reason TEXT
)
BEGIN
    DECLARE current_value DECIMAL(4,2);
    DECLARE valid_update BOOLEAN DEFAULT FALSE;
    
    -- Validar que el campo existe y obtener valor actual
    CASE p_field
        WHEN 'normal_max' THEN
            SELECT normal_max INTO current_value FROM threshold_configs 
            WHERE station_id = p_station_id AND season = p_season;
            SET valid_update = (p_new_value > 0 AND p_new_value < 4.0);
            
        WHEN 'low_max' THEN
            SELECT low_max INTO current_value FROM threshold_configs 
            WHERE station_id = p_station_id AND season = p_season;
            SET valid_update = (p_new_value > 1.0 AND p_new_value < 6.0);
            
        WHEN 'moderate_max' THEN
            SELECT moderate_max INTO current_value FROM threshold_configs 
            WHERE station_id = p_station_id AND season = p_season;
            SET valid_update = (p_new_value > 2.0 AND p_new_value < 8.0);
            
        WHEN 'high_max' THEN
            SELECT high_max INTO current_value FROM threshold_configs 
            WHERE station_id = p_station_id AND season = p_season;
            SET valid_update = (p_new_value > 4.0 AND p_new_value < 10.0);
            
        WHEN 'very_high_max' THEN
            SELECT very_high_max INTO current_value FROM threshold_configs 
            WHERE station_id = p_station_id AND season = p_season;
            SET valid_update = (p_new_value > 6.0 AND p_new_value < 15.0);
            
        WHEN 'critical_min' THEN
            SELECT critical_min INTO current_value FROM threshold_configs 
            WHERE station_id = p_station_id AND season = p_season;
            SET valid_update = (p_new_value > 8.0 AND p_new_value < 20.0);
            
        ELSE
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Campo inválido para actualización';
    END CASE;
    
    -- Ejecutar actualización si es válida
    IF valid_update THEN
        -- Registrar en historial antes de actualizar
        INSERT INTO threshold_history (station_id, season, field_changed, old_value, new_value, reason, changed_by)
        VALUES (p_station_id, p_season, p_field, current_value, p_new_value, p_reason, USER());
        
        -- Ejecutar actualización
        CASE p_field
            WHEN 'normal_max' THEN
                UPDATE threshold_configs SET normal_max = p_new_value 
                WHERE station_id = p_station_id AND season = p_season;
            WHEN 'low_max' THEN
                UPDATE threshold_configs SET low_max = p_new_value 
                WHERE station_id = p_station_id AND season = p_season;
            WHEN 'moderate_max' THEN
                UPDATE threshold_configs SET moderate_max = p_new_value 
                WHERE station_id = p_station_id AND season = p_season;
            WHEN 'high_max' THEN
                UPDATE threshold_configs SET high_max = p_new_value 
                WHERE station_id = p_station_id AND season = p_season;
            WHEN 'very_high_max' THEN
                UPDATE threshold_configs SET very_high_max = p_new_value 
                WHERE station_id = p_station_id AND season = p_season;
            WHEN 'critical_min' THEN
                UPDATE threshold_configs SET critical_min = p_new_value 
                WHERE station_id = p_station_id AND season = p_season;
        END CASE;
        
        SELECT 'SUCCESS' as result, 'Umbral actualizado correctamente' as message;
    ELSE
        SELECT 'ERROR' as result, 'Valor fuera del rango válido' as message;
    END IF;
END//

DELIMITER ;

-- =====================================================
-- CONSULTAS DE VALIDACIÓN Y TESTING
-- =====================================================

-- Verificar integridad de umbrales
SELECT 
    station_id,
    season,
    CASE 
        WHEN normal_max >= low_max THEN 'ERROR: normal_max >= low_max'
        WHEN low_max >= moderate_max THEN 'ERROR: low_max >= moderate_max'
        WHEN moderate_max >= high_max THEN 'ERROR: moderate_max >= high_max'
        WHEN high_max >= very_high_max THEN 'ERROR: high_max >= very_high_max'
        WHEN very_high_max > critical_min THEN 'ERROR: very_high_max > critical_min'
        ELSE 'OK'
    END as validation_status,
    normal_max, low_max, moderate_max, high_max, very_high_max, critical_min
FROM threshold_configs
WHERE active = TRUE
ORDER BY station_id, season;

-- =====================================================
-- COMENTARIOS Y DOCUMENTACIÓN
-- =====================================================

-- Agregar comentarios a las tablas
ALTER TABLE threshold_configs COMMENT = 'Configuración de umbrales de riesgo por estación y época del año';
ALTER TABLE threshold_history COMMENT = 'Historial de cambios en umbrales para auditoría';
ALTER TABLE population_risk_mapping COMMENT = 'Mapeo de población en riesgo por nivel de umbral';

-- Comentarios en columnas
ALTER TABLE threshold_configs 
    MODIFY COLUMN normal_max DECIMAL(4,2) COMMENT 'Umbral máximo para nivel normal (metros)',
    MODIFY COLUMN low_max DECIMAL(4,2) COMMENT 'Umbral máximo para nivel bajo (metros)',
    MODIFY COLUMN moderate_max DECIMAL(4,2) COMMENT 'Umbral máximo para nivel moderado (metros)',
    MODIFY COLUMN high_max DECIMAL(4,2) COMMENT 'Umbral máximo para nivel alto (metros)',
    MODIFY COLUMN very_high_max DECIMAL(4,2) COMMENT 'Umbral máximo para nivel muy alto (metros)',
    MODIFY COLUMN critical_min DECIMAL(4,2) COMMENT 'Umbral mínimo para nivel crítico (metros)';

-- =====================================================
-- EJEMPLOS DE USO
-- =====================================================

/*
-- Ejemplos de consultas para testing:

-- 1. Obtener umbrales actuales para una estación
CALL GetCurrentThresholds('CHIH3');

-- 2. Actualizar un umbral
CALL UpdateThreshold('CHIH3', 'dry', 'normal_max', 2.1, 'Ajuste basado en evento reciente');

-- 3. Ver todos los umbrales formateados
SELECT 
    station_id,
    season as epoca,
    CONCAT('0-', normal_max, 'm') as normal,
    CONCAT(normal_max, '-', low_max, 'm') as bajo,
    CONCAT(low_max, '-', moderate_max, 'm') as moderado,
    CONCAT(moderate_max, '-', high_max, 'm') as alto,
    CONCAT(high_max, '-', very_high_max, 'm') as muy_alto,
    CONCAT('>', critical_min, 'm') as critico
FROM threshold_configs
WHERE active = TRUE
ORDER BY station_id, FIELD(season, 'dry', 'rainy', 'peak_rainy');

-- 4. Ver historial de cambios
SELECT * FROM threshold_history ORDER BY changed_at DESC LIMIT 10;

-- 5. Ver población en riesgo por estación
SELECT 
    station_id,
    threshold_level,
    estimated_population,
    affected_communities
FROM population_risk_mapping
WHERE estimated_population > 0
ORDER BY station_id, FIELD(threshold_level, 'low', 'moderate', 'high', 'very_high', 'critical');
*/
EOF