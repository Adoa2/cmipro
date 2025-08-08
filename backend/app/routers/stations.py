# Archivo: backend/app/routers/stations.py
# Router simplificado para estaciones funcionando con SQLite

from datetime import datetime
from typing import List, Optional, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import text
from pydantic import BaseModel

from ..config.database import get_db
from ..config.settings import get_settings, Settings

# Crear router
router = APIRouter(
    prefix="/stations",
    tags=["Estaciones"],
    responses={404: {"description": "Estación no encontrada"}}
)

# Schemas simplificados
class StationSummary(BaseModel):
    id: int
    nwsli_id: str
    name: str
    river_name: str
    location: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    status: str
    current_level: Optional[float] = None
    risk_level: str = "normal"
    risk_color: str = "#22C55E"
    last_updated: Optional[datetime] = None

class StationResponse(BaseModel):
    id: int
    nwsli_id: str
    name: str
    river_name: str
    location: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    status: str
    created_at: datetime
    updated_at: datetime

class APIResponse(BaseModel):
    success: bool = True
    data: Optional[Any] = None
    message: str = "Operación exitosa"
    timestamp: datetime = datetime.utcnow()

@router.get("/", response_model=APIResponse)
async def get_stations(
    active_only: bool = Query(True, description="Solo estaciones activas"),
    include_current_reading: bool = Query(True, description="Incluir lectura actual"),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings)
):
    """Obtener lista de todas las estaciones hidrológicas."""
    try:
        # Query base para estaciones
        base_query = """
        SELECT 
            id, nwsli_id, name, river_name, location,
            latitude, longitude, status, created_at, updated_at
        FROM stations
        """
        
        if active_only:
            base_query += " WHERE status = 'active'"
            
        base_query += " ORDER BY name"
        
        result = db.execute(text(base_query))
        stations_data = result.fetchall()
        
        stations = []
        for station_row in stations_data:
            station_dict = {
                "id": station_row.id,
                "nwsli_id": station_row.nwsli_id,
                "name": station_row.name,
                "river_name": station_row.river_name,
                "location": station_row.location,
                "latitude": float(station_row.latitude) if station_row.latitude else None,
                "longitude": float(station_row.longitude) if station_row.longitude else None,
                "status": station_row.status,
                "last_updated": station_row.updated_at
            }
            
            # Obtener lectura actual si se requiere
            if include_current_reading:
                reading_query = """
                SELECT 
                    timestamp, water_level_m, flow_rate_cms
                FROM hydrologic_readings
                WHERE station_id = :station_id
                ORDER BY timestamp DESC
                LIMIT 1
                """
                
                reading_result = db.execute(
                    text(reading_query), 
                    {"station_id": station_row.id}
                )
                reading_row = reading_result.fetchone()
                
                if reading_row:
                    # Calcular nivel de riesgo manualmente
                    level = reading_row.water_level_m
                    risk_level = calculate_risk_level(level, station_row.nwsli_id)
                    risk_color = settings.risk_levels.get(risk_level, {}).get("color", "#22C55E")
                    
                    station_dict.update({
                        "current_level": level,
                        "risk_level": risk_level,
                        "risk_color": risk_color,
                        "last_reading": reading_row.timestamp
                    })
            
            stations.append(StationSummary(**station_dict))
        
        return APIResponse(
            success=True,
            data={
                "stations": [station.dict() for station in stations],
                "total_count": len(stations),
                "active_count": len([s for s in stations if s.status == "active"])
            },
            message=f"Encontradas {len(stations)} estaciones"
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=500, 
            detail=f"Error obteniendo estaciones: {str(e)}"
        )

@router.get("/{station_id}", response_model=APIResponse)
async def get_station(
    station_id: int,
    db: Session = Depends(get_db)
):
    """Obtener detalles de una estación específica por ID."""
    try:
        query = "SELECT * FROM stations WHERE id = :station_id"
        result = db.execute(text(query), {"station_id": station_id})
        station_row = result.fetchone()
        
        if not station_row:
            raise HTTPException(
                status_code=404, 
                detail=f"Estación con ID {station_id} no encontrada"
            )
        
        station_data = StationResponse(
            id=station_row.id,
            nwsli_id=station_row.nwsli_id,
            name=station_row.name,
            river_name=station_row.river_name,
            location=station_row.location,
            latitude=float(station_row.latitude) if station_row.latitude else None,
            longitude=float(station_row.longitude) if station_row.longitude else None,
            status=station_row.status,
            created_at=station_row.created_at,
            updated_at=station_row.updated_at
        )
        
        return APIResponse(
            success=True,
            data=station_data.dict(),
            message="Estación encontrada"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error obteniendo estación: {str(e)}"
        )

