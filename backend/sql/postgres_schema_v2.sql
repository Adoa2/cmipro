-- ============================================================================
-- CMIPRO - Esquema PostgreSQL Optimizado (Sin TimescaleDB)
-- Fecha: Martes Semana 2 
-- Versión: 2.0 - PostgreSQL simple con optimizaciones para series temporales
-- ============================================================================

-- Extensiones básicas de PostgreSQL
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- ============================================================================
-- 1. TABLA STATIONS - Catálogo de Estaciones Hidrológicas
-- ============================================================================
CREATE TABLE IF NOT EXISTS stations (
    station_id VARCHAR(10) PRIMARY KEY,
    station_name VARCHAR(100) NOT NULL,
    river_name VARCHAR(50) NOT NULL,
    latitude DECIMAL(10, 7) NOT NULL,
    longitude DECIMAL(11, 7) NOT NULL,
    elevation DECIMAL(6,1),
    
    -- Identificadores externos
    nesdis_id VARCHAR(20) UNIQUE,
    usgs_id VARCHAR(20),
    
    -- Umbrales de riesgo calibrados (6 niveles - Análisis Semana 1)
    threshold_normal DECIMAL(5, 2) NOT NULL DEFAULT 2.0,
    threshold_low DECIMAL(5, 2) NOT NULL DEFAULT 4.0,
    threshold_moderate DECIMAL(5, 2) NOT NULL DEFAULT 6.0,
    threshold_high DECIMAL(5, 2) NOT NULL DEFAULT 8.0,
    threshold_very_high DECIMAL(5, 2) NOT NULL DEFAULT 12.0,
    threshold_critical DECIMAL(5, 2) NOT NULL DEFAULT 12.0,
    
    -- Población en riesgo por nivel
    population_risk_low INTEGER DEFAULT 5000,
    population_risk_moderate INTEGER DEFAULT 25000,
    population_risk_high INTEGER DEFAULT 100000,
    population_risk_very_high INTEGER DEFAULT 250000,
    population_risk_critical INTEGER DEFAULT 400000,
    
    -- Estado operacional
    is_active BOOLEAN DEFAULT TRUE,
    status VARCHAR(20) DEFAULT 'active',
    last_reading TIMESTAMPTZ,
    
    -- Metadatos
    description TEXT,
    data_source VARCHAR(20) DEFAULT 'NOAA',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 2. TABLA HYDROLOGIC_READINGS - Datos de Niveles (Optimizada para PostgreSQL)
-- ============================================================================
CREATE TABLE IF NOT EXISTS hydrologic_readings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    station_id VARCHAR(10) NOT NULL REFERENCES stations(station_id),
    timestamp_utc TIMESTAMPTZ NOT NULL,
    
    -- Datos hidrológicos principales
    water_level_m DECIMAL(6, 3) NOT NULL,
    flow_rate_cms DECIMAL(10, 3),
    stage_height DECIMAL(6, 3),
    
    -- Datos meteorológicos relacionados
    precipitation_mm DECIMAL(5, 2),
    temperature_c DECIMAL(4, 1),
    humidity_percent DECIMAL(4, 1),
    
    -- Análisis automático
    risk_level VARCHAR(15) DEFAULT 'normal',
    population_at_risk INTEGER DEFAULT 0,
    alert_triggered BOOLEAN DEFAULT FALSE,
    
    -- Calidad y origen del dato
    data_quality VARCHAR(10) DEFAULT 'good',
    data_source VARCHAR(50) DEFAULT 'NOAA_HADS',
    is_validated BOOLEAN DEFAULT FALSE,
    
    -- Metadatos
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    raw_data JSONB,
    
    -- Constraints
    CONSTRAINT unique_station_timestamp UNIQUE (station_id, timestamp_utc),
    CONSTRAINT chk_water_level_range CHECK (water_level_m >= 0 AND water_level_m <= 25),
    CONSTRAINT chk_risk_level CHECK (risk_level IN ('normal', 'low', 'moderate', 'high', 'very_high', 'critical'))
);

