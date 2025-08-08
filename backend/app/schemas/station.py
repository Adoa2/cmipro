# Archivo: backend/app/schemas/station.py
# Modelos Pydantic para estaciones hidrológicas

from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field, validator
from enum import Enum

class RiskLevel(str, Enum):
    """Niveles de riesgo definidos en Martes S1"""
    NORMAL = "normal"
    LOW = "low" 
    MODERATE = "moderate"
    HIGH = "high"
    VERY_HIGH = "very_high"
    CRITICAL = "critical"

class StationStatus(str, Enum):
    """Estados posibles de una estación"""
    ACTIVE = "active"
    INACTIVE = "inactive"
    MAINTENANCE = "maintenance"

# Schemas Base
class StationBase(BaseModel):
    """Campos base para estación"""
    nwsli_id: str = Field(..., description="Código NWSLI (ej: CHIH3)")
    nesdis_id: str = Field(..., description="Código NESDIS")
    name: str = Field(..., description="Nombre descriptivo")
    river_name: str = Field(..., description="Nombre del río")
    location: str = Field(..., description="Ubicación descriptiva")
    latitude: float = Field(..., ge=-90, le=90, description="Latitud")
    longitude: float = Field(..., ge=-180, le=180, description="Longitud")
    
    @validator('nwsli_id')
    def validate_nwsli_id(cls, v):
        if not v or len(v) < 3:
            raise ValueError('NWSLI ID debe tener al menos 3 caracteres')
        return v.upper()

class StationThresholds(BaseModel):
    """Umbrales de riesgo por estación (desde Martes S1)"""
    normal_max: float = Field(..., description="Máximo nivel normal (metros)")
    low_max: float = Field(..., description="Máximo nivel bajo")
    moderate_max: float = Field(..., description="Máximo nivel moderado") 
    high_max: float = Field(..., description="Máximo nivel alto")
    very_high_max: float = Field(..., description="Máximo nivel muy alto")
    critical_min: float = Field(..., description="Mínimo nivel crítico")
    
    @validator('critical_min')
    def validate_thresholds_order(cls, v, values):
        """Validar que los umbrales estén en orden ascendente"""
        if 'very_high_max' in values and v <= values['very_high_max']:
            raise ValueError('Umbral crítico debe ser mayor que muy alto')
        return v

class StationCreate(StationBase):
    """Schema para crear nueva estación"""
    thresholds: StationThresholds
    status: StationStatus = StationStatus.ACTIVE

class StationUpdate(BaseModel):
    """Schema para actualizar estación"""
    name: Optional[str] = None
    location: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    status: Optional[StationStatus] = None
    thresholds: Optional[StationThresholds] = None

# Schemas de respuesta
class CurrentReading(BaseModel):
    """Lectura actual de la estación"""
    timestamp: datetime
    water_level_m: float = Field(..., description="Nivel del agua en metros")
    flow_rate_cms: Optional[float] = Field(None, description="Caudal en m³/s")
    risk_level: RiskLevel
    risk_color: str = Field(..., description="Color hex para UI")

class StationResponse(StationBase):
    """Respuesta completa de estación"""
    id: int
    thresholds: StationThresholds
    status: StationStatus
    current_reading: Optional[CurrentReading] = None
    last_updated: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class StationSummary(BaseModel):
    """Resumen de estación para dashboard"""
    id: int
    nwsli_id: str
    name: str
    river_name: str
    current_level: Optional[float] = None
    risk_level: Optional[RiskLevel] = None
    risk_color: str = "#22C55E"  # Verde por defecto
    status: StationStatus
    last_updated: Optional[datetime] = None

class StationsList(BaseModel):
    """Lista de estaciones con metadatos"""
    stations: List[StationSummary]
    total_count: int
    active_count: int
    last_update: Optional[datetime] = None

# Schemas para dashboard
class DashboardStation(BaseModel):
    """Datos de estación optimizados para dashboard"""
    nwsli_id: str
    name: str
    river_name: str
    location: str
    coordinates: tuple[float, float]  # (lat, lon)
    
    # Estado actual
    current_level: Optional[float] = None
    risk_level: RiskLevel = RiskLevel.NORMAL
    risk_color: str = "#22C55E"
    trend: str = "stable"  # "rising", "falling", "stable"
    
    # Poblacion en riesgo (desde Martes S1)
    population_at_risk: int = 0
    
    # Metadata
    status: StationStatus
    last_reading: Optional[datetime] = None

# Response wrapper genérico
class StationAPIResponse(BaseModel):
    """Wrapper estándar para respuestas de la API"""
    success: bool = True
    data: Optional[StationResponse | StationsList | List[DashboardStation]] = None
    message: str = "Operación exitosa"
    timestamp: datetime = Field(default_factory=datetime.utcnow)