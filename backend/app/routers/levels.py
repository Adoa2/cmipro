# Archivo: backend/app/routers/levels.py
# Endpoints para lecturas hidrológicas y series temporales

from datetime import datetime, timedelta
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import text

from ..config.database import get_db
from ..schemas.reading import (
    ReadingResponse, LevelsResponse, TimeSeriesData, 
    RealTimeReading, LevelsQueryParams
)
from ..config.settings import get_settings, Settings

# Crear router
router = APIRouter(
    prefix="/levels",
    tags=["Lecturas Hidrológicas"],
    responses={404: {"description": "Datos no encontrados"}}
)

@router.get("/", response_model=LevelsResponse)
async def get_levels(
    station_id: Optional[int] = Query(None, description="ID de estación específica"),
    nwsli_id: Optional[str] = Query(None, description="Código NWSLI (ej: CHIH3)"),
    from_time: Optional[datetime] = Query(None, description="Fecha/hora inicio (UTC)"),
    to_time: Optional[datetime] = Query(None, description="Fecha/hora fin (UTC)"),
    limit: int = Query(100, le=1000, description="Máximo número de registros"),
    order: str = Query("desc", regex="^(asc|desc)$", description="Orden temporal"),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings)
):
    """
    Obtener lecturas hidrológicas con filtros opcionales.
    
    - **station_id**: Filtrar por ID de estación
    - **nwsli_id**: Filtrar por código NWSLI (alternativo a station_id)
    - **from_time**: Inicio del período (UTC)
    - **to_time**: Fin del período (UTC)
    - **limit**: Máximo registros (default: 100, max: 1000)
    - **order**: Orden temporal (asc|desc)
    """
    try:
        # Construir query dinámicamente
        base_query = """
        SELECT 
            hr.id,
            hr.station_id,
            hr.timestamp,
            hr.water_level_m,
            hr.flow_rate_cms,
            hr.temperature_c,
            hr.source,
            hr.quality_flag,
            hr.created_at,
            s.nwsli_id,
            s.name as station_name,
            calculate_risk_level(hr.water_level_m, s.nwsli_id) as risk_level
        FROM hydrologic_readings hr
        JOIN stations s ON hr.station_id = s.id
        WHERE 1=1
        """
        
        params = []
        
        # Filtros condicionales
        if station_id:
            base_query += " AND hr.station_id = %s"
            params.append(station_id)
        
        if nwsli_id:
            base_query += " AND UPPER(s.nwsli_id) = UPPER(%s)"
            params.append(nwsli_id)
        
        if from_time:
            base_query += " AND hr.timestamp >= %s"
            params.append(from_time)
        
        if to_time:
            base_query += " AND hr.timestamp <= %s"
            params.append(to_time)
        
        # Ordenamiento y límite
        base_query += f" ORDER BY hr.timestamp {order.upper()}"
        base_query += " LIMIT %s"
        params.append(limit)
        
        result = db.execute(text(base_query), params)
        readings_data = result.fetchall()
        
        # Procesar resultados
        readings = []
        risk_colors = settings.risk_levels
        
        for row in readings_data:
            risk_level = row.risk_level or "normal"
            risk_color = risk_colors.get(risk_level, {}).get("color", "#22C55E")
            
            reading = ReadingResponse(
                id=row.id,
                station_id=row.station_id,
                timestamp=row.timestamp,
                water_level_m=row.water_level_m,
                flow_rate_cms=row.flow_rate_cms,
                temperature_c=row.temperature_c,
                risk_level=risk_level,
                risk_color=risk_color,
                trend="stable",  # TODO: calcular tendencia
                change_rate=None,  # TODO: calcular tasa de cambio
                source=row.source,
                quality_flag=row.quality_flag,
                created_at=row.created_at
            )
            readings.append(reading)
        
        # Metadatos de paginación
        pagination = {
            "total_returned": len(readings),
            "limit": limit,
            "has_more": len(readings) == limit
        }
        
        metadata = {
            "query_station_id": station_id,
            "query_nwsli_id": nwsli_id,
            "query_from": from_time,
            "query_to": to_time,
            "order": order
        }
        
        return LevelsResponse(
            success=True,
            data=readings,
            pagination=pagination,
            metadata=metadata
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error obteniendo lecturas: {str(e)}"
        )