-- Índices optimizados para series temporales
CREATE INDEX IF NOT EXISTS idx_hydro_station_time ON hydrologic_readings(station_id, timestamp_utc DESC);
CREATE INDEX IF NOT EXISTS idx_hydro_time_only ON hydrologic_readings(timestamp_utc DESC);
CREATE INDEX IF NOT EXISTS idx_hydro_risk_level ON hydrologic_readings(risk_level, timestamp_utc DESC) 
    WHERE risk_level IN ('high', 'very_high', 'critical');
CREATE INDEX IF NOT EXISTS idx_hydro_station_recent ON hydrologic_readings(station_id, timestamp_utc DESC) 
    WHERE timestamp_utc > CURRENT_TIMESTAMP - INTERVAL '7 days';

-- ============================================================================
-- 3. TABLA ALERTS - Sistema de Alertas
-- ============================================================================
CREATE TABLE IF NOT EXISTS alerts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    station_id VARCHAR(10) NOT NULL REFERENCES stations(station_id),
    
    -- Tipo y nivel de alerta
    alert_type VARCHAR(20) NOT NULL DEFAULT 'water_level',
    risk_level VARCHAR(15) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    
    -- Datos del trigger
    trigger_value DECIMAL(6, 3) NOT NULL,
    current_value DECIMAL(6, 3) NOT NULL,
    threshold_exceeded VARCHAR(15) NOT NULL,
    
    -- Población afectada
    estimated_population INTEGER DEFAULT 0,
    affected_areas TEXT[],
    
    -- Estado de la alerta
    status VARCHAR(15) DEFAULT 'active',
    priority INTEGER DEFAULT 3,
    
    -- Mensajes
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    recommended_actions TEXT[],
    
    -- Control de usuario
    acknowledged_by UUID,
    acknowledged_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    
    -- Timestamps
    triggered_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) DEFAULT 'system',
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 4. TABLA USERS - Gestión de Usuarios
-- ============================================================================
CREATE TABLE IF NOT EXISTS users (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    
    -- Firebase Auth
    firebase_uid VARCHAR(128) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    
    -- Información personal
    display_name VARCHAR(100),
    phone_number VARCHAR(20),
    
    -- Suscripción Stripe
    stripe_customer_id VARCHAR(100) UNIQUE,
    subscription_status VARCHAR(20) DEFAULT 'inactive',
    subscription_plan VARCHAR(20) DEFAULT 'free',
    subscription_start_date TIMESTAMPTZ,
    subscription_end_date TIMESTAMPTZ,
    
    -- Preferencias de alertas
    alert_preferences JSONB DEFAULT '{"email": true, "push": true, "sms": false}',
    preferred_stations TEXT[] DEFAULT ARRAY['CHIH3', 'SANH3', 'RCHH3'],
    
    -- Metadatos
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE
);

