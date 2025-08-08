# Archivo: backend/app/schemas/reading.py
# Modelos Pydantic para lecturas hidrológicas

from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field, validator
from .station import RiskLevel

class ReadingBase(BaseModel):
    """Campos base para lectura hidrológica"""
    station_id: int = Field(..., description="ID de la estación")
    timestamp: datetime = Field(..., description="Timestamp UTC de la lectura")
    water_level_m: float = Field(..., ge=0, description="Nivel del agua en metros")
    flow_rate_cms: Optional[float] = Field(None, ge=0, description="Caudal en m³/s")
    temperature_c: Optional[float] = Field(None, description="Temperatura del agua °C")
    
    @validator('timestamp')
    def validate_timestamp(cls, v):
        """Validar que el timestamp no sea muy antiguo o futuro"""
        now = datetime.utcnow()
        if v > now + timedelta(hours=1):
            raise ValueError('Timestamp no puede ser más de 1 hora en el futuro')
        if v < now - timedelta(days=30):
            raise ValueError('Timestamp no puede ser más de 30 días en el pasado')
        return v

class ReadingCreate(ReadingBase):
    """Schema para crear nueva lectura"""
    source: str = Field(default="NOAA", description="Fuente de los datos")
    quality_flag: str = Field(default="good", description="Calidad del dato")

class ReadingResponse(ReadingBase):
    """Respuesta de lectura con datos calculados"""
    id: int
    risk_level: RiskLevel
    risk_color: str
    trend: str = Field(..., description="Tendencia: rising, falling, stable")
    change_rate: Optional[float] = Field(None, description="Tasa de cambio m/h")
    
    # Metadata
    source: str
    quality_flag: str
    created_at: datetime
    
    class Config:
        from_attributes = True

# Schemas para consultas temporales
class TimeSeriesQuery(BaseModel):
    """Parámetros para consultas de series temporales"""
    station_ids: List[int] = Field(..., description="IDs de estaciones")
    start_time: datetime = Field(..., description="Inicio del período")
    end_time: datetime = Field(..., description="Fin del período")
    interval: str = Field(default="1h", description="Intervalo de agregación")
    
    @validator('end_time')
    def validate_time_range(cls, v, values):
        if 'start_time' in values and v <= values['start_time']:
            raise ValueError('end_time debe ser posterior a start_time')
        return v
    
    @validator('interval')
    def validate_interval(cls, v):
        valid_intervals = ['5m', '15m', '30m', '1h', '3h', '6h', '12h', '1d']
        if v not in valid_intervals:
            raise ValueError(f'Intervalo debe ser uno de: {valid_intervals}')
        return v

class TimeSeriesPoint(BaseModel):
    """Punto individual en serie temporal"""
    timestamp: datetime
    value: float
    risk_level: RiskLevel
    quality: str = "good"

class TimeSeriesData(BaseModel):
    """Serie temporal completa para una estación"""
    station_id: int
    station_name: str
    nwsli_id: str
    interval: str
    data_points: List[TimeSeriesPoint]
    statistics: Dict[str, float] = Field(default_factory=dict)

class MultiStationTimeSeries(BaseModel):
    """Series temporales para múltiples estaciones"""
    query: TimeSeriesQuery
    stations: List[TimeSeriesData]
    total_points: int
    generated_at: datetime = Field(default_factory=datetime.utcnow)

# Schemas para análisis
class LevelAnalysis(BaseModel):
    """Análisis estadístico de niveles"""
    station_id: int
    period_hours: int
    
    # Estadísticas básicas
    current_level: float
    min_level: float
    max_level: float
    avg_level: float
    
    # Análisis de tendencia
    trend: str  # "rising", "falling", "stable"
    change_rate_mh: float  # metros por hora
    total_change_m: float
    
    # Análisis de riesgo
    time_above_critical: int = 0  # minutos
    max_risk_level: RiskLevel
    risk_changes: int = 0  # número de cambios de nivel de riesgo
    
    # Predicción simple
    predicted_level_1h: Optional[float] = None
    predicted_risk_1h: Optional[RiskLevel] = None

class StationHealthMetrics(BaseModel):
    """Métricas de salud de estación"""
    station_id: int
    last_24h: Dict[str, Any] = Field(default_factory=dict)
    
    # Calidad de datos
    total_readings: int
    good_readings: int
    poor_readings: int
    missing_periods: int
    
    # Conectividad
    last_reading: Optional[datetime] = None
    is_online: bool = True
    uptime_percentage: float = 100.0
    
    # Alertas
    active_alerts: int = 0
    total_alerts_24h: int = 0

# Schemas para endpoints específicos
class LevelsQueryParams(BaseModel):
    """Parámetros para endpoint GET /levels"""
    station_id: Optional[int] = None
    nwsli_id: Optional[str] = None
    from_time: Optional[datetime] = None
    to_time: Optional[datetime] = None
    limit: int = Field(default=100, le=1000)
    order: str = Field(default="desc", regex="^(asc|desc)$")

class LevelsResponse(BaseModel):
    """Respuesta del endpoint /levels"""
    success: bool = True
    data: List[ReadingResponse]
    pagination: Dict[str, Any] = Field(default_factory=dict)
    metadata: Dict[str, Any] = Field(default_factory=dict)
    timestamp: datetime = Field(default_factory=datetime.utcnow)

# Schemas para dashboard en tiempo real
class RealTimeReading(BaseModel):
    """Lectura optimizada para tiempo real"""
    station_id: int
    nwsli_id: str
    timestamp: datetime
    level: float
    risk: RiskLevel
    color: str
    trend: str
    population_at_risk: int = 0

class RealTimeDashboard(BaseModel):
    """Dashboard tiempo real completo"""
    stations: List[RealTimeReading]
    last_update: datetime
    total_stations: int
    alerts_active: int
    system_status: str = "operational"