@router.get("/nwsli/{nwsli_id}", response_model=APIResponse)
async def get_station_by_nwsli(
    nwsli_id: str,
    db: Session = Depends(get_db)
):
    """Obtener estación por código NWSLI (ej: CHIH3, SANH3, RCHH3)."""
    try:
        query = "SELECT * FROM stations WHERE UPPER(nwsli_id) = UPPER(:nwsli_id)"
        result = db.execute(text(query), {"nwsli_id": nwsli_id})
        station_row = result.fetchone()
        
        if not station_row:
            raise HTTPException(
                status_code=404,
                detail=f"Estación {nwsli_id} no encontrada"
            )
        
        station_data = StationResponse(
            id=station_row.id,
            nwsli_id=station_row.nwsli_id,
            name=station_row.name,
            river_name=station_row.river_name,
            location=station_row.location,
            latitude=float(station_row.latitude) if station_row.latitude else None,
            longitude=float(station_row.longitude) if station_row.longitude else None,
            status=station_row.status,
            created_at=station_row.created_at,
            updated_at=station_row.updated_at
        )
        
        return APIResponse(
            success=True,
            data=station_data.dict(),
            message=f"Estación {nwsli_id} encontrada"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error obteniendo estación: {str(e)}"
        )

@router.get("/summary/dashboard", response_model=APIResponse)
async def get_dashboard_summary(
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings)
):
    """Obtener resumen para dashboard con datos de las 3 estaciones del Valle de Sula."""
    try:
        # Query optimizada para dashboard
        query = """
        SELECT 
            s.id, s.nwsli_id, s.name, s.river_name, s.location,
            s.latitude, s.longitude, s.status,
            hr.water_level_m as current_level,
            hr.timestamp as last_reading
        FROM stations s
        LEFT JOIN (
            SELECT DISTINCT station_id, 
                   FIRST_VALUE(water_level_m) OVER (PARTITION BY station_id ORDER BY timestamp DESC) as water_level_m,
                   FIRST_VALUE(timestamp) OVER (PARTITION BY station_id ORDER BY timestamp DESC) as timestamp,
                   ROW_NUMBER() OVER (PARTITION BY station_id ORDER BY timestamp DESC) as rn
            FROM hydrologic_readings
        ) hr ON s.id = hr.station_id AND hr.rn = 1
        WHERE s.status = 'active'
        ORDER BY s.name
        """
        
        result = db.execute(text(query))
        stations_data = result.fetchall()
        
        dashboard_stations = []
        
        # Población en riesgo por estación (del Martes S1)
        population_map = {
            "CHIH3": 150000,  # Ulúa - Chinda
            "SANH3": 180000,  # Ulúa - Santiago  
            "RCHH3": 120000   # Chamelecón - El Tablón
        }
        
        for station in stations_data:
            # Calcular riesgo y población
            risk_level = "normal"
            population_at_risk = 0
            
            if station.current_level:
                risk_level = calculate_risk_level(station.current_level, station.nwsli_id)
                base_population = population_map.get(station.nwsli_id, 0)
                
                if risk_level in ["critical", "very_high"]:
                    population_at_risk = base_population
                elif risk_level == "high":
                    population_at_risk = int(base_population * 0.7)
                elif risk_level == "moderate":
                    population_at_risk = int(base_population * 0.4)
            
            risk_color = settings.risk_levels.get(risk_level, {}).get("color", "#22C55E")
            
            dashboard_station = {
                "nwsli_id": station.nwsli_id,
                "name": station.name,
                "river_name": station.river_name,
                "location": station.location or "",
                "coordinates": [
                    float(station.latitude) if station.latitude else 0.0,
                    float(station.longitude) if station.longitude else 0.0
                ],
                "current_level": station.current_level,
                "risk_level": risk_level,
                "risk_color": risk_color,
                "trend": "stable",
                "population_at_risk": population_at_risk,
                "status": station.status,
                "last_reading": station.last_reading
            }
            
            dashboard_stations.append(dashboard_station)
        
        return APIResponse(
            success=True,
            data={
                "stations": dashboard_stations,
                "total_stations": len(dashboard_stations),
                "active_alerts": sum(1 for s in dashboard_stations if s["risk_level"] in ["high", "very_high", "critical"]),
                "total_population_protected": sum(population_map.values()),
                "last_update": datetime.utcnow()
            },
            message="Dashboard generado exitosamente"
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error obteniendo datos de dashboard: {str(e)}"
        )

# Función auxiliar para calcular nivel de riesgo
def calculate_risk_level(water_level: float, nwsli_id: str) -> str:
    """Calcular nivel de riesgo basado en umbrales del Martes S1"""
    
    # Umbrales por estación (desde Martes S1)
    thresholds = {
        "CHIH3": {"low": 2.0, "moderate": 4.0, "high": 6.0, "very_high": 8.0, "critical": 12.0},
        "SANH3": {"low": 2.0, "moderate": 4.0, "high": 6.0, "very_high": 8.0, "critical": 12.0},
        "RCHH3": {"low": 2.0, "moderate": 4.0, "high": 6.0, "very_high": 8.0, "critical": 12.0}
    }
    
    station_thresholds = thresholds.get(nwsli_id, thresholds["CHIH3"])  # Default
    
    if water_level >= station_thresholds["critical"]:
        return "critical"
    elif water_level >= station_thresholds["very_high"]:
        return "very_high"
    elif water_level >= station_thresholds["high"]:
        return "high"
    elif water_level >= station_thresholds["moderate"]:
        return "moderate"
    elif water_level >= station_thresholds["low"]:
        return "low"
    else:
        return "normal"