-- ============================================================================
-- 5. TABLA AI_NEWS - Noticias IA (Fase 2)
-- ============================================================================
CREATE TABLE IF NOT EXISTS ai_news (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    
    -- Contenido
    title VARCHAR(200) NOT NULL,
    summary TEXT NOT NULL,
    content TEXT,
    category VARCHAR(50) DEFAULT 'weather',
    
    -- Fuentes
    source_urls TEXT[],
    source_type VARCHAR(30) DEFAULT 'rss',
    confidence_score DECIMAL(3, 2) DEFAULT 0.75,
    
    -- AI Metadata
    ai_model VARCHAR(50) DEFAULT 'gpt-3.5-turbo',
    generation_prompt TEXT,
    tokens_used INTEGER,
    
    -- Publicación
    status VARCHAR(15) DEFAULT 'draft',
    published_at TIMESTAMPTZ,
    
    -- Relevancia geográfica
    relevance_area VARCHAR(50) DEFAULT 'honduras',
    coordinates POINT,
    
    -- Metadatos
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- FUNCIONES PRINCIPALES
-- ============================================================================

-- Función para calcular nivel de riesgo
CREATE OR REPLACE FUNCTION calculate_risk_level(
    p_station_id VARCHAR(10),
    p_water_level DECIMAL(6, 3)
) RETURNS TABLE(
    risk_level VARCHAR(15),
    population_at_risk INTEGER,
    color_code VARCHAR(7),
    action_required TEXT
) AS $$
DECLARE
    station_rec RECORD;
BEGIN
    -- Obtener datos de la estación
    SELECT * INTO station_rec FROM stations WHERE station_id = p_station_id;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT 'unknown'::VARCHAR(15), 0::INTEGER, 
                           '#808080'::VARCHAR(7), 'Estación no encontrada'::TEXT;
        RETURN;
    END IF;
    
    -- Evaluar nivel de riesgo
    IF p_water_level >= station_rec.threshold_critical THEN
        RETURN QUERY SELECT 'critical'::VARCHAR(15), station_rec.population_risk_critical, 
                           '#EF4444'::VARCHAR(7), 'Evacuación inmediata'::TEXT;
    ELSIF p_water_level >= station_rec.threshold_very_high THEN
        RETURN QUERY SELECT 'very_high'::VARCHAR(15), station_rec.population_risk_very_high, 
                           '#DC2626'::VARCHAR(7), 'Evacuación preventiva'::TEXT;
    ELSIF p_water_level >= station_rec.threshold_high THEN
        RETURN QUERY SELECT 'high'::VARCHAR(15), station_rec.population_risk_high, 
                           '#F97316'::VARCHAR(7), 'Preparar evacuación'::TEXT;
    ELSIF p_water_level >= station_rec.threshold_moderate THEN
        RETURN QUERY SELECT 'moderate'::VARCHAR(15), station_rec.population_risk_moderate, 
                           '#EAB308'::VARCHAR(7), 'Monitoreo intensivo'::TEXT;
    ELSIF p_water_level >= station_rec.threshold_low THEN
        RETURN QUERY SELECT 'low'::VARCHAR(15), station_rec.population_risk_low, 
                           '#84CC16'::VARCHAR(7), 'Vigilancia continua'::TEXT;
    ELSE
        RETURN QUERY SELECT 'normal'::VARCHAR(15), 0::INTEGER, 
                           '#22C55E'::VARCHAR(7), 'Monitoreo rutinario'::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Función para insertar lectura con análisis automático
CREATE OR REPLACE FUNCTION insert_hydrologic_reading(
    p_station_id VARCHAR(10),
    p_timestamp_utc TIMESTAMPTZ,
    p_water_level_m DECIMAL(6, 3),
    p_flow_rate_cms DECIMAL(10, 3) DEFAULT NULL,
    p_data_quality VARCHAR(10) DEFAULT 'good',
    p_raw_data JSONB DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    reading_id UUID;
    risk_result RECORD;
BEGIN
    -- Calcular nivel de riesgo
    SELECT * INTO risk_result FROM calculate_risk_level(p_station_id, p_water_level_m);
    
    -- Insertar lectura con análisis
    INSERT INTO hydrologic_readings (
        station_id, timestamp_utc, water_level_m, flow_rate_cms,
        data_quality, risk_level, population_at_risk, raw_data,
        alert_triggered
    ) VALUES (
        p_station_id, p_timestamp_utc, p_water_level_m, p_flow_rate_cms,
        p_data_quality, risk_result.risk_level, risk_result.population_at_risk, p_raw_data,
        (risk_result.risk_level != 'normal')
    ) RETURNING id INTO reading_id;
    
    -- Actualizar timestamp en stations
    UPDATE stations 
    SET last_reading = p_timestamp_utc, updated_at = CURRENT_TIMESTAMP
    WHERE station_id = p_station_id;
    
    RETURN reading_id;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener últimas lecturas
CREATE OR REPLACE FUNCTION get_latest_readings(p_hours INTEGER DEFAULT 24)
RETURNS TABLE(
    station_id VARCHAR(10),
    station_name VARCHAR(100),
    river_name VARCHAR(50),
    latest_timestamp TIMESTAMPTZ,
    latest_water_level DECIMAL(6, 3),
    current_risk_level VARCHAR(15),
    population_at_risk INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.station_id,
        s.station_name,
        s.river_name,
        hr.timestamp_utc as latest_timestamp,
        hr.water_level_m as latest_water_level,
        hr.risk_level as current_risk_level,
        hr.population_at_risk
    FROM stations s
    LEFT JOIN LATERAL (
        SELECT *
        FROM hydrologic_readings hr2
        WHERE hr2.station_id = s.station_id
        AND hr2.timestamp_utc > CURRENT_TIMESTAMP - (p_hours || ' hours')::INTERVAL
        ORDER BY hr2.timestamp_utc DESC
        LIMIT 1
    ) hr ON true
    WHERE s.is_active = TRUE
    ORDER BY s.station_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TRIGGERS PARA AUTOMATIZACIÓN
-- ============================================================================

-- Trigger para updated_at automático
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_stations_updated_at 
    BEFORE UPDATE ON stations 
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- ============================================================================
-- VISTAS PARA CONSULTAS FRECUENTES
-- ============================================================================

-- Vista para dashboard principal
CREATE OR REPLACE VIEW dashboard_summary AS
SELECT 
    s.station_id,
    s.station_name,
    s.river_name,
    s.latitude,
    s.longitude,
    COALESCE(latest.water_level_m, 0) as current_level,
    COALESCE(latest.risk_level, 'unknown') as current_risk,
    COALESCE(latest.population_at_risk, 0) as population_at_risk,
    latest.timestamp_utc as last_updated,
    CASE 
        WHEN latest.timestamp_utc IS NULL THEN 'no_data'
        WHEN latest.timestamp_utc < CURRENT_TIMESTAMP - INTERVAL '2 hours' THEN 'stale'
        ELSE 'current'
    END as data_status
FROM stations s
LEFT JOIN LATERAL (
    SELECT water_level_m, risk_level, population_at_risk, timestamp_utc
    FROM hydrologic_readings hr
    WHERE hr.station_id = s.station_id
    ORDER BY timestamp_utc DESC
    LIMIT 1
) latest ON true
WHERE s.is_active = TRUE;

-- ============================================================================
-- DATOS INICIALES
-- ============================================================================

-- Insertar estaciones principales (basadas en análisis Semana 1)
INSERT INTO stations (
    station_id, station_name, river_name, latitude, longitude, elevation, nesdis_id,
    threshold_normal, threshold_low, threshold_moderate, threshold_high, 
    threshold_very_high, threshold_critical,
    population_risk_low, population_risk_moderate, population_risk_high, 
    population_risk_very_high, population_risk_critical,
    description
) VALUES 
(
    'CHIH3', 'Chinda (Río Ulúa)', 'Ulúa', 15.3847, -87.9547, 45.0, '50401A48',
    2.0, 4.0, 6.0, 8.0, 12.0, 12.0,
    5000, 25000, 100000, 250000, 400000,
    'Estación crítica río Ulúa - Monitorea La Lima, El Progreso'
),
(
    'SANH3', 'Santiago (Río Ulúa)', 'Ulúa', 15.2941, -87.9234, 38.0, '50402FD2',
    2.0, 4.0, 6.0, 8.0, 12.0, 12.0,
    3000, 20000, 80000, 200000, 350000,
    'Estación río Ulúa sector Santiago - Control aguas arriba'
),
(
    'RCHH3', 'El Tablón (Río Chamelecón)', 'Chamelecón', 15.4234, -88.0123, 52.0, '50403CA4',
    2.0, 4.0, 6.0, 8.0, 12.0, 12.0,
    4000, 15000, 60000, 150000, 280000,
    'Estación río Chamelecón - Monitorea Villanueva, Choloma'
)
ON CONFLICT (station_id) DO UPDATE SET
    updated_at = CURRENT_TIMESTAMP,
    description = EXCLUDED.description;

-- ============================================================================
-- COMENTARIOS Y DOCUMENTACIÓN
-- ============================================================================

COMMENT ON TABLE stations IS 'Catálogo estaciones hidrológicas Valle de Sula';
COMMENT ON TABLE hydrologic_readings IS 'Lecturas niveles optimizadas PostgreSQL';
COMMENT ON TABLE alerts IS 'Sistema alertas 6 niveles riesgo';
COMMENT ON TABLE users IS 'Usuarios Firebase Auth + Stripe';

-- Configurar timezone
SET timezone = 'America/Tegucigalpa';

-- Verificar extensiones
SELECT name, default_version, installed_version 
FROM pg_available_extensions 
WHERE name IN ('uuid-ossp', 'pg_stat_statements');

-- Verificar tablas creadas
SELECT 'ESQUEMA CARGADO EXITOSAMENTE' as status;

-- Fin del esquema PostgreSQL