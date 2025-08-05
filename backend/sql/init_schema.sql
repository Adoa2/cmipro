-- CMIPRO Database Schema - TimescaleDB
-- Creado: Lunes Semana 1
-- Versión: 1.0

-- Habilitar extensión TimescaleDB
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- =============================================================================
-- TABLA DE ESTACIONES HIDROLÓGICAS
-- =============================================================================

CREATE TABLE stations (
    id VARCHAR(10) PRIMARY KEY,               -- CHIH3, SANH3, RCHH3
    name VARCHAR(100) NOT NULL,               -- Chinda, Santiago, El Tablón
    river VARCHAR(50) NOT NULL,               -- Ulúa, Chamelecón
    
    -- Ubicación geográfica
    latitude DECIMAL(9,6) NOT NULL,
    longitude DECIMAL(9,6) NOT NULL,
    elevation DECIMAL(6,1),                   -- Elevación en metros
    
    -- Identificadores externos
    nesdis_id VARCHAR(20) UNIQUE,             -- ID NESDIS de NOAA
    usgs_id VARCHAR(20),                      -- ID alternativo USGS
    
    -- Umbrales de riesgo (en metros)
    threshold_low DECIMAL(6,3) DEFAULT 1.5,
    threshold_medium DECIMAL(6,3) DEFAULT 3.0,
    threshold_high DECIMAL(6,3) DEFAULT 4.5,
    threshold_critical DECIMAL(6,3) DEFAULT 6.0,
    
    -- Estado operacional
    status VARCHAR(20) DEFAULT 'active',      -- active, inactive, maintenance
    last_reading TIMESTAMPTZ,
    
    -- Metadatos
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- TABLA PRINCIPAL DE LECTURAS HIDROLÓGICAS (HYPERTABLE)
-- =============================================================================

CREATE TABLE hydrologic_readings (
    -- Identificadores
    id BIGSERIAL PRIMARY KEY,
    station_id VARCHAR(10) NOT NULL,           -- CHIH3, SANH3, RCHH3
    nesdis_id VARCHAR(20) NOT NULL,            -- 50401A48, etc.
    
    -- Timestamp (columna particionada por TimescaleDB)
    timestamp TIMESTAMPTZ NOT NULL,
    
    -- Datos hidrológicos principales
    level DECIMAL(6,3),                        -- Nivel en metros
    flow_rate DECIMAL(8,2),                    -- Caudal en m³/s
    stage_height DECIMAL(6,3),                 -- Altura de etapa
    
    -- Datos meteorológicos relacionados
    precipitation DECIMAL(5,2),                -- Precipitación en mm
    temperature DECIMAL(4,1),                  -- Temperatura en °C
    humidity DECIMAL(4,1),                     -- Humedad relativa %
    
    -- Metadatos
    risk_level VARCHAR(20) DEFAULT 'normal',   -- normal, low, medium, high, critical
    data_quality VARCHAR(20) DEFAULT 'good',   -- good, fair, poor, missing
    data_source VARCHAR(50) DEFAULT 'NOAA_HADS', -- NOAA_HADS, USGS, manual
    
    -- Timestamps de procesamiento
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT unique_station_timestamp UNIQUE (station_id, timestamp)
);

-- Convertir a hypertable (TimescaleDB)
SELECT create_hypertable('hydrologic_readings', 'timestamp', chunk_time_interval => INTERVAL '1 day');

-- =============================================================================
-- TABLA DE ALERTAS
-- =============================================================================

CREATE TABLE alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    station_id VARCHAR(10) NOT NULL REFERENCES stations(id),
    
    -- Datos de la alerta
    severity VARCHAR(20) NOT NULL,            -- low, medium, high, critical
    level DECIMAL(6,3) NOT NULL,              -- Nivel que disparó la alerta
    threshold DECIMAL(6,3) NOT NULL,          -- Umbral superado
    message TEXT NOT NULL,
    
    -- Estados
    is_active BOOLEAN DEFAULT true,
    acknowledged_by UUID,                     -- user_id que reconoció
    acknowledged_at TIMESTAMPTZ,
    
    -- Predicciones
    estimated_peak TIMESTAMPTZ,               -- Pico estimado
    estimated_duration INTERVAL,             -- Duración estimada
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

-- =============================================================================
-- TABLA DE USUARIOS
-- =============================================================================

CREATE TABLE users (
    id UUID PRIMARY KEY,                      -- Firebase UID
    email VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(100),
    
    -- Suscripción Stripe
    stripe_customer_id VARCHAR(100) UNIQUE,
    subscription_status VARCHAR(20) DEFAULT 'inactive', -- active, inactive, canceled, past_due
    subscription_plan VARCHAR(50),            -- monthly, annual
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    
    -- Preferencias de notificación
    notifications_email BOOLEAN DEFAULT true,
    notifications_push BOOLEAN DEFAULT true,
    notifications_sound BOOLEAN DEFAULT true,
    
    -- Umbrales personalizados por estación (JSON)
    alert_preferences JSONB DEFAULT '{}',     -- {"CHIH3": "medium", "SANH3": "high"}
    
    -- Metadatos
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_login TIMESTAMPTZ
);

-- =============================================================================
-- TABLA DE NOTICIAS IA (FASE 2)
-- =============================================================================

CREATE TABLE ai_news (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Contenido
    title VARCHAR(200) NOT NULL,
    summary TEXT NOT NULL,
    full_content TEXT,
    category VARCHAR(50) NOT NULL,            -- weather, seismic, flooding
    
    -- Metadatos IA
    ai_model VARCHAR(50) DEFAULT 'gpt-4',
    ai_confidence DECIMAL(3,2),               -- 0.00 - 1.00
    sources JSONB,                            -- ["NOAA", "AccuWeather RSS"]
    
    -- Estados
    status VARCHAR(20) DEFAULT 'published',   -- draft, published, archived
    priority INTEGER DEFAULT 0,              -- 0=normal, 1=high, 2=urgent
    
    -- Timestamps
    generated_at TIMESTAMPTZ DEFAULT NOW(),
    published_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ                    -- Para noticias temporales
);

-- =============================================================================
-- ÍNDICES PARA OPTIMIZACIÓN DE CONSULTAS
-- =============================================================================

-- Índices para hydrologic_readings
CREATE INDEX idx_station_timestamp ON hydrologic_readings (station_id, timestamp DESC);
CREATE INDEX idx_risk_level ON hydrologic_readings (risk_level, timestamp DESC) WHERE risk_level != 'normal';
CREATE INDEX idx_created_at ON hydrologic_readings (created_at DESC);

-- Índices para alerts
CREATE INDEX idx_alerts_active ON alerts (station_id, is_active, created_at DESC);
CREATE INDEX idx_alerts_severity ON alerts (severity, created_at DESC) WHERE is_active = true;

-- Índices para users
CREATE INDEX idx_users_subscription ON users (subscription_status, current_period_end);
CREATE INDEX idx_users_stripe ON users (stripe_customer_id);

-- Índices para ai_news
CREATE INDEX idx_news_category ON ai_news (category, published_at DESC) WHERE status = 'published';
CREATE INDEX idx_news_priority ON ai_news (priority DESC, published_at DESC) WHERE status = 'published';

-- =============================================================================
-- INSERTAR DATOS INICIALES
-- =============================================================================

-- Estaciones iniciales del Valle de Sula
INSERT INTO stations (id, name, river, latitude, longitude, elevation, nesdis_id, threshold_low, threshold_medium, threshold_high, threshold_critical, description) VALUES
('CHIH3', 'Chinda', 'Ulúa', 15.3847, -87.9547, 45.0, '50401A48', 1.5, 3.0, 4.5, 6.0, 'Estación hidrológica en río Ulúa, sector Chinda. Monitorea nivel y caudal crítico para El Progreso y La Lima.'),
('SANH3', 'Santiago', 'Ulúa', 15.2941, -87.9234, 38.0, '50402FD2', 1.2, 2.5, 4.0, 5.5, 'Estación hidrológica en río Ulúa, sector Santiago. Punto de control aguas arriba de la confluencia.'),
('RCHH3', 'El Tablón', 'Chamelecón', 15.4234, -88.0123, 52.0, '50403CA4', 1.8, 3.5, 5.0, 7.0, 'Estación hidrológica en río Chamelecón, sector El Tablón. Monitorea crecidas hacia San Pedro Sula.');

-- =============================================================================
-- FUNCIONES SQL AUXILIARES
-- =============================================================================

-- Función para obtener niveles actuales de todas las estaciones
CREATE OR REPLACE FUNCTION get_current_levels()
RETURNS TABLE (
    station_id VARCHAR(10),
    current_level DECIMAL(6,3),
    risk_level VARCHAR(20),
    last_reading TIMESTAMPTZ
) AS $
BEGIN
    RETURN QUERY
    SELECT DISTINCT ON (hr.station_id)
        hr.station_id,
        hr.level,
        hr.risk_level,
        hr.timestamp
    FROM hydrologic_readings hr
    ORDER BY hr.station_id, hr.timestamp DESC;
END;
$ LANGUAGE plpgsql;

-- Función para calcular nivel de riesgo basado en umbrales
CREATE OR REPLACE FUNCTION calculate_risk_level(
    station_id_param VARCHAR(10),
    level_param DECIMAL(6,3)
) RETURNS VARCHAR(20) AS $
DECLARE
    station_record RECORD;
    risk VARCHAR(20) := 'normal';
BEGIN
    SELECT * INTO station_record FROM stations WHERE id = station_id_param;
    
    IF station_record IS NULL THEN
        RETURN 'unknown';
    END IF;
    
    IF level_param >= station_record.threshold_critical THEN
        risk := 'critical';
    ELSIF level_param >= station_record.threshold_high THEN
        risk := 'high';
    ELSIF level_param >= station_record.threshold_medium THEN
        risk := 'medium';
    ELSIF level_param >= station_record.threshold_low THEN
        risk := 'low';
    END IF;
    
    RETURN risk;
END;
$ LANGUAGE plpgsql;

-- Función para actualizar el timestamp de última lectura en stations
CREATE OR REPLACE FUNCTION update_station_last_reading()
RETURNS TRIGGER AS $
BEGIN
    UPDATE stations 
    SET last_reading = NEW.timestamp,
        updated_at = NOW()
    WHERE id = NEW.station_id;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- Trigger para actualizar automáticamente last_reading
CREATE TRIGGER trigger_update_station_last_reading
    AFTER INSERT ON hydrologic_readings
    FOR EACH ROW
    EXECUTE FUNCTION update_station_last_reading();

-- =============================================================================
-- CONFIGURACIONES DE RETENCIÓN Y COMPRESIÓN (TIMESCALEDB)
-- =============================================================================

-- Política de retención: mantener datos detallados por 2 años
SELECT add_retention_policy('hydrologic_readings', INTERVAL '2 years');

-- Política de compresión: comprimir datos después de 7 días
ALTER TABLE hydrologic_readings SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'station_id',
    timescaledb.compress_orderby = 'timestamp DESC'
);

SELECT add_compression_policy('hydrologic_readings', INTERVAL '7 days');

-- =============================================================================
-- COMENTARIOS DE LA BASE DE DATOS
-- =============================================================================

COMMENT ON TABLE stations IS 'Catálogo de estaciones hidrológicas monitoreadas';
COMMENT ON TABLE hydrologic_readings IS 'Tabla principal de lecturas de nivel de río (hypertable TimescaleDB)';
COMMENT ON TABLE alerts IS 'Sistema de alertas por niveles críticos de río';
COMMENT ON TABLE users IS 'Usuarios registrados con suscripciones Stripe';
COMMENT ON TABLE ai_news IS 'Noticias automatizadas generadas por IA (Fase 2)';

COMMENT ON COLUMN stations.nesdis_id IS 'ID NESDIS de NOAA para identificación única';
COMMENT ON COLUMN hydrologic_readings.timestamp IS 'Timestamp de la lectura (columna de particionamiento TimescaleDB)';
COMMENT ON COLUMN hydrologic_readings.level IS 'Nivel del río en metros';
COMMENT ON COLUMN users.alert_preferences IS 'Preferencias de alertas por estación en formato JSON';

-- Verificar que todo se creó correctamente
\dt