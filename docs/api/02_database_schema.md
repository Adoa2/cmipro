# 🗄️ Esquema de Base de Datos y Modelos JSON - CMIPRO

## 📊 **Tabla principal: hydrologic_readings**

Esta tabla almacena todas las lecturas de las estaciones hidrológicas en TimescaleDB.

```sql
-- Extensión TimescaleDB habilitada
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Tabla principal de lecturas hidrológicas
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
    
    -- Índices para consultas rápidas
    CONSTRAINT unique_station_timestamp UNIQUE (station_id, timestamp)
);

-- Convertir a hypertable (TimescaleDB)
SELECT create_hypertable('hydrologic_readings', 'timestamp', chunk_time_interval => INTERVAL '1 day');

-- Índices adicionales
CREATE INDEX idx_station_timestamp ON hydrologic_readings (station_id, timestamp DESC);
CREATE INDEX idx_risk_level ON hydrologic_readings (risk_level, timestamp DESC) WHERE risk_level != 'normal';
CREATE INDEX idx_created_at ON hydrologic_readings (created_at DESC);
```

---

## 🏛️ **Tabla de estaciones: stations**

```sql
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

-- Insertar estaciones iniciales
INSERT INTO stations (id, name, river, latitude, longitude, elevation, nesdis_id, threshold_low, threshold_medium, threshold_high, threshold_critical) VALUES
('CHIH3', 'Chinda', 'Ulúa', 15.3847, -87.9547, 45.0, '50401A48', 1.5, 3.0, 4.5, 6.0),
('SANH3', 'Santiago', 'Ulúa', 15.2941, -87.9234, 38.0, '50402FD2', 1.2, 2.5, 4.0, 5.5),
('RCHH3', 'El Tablón', 'Chamelecón', 15.4234, -88.0123, 52.0, '50403CA4', 1.8, 3.5, 5.0, 7.0);
```

---

## 🚨 **Tabla de alertas: alerts**

```sql
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

CREATE INDEX idx_alerts_active ON alerts (station_id, is_active, created_at DESC);
CREATE INDEX idx_alerts_severity ON alerts (severity, created_at DESC) WHERE is_active = true;
```

---

## 👥 **Tabla de usuarios: users**

```sql
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

CREATE INDEX idx_users_subscription ON users (subscription_status, current_period_end);
CREATE INDEX idx_users_stripe ON users (stripe_customer_id);
```

---

## 🤖 **Tabla de noticias IA: ai_news**

```sql
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

CREATE INDEX idx_news_category ON ai_news (category, published_at DESC) WHERE status = 'published';
CREATE INDEX idx_news_priority ON ai_news (priority DESC, published_at DESC) WHERE status = 'published';
```

---

## 📋 **Modelos JSON para FastAPI (Pydantic)**

### **1. Modelo de estación**

```python
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional
from enum import Enum

class RiskLevel(str, Enum):
    NORMAL = "normal"
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

class Location(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    elevation: Optional[float] = None

class Station(BaseModel):
    id: str = Field(..., min_length=1, max_length=10)
    name: str = Field(..., min_length=1, max_length=100)
    river: str = Field(..., min_length=1, max_length=50)
    location: Location
    nesdis_id: Optional[str] = None
    status: str = "active"
    last_reading: Optional[datetime] = None
    current_level: Optional[float] = None
    risk_level: RiskLevel = RiskLevel.NORMAL

class StationResponse(BaseModel):
    success: bool = True
    data: list[Station]
```

### **2. Modelo de lectura hidrológica**

```python
class HydrologicReading(BaseModel):
    timestamp: datetime
    level: Optional[float] = None
    flow_rate: Optional[float] = None
    temperature: Optional[float] = None
    precipitation: Optional[float] = None
    risk_level: RiskLevel = RiskLevel.NORMAL

class Thresholds(BaseModel):
    normal: float = 0.0
    low: float = 1.5
    medium: float = 3.0
    high: float = 4.5
    critical: float = 6.0

class LevelsResponse(BaseModel):
    success: bool = True
    data: dict = Field(..., example={
        "station_id": "CHIH3",
        "station_name": "Chinda",
        "river": "Ulúa",
        "interval": "1hour",
        "unit": "meters",
        "readings": [],
        "count": 0,
        "thresholds": {}
    })
```

### **3. Modelo de alerta**

```python
class AlertSeverity(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

class Alert(BaseModel):
    id: str
    station_id: str
    station_name: str
    river: str
    severity: AlertSeverity
    level: float
    threshold: float
    message: str
    created_at: datetime
    is_active: bool = True
    estimated_peak: Optional[datetime] = None

class AlertsResponse(BaseModel):
    success: bool = True
    data: list[Alert]
```

### **4. Modelo de respuesta de error**

```python
class ErrorDetail(BaseModel):
    code: str
    message: str
    details: Optional[str] = None

class ErrorResponse(BaseModel):
    success: bool = False
    error: ErrorDetail
```

---

## 🔧 **Funciones SQL útiles para TimescaleDB**

```sql
-- 1. Obtener último nivel por estación
CREATE OR REPLACE FUNCTION get_current_levels()
RETURNS TABLE (
    station_id VARCHAR(10),
    current_level DECIMAL(6,3),
    risk_level VARCHAR(20),
    last_reading TIMESTAMPTZ
) AS $$
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
$$ LANGUAGE plpgsql;

-- 2. Calcular riesgo basado en umbrales
CREATE OR REPLACE FUNCTION calculate_risk_level(
    station_id_param VARCHAR(10),
    level_param DECIMAL(6,3)
) RETURNS VARCHAR(20) AS $$
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
$$ LANGUAGE plpgsql;
```

---

## 📦 **Ejemplo de datos NOAA HADS parseados**

```json
{
  "raw_noaa_line": "CHIH3    08051430 /DC25051430/HP/DH1430/HG/2.45/HT/26.5/PC/0.00",
  "parsed": {
    "station_id": "CHIH3",
    "timestamp": "2025-08-05T14:30:00Z",
    "level": 2.45,
    "temperature": 26.5,
    "precipitation": 0.00,
    "data_quality": "good",
    "risk_level": "normal"
  }
}
```