@router.get("/latest", response_model=List[RealTimeReading])
async def get_latest_levels(
    stations: Optional[str] = Query(None, description="Lista de estaciones separadas por coma"),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings)
):
    """
    Obtener las últimas lecturas de todas las estaciones o estaciones específicas.
    
    - **stations**: Lista opcional de códigos NWSLI separados por coma (ej: "CHIH3,SANH3")
    """
    try:
        # Query para últimas lecturas
        base_query = """
        SELECT DISTINCT ON (s.id)
            hr.station_id,
            s.nwsli_id,
            hr.timestamp,
            hr.water_level_m,
            calculate_risk_level(hr.water_level_m, s.nwsli_id) as risk_level,
            s.name as station_name
        FROM hydrologic_readings hr
        JOIN stations s ON hr.station_id = s.id
        WHERE s.status = 'active'
        """
        
        params = []
        
        # Filtrar estaciones específicas si se proporciona
        if stations:
            station_list = [s.strip().upper() for s in stations.split(",")]
            placeholders = ",".join(["%s"] * len(station_list))
            base_query += f" AND UPPER(s.nwsli_id) IN ({placeholders})"
            params.extend(station_list)
        
        base_query += """
        ORDER BY s.id, hr.timestamp DESC
        """
        
        result = db.execute(text(base_query), params)
        latest_data = result.fetchall()
        
        # Población en riesgo por estación (datos del Martes S1)
        population_map = {
            "CHIH3": 150000,  # Ulúa - Chinda
            "SANH3": 180000,  # Ulúa - Santiago
            "RCHH3": 120000   # Chamelecón - El Tablón
        }
        
        # Procesar resultados
        latest_readings = []
        risk_colors = settings.risk_levels
        
        for row in latest_data:
            risk_level = row.risk_level or "normal"
            risk_color = risk_colors.get(risk_level, {}).get("color", "#22C55E")
            
            # Calcular población en riesgo
            base_population = population_map.get(row.nwsli_id, 0)
            if risk_level in ["critical", "very_high"]:
                population_at_risk = base_population
            elif risk_level == "high":
                population_at_risk = int(base_population * 0.7)
            elif risk_level == "moderate":
                population_at_risk = int(base_population * 0.4)
            else:
                population_at_risk = 0
            
            reading = RealTimeReading(
                station_id=row.station_id,
                nwsli_id=row.nwsli_id,
                timestamp=row.timestamp,
                level=row.water_level_m,
                risk=risk_level,
                color=risk_color,
                trend="stable",  # TODO: calcular tendencia
                population_at_risk=population_at_risk
            )
            latest_readings.append(reading)
        
        return latest_readings
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error obteniendo últimas lecturas: {str(e)}"
        )

@router.get("/timeseries/{station_id}")
async def get_time_series(
    station_id: int,
    hours: int = Query(24, le=168, description="Horas hacia atrás (max: 168 = 1 semana)"),
    interval: str = Query("1h", description="Intervalo de agrupación (1h, 3h, 6h)"),
    db: Session = Depends(get_db)
):
    """
    Obtener serie temporal de una estación para gráficos.
    
    - **station_id**: ID de la estación
    - **hours**: Horas hacia atrás desde ahora (máximo 168 = 1 semana)
    - **interval**: Intervalo de agrupación de datos
    """
    try:
        # Validar intervalo
        valid_intervals = {"1h": 1, "3h": 3, "6h": 6, "12h": 12}
        if interval not in valid_intervals:
            raise HTTPException(
                status_code=400,
                detail=f"Intervalo inválido. Opciones: {list(valid_intervals.keys())}"
            )
        
        # Calcular tiempo de inicio
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(hours=hours)
        
        # Query para series temporales con agrupación
        query = """
        SELECT 
            date_trunc('hour', hr.timestamp) + 
            interval '%s hour' * floor(extract(hour from hr.timestamp) / %s) as time_bucket,
            AVG(hr.water_level_m) as avg_level,
            MIN(hr.water_level_m) as min_level,
            MAX(hr.water_level_m) as max_level,
            COUNT(*) as reading_count,
            s.nwsli_id,
            s.name
        FROM hydrologic_readings hr
        JOIN stations s ON hr.station_id = s.id
        WHERE hr.station_id = %s 
        AND hr.timestamp >= %s 
        AND hr.timestamp <= %s
        GROUP BY time_bucket, s.nwsli_id, s.name
        ORDER BY time_bucket
        """
        
        interval_hours = valid_intervals[interval]
        result = db.execute(
            text(query), 
            (interval_hours, interval_hours, station_id, start_time, end_time)
        )
        timeseries_data = result.fetchall()
        
        # Procesar para respuesta
        data_points = []
        for row in timeseries_data:
            # Determinar nivel de riesgo basado en promedio
            risk_level = "normal"  # TODO: usar función calculate_risk_level
            
            data_points.append({
                "timestamp": row.time_bucket,
                "value": float(row.avg_level),
                "min_value": float(row.min_level),
                "max_value": float(row.max_level), 
                "risk_level": risk_level,
                "reading_count": row.reading_count
            })
        
        return {
            "success": True,
            "data": {
                "station_id": station_id,
                "station_nwsli_id": timeseries_data[0].nwsli_id if timeseries_data else None,
                "station_name": timeseries_data[0].name if timeseries_data else None,
                "interval": interval,
                "period_hours": hours,
                "data_points": data_points,
                "total_points": len(data_points)
            },
            "timestamp": datetime.utcnow()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error obteniendo serie temporal: {str(e)}"
        )