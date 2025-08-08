# Archivo: backend/app/schemas/alert.py
# Modelos Pydantic para sistema de alertas

from datetime import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field, validator
from enum import Enum
from .station import RiskLevel

class AlertType(str, Enum):
    """Tipos de alerta"""
    LEVEL_THRESHOLD = "level_threshold"
    RAPID_RISE = "rapid_rise"
    SUSTAINED_HIGH = "sustained_high"
    DATA_QUALITY = "data_quality"
    SYSTEM_FAILURE = "system_failure"

class AlertSeverity(str, Enum):
    """Severidad de alertas"""
    INFO = "info"
    WARNING = "warning"  
    CRITICAL = "critical"
    EMERGENCY = "emergency"

class AlertStatus(str, Enum):
    """Estados de alerta"""
    ACTIVE = "active"
    ACKNOWLEDGED = "acknowledged"
    RESOLVED = "resolved"
    CANCELLED = "cancelled"

# Schemas base
class AlertBase(BaseModel):
    """Campos base para alertas"""
    station_id: int = Field(..., description="ID de la estación")
    alert_type: AlertType
    severity: AlertSeverity
    risk_level: RiskLevel
    title: str = Field(..., max_length=200, description="Título de la alerta")
    message: str = Field(..., max_length=1000, description="Mensaje detallado")
    
class AlertCreate(AlertBase):
    """Schema para crear nueva alerta"""
    triggered_by_reading_id: Optional[int] = None
    additional_data: Dict[str, Any] = Field(default_factory=dict)
    
class AlertUpdate(BaseModel):
    """Schema para actualizar alerta"""
    status: Optional[AlertStatus] = None
    acknowledged_by: Optional[str] = None
    resolution_notes: Optional[str] = None

class AlertResponse(AlertBase):
    """Respuesta completa de alerta"""
    id: int
    status: AlertStatus
    
    # Timestamps
    created_at: datetime
    acknowledged_at: Optional[datetime] = None
    resolved_at: Optional[datetime] = None
    
    # Datos adicionales
    triggered_by_reading_id: Optional[int] = None
    additional_data: Dict[str, Any] = Field(default_factory=dict)
    
    # Metadatos de resolución
    acknowledged_by: Optional[str] = None
    resolution_notes: Optional[str] = None
    
    # Información de estación
    station_nwsli_id: str
    station_name: str
    
    class Config:
        from_attributes = True

# Schemas para listas y consultas
class AlertsQuery(BaseModel):
    """Parámetros para consultar alertas"""
    station_ids: Optional[List[int]] = None
    alert_types: Optional[List[AlertType]] = None
    severities: Optional[List[AlertSeverity]] = None
    statuses: Optional[List[AlertStatus]] = None
    from_date: Optional[datetime] = None
    to_date: Optional[datetime] = None
    limit: int = Field(default=50, le=200)
    offset: int = Field(default=0, ge=0)

class AlertSummary(BaseModel):
    """Resumen de alerta para listas"""
    id: int
    station_nwsli_id: str
    alert_type: AlertType
    severity: AlertSeverity
    status: AlertStatus
    title: str
    created_at: datetime
    risk_level: RiskLevel
    is_urgent: bool = False

class AlertsList(BaseModel):
    """Lista de alertas con metadatos"""
    alerts: List[AlertSummary]
    total_count: int
    active_count: int
    critical_count: int
    pagination: Dict[str, int]

# Schemas para dashboard de alertas
class ActiveAlert(BaseModel):
    """Alerta activa para dashboard"""
    id: int
    station_nwsli_id: str
    station_name: str
    severity: AlertSeverity
    title: str
    message: str
    created_at: datetime
    time_active: str  # "2h 30m"
    risk_level: RiskLevel
    risk_color: str

class AlertsDashboard(BaseModel):
    """Dashboard de alertas"""
    active_alerts: List[ActiveAlert]
    summary: Dict[str, int] = Field(default_factory=dict)
    last_update: datetime = Field(default_factory=datetime.utcnow)

# Schemas para notificaciones
class NotificationChannel(str, Enum):
    """Canales de notificación"""
    BROWSER_PUSH = "browser_push"
    EMAIL = "email"
    SMS = "sms"
    WEBHOOK = "webhook"

class NotificationRule(BaseModel):
    """Regla de notificación"""
    id: Optional[int] = None
    user_id: str  # Firebase UID
    station_ids: List[int] = Field(default_factory=list)
    severity_threshold: AlertSeverity = AlertSeverity.WARNING
    channels: List[NotificationChannel]
    is_active: bool = True
    
    # Configuración específica por canal
    email_address: Optional[str] = None
    phone_number: Optional[str] = None
    webhook_url: Optional[str] = None

class NotificationPayload(BaseModel):
    """Payload para enviar notificación"""
    alert_id: int
    channel: NotificationChannel
    recipient: str  # email, phone, etc.
    subject: str
    body: str
    priority: str = "normal"
    additional_data: Dict[str, Any] = Field(default_factory=dict)

# Schemas para métricas de alertas
class AlertMetrics(BaseModel):
    """Métricas del sistema de alertas"""
    period_hours: int = 24
    
    # Contadores
    total_alerts: int
    active_alerts: int
    resolved_alerts: int
    false_positives: int
    
    # Por severidad
    by_severity: Dict[AlertSeverity, int]
    
    # Por tipo
    by_type: Dict[AlertType, int]
    
    # Por estación
    by_station: Dict[str, int]  # nwsli_id -> count
    
    # Tiempos promedio
    avg_resolution_time_hours: float
    avg_acknowledgment_time_minutes: float
    
    # Tendencias
    trend_vs_previous_period: str  # "increasing", "decreasing", "stable"

# Schemas para respuestas de API
class AlertAPIResponse(BaseModel):
    """Wrapper para respuestas de alertas"""
    success: bool = True
    data: Optional[AlertResponse | AlertsList | AlertsDashboard] = None
    message: str = "Operación exitosa"
    timestamp: datetime = Field(default_factory=datetime.utcnow)

# Schemas para webhooks
class AlertWebhook(BaseModel):
    """Webhook de alerta para sistemas externos"""
    event_type: str  # "alert.created", "alert.resolved", etc.
    alert_id: int
    station_id: int
    station_nwsli_id: str
    severity: AlertSeverity
    status: AlertStatus
    timestamp: datetime
    data: AlertResponse