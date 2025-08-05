# 📡 Especificación de Endpoints REST - CMIPRO API

## Base URL
- **Desarrollo**: `http://localhost:8000/api/v1`
- **Producción**: `https://api.cmiweather.com/v1`

## 🔐 Autenticación
Todos los endpoints (excepto públicos) requieren:
```
Authorization: Bearer <firebase_jwt_token>
```

---

## 📍 **1. Estaciones hidrológicas**

### `GET /stations`
Obtiene lista de todas las estaciones monitoreadas.

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Respuesta 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": "CHIH3",
      "name": "Chinda",
      "river": "Ulúa",
      "location": {
        "latitude": 15.3847,
        "longitude": -87.9547,
        "elevation": 45.0
      },
      "nesdis_id": "50401A48",
      "status": "active",
      "last_reading": "2025-08-05T14:30:00Z",
      "current_level": 2.45,
      "risk_level": "low"
    },
    {
      "id": "SANH3",
      "name": "Santiago",
      "river": "Ulúa",
      "location": {
        "latitude": 15.2941,
        "longitude": -87.9234,
        "elevation": 38.0
      },
      "nesdis_id": "50402FD2",
      "status": "active",
      "last_reading": "2025-08-05T14:30:00Z",
      "current_level": 1.89,
      "risk_level": "normal"
    },
    {
      "id": "RCHH3",
      "name": "El Tablón",
      "river": "Chamelecón",
      "location": {
        "latitude": 15.4234,
        "longitude": -88.0123,
        "elevation": 52.0
      },
      "nesdis_id": "50403CA4",
      "status": "active",
      "last_reading": "2025-08-05T14:30:00Z",
      "current_level": 3.12,
      "risk_level": "medium"
    }
  ]
}
```

---

## 📊 **2. Niveles históricos**

### `GET /levels`
Obtiene datos históricos de niveles de río.

**Query Parameters:**
- `station_id` (requerido): ID de la estación (CHIH3, SANH3, RCHH3)
- `from` (requerido): Fecha inicio ISO 8601 (ej: 2025-08-01T00:00:00Z)
- `to` (requerido): Fecha fin ISO 8601
- `interval` (opcional): 15min, 1hour, 6hour, 1day (default: 15min)

**Ejemplo:**
```
GET /levels?station_id=CHIH3&from=2025-08-01T00:00:00Z&to=2025-08-05T23:59:59Z&interval=1hour
```

**Respuesta 200:**
```json
{
  "success": true,
  "data": {
    "station_id": "CHIH3",
    "station_name": "Chinda",
    "river": "Ulúa",
    "interval": "1hour",
    "unit": "meters",
    "readings": [
      {
        "timestamp": "2025-08-01T00:00:00Z",
        "level": 2.12,
        "flow_rate": 45.6,
        "temperature": 26.5,
        "precipitation": 0.0,
        "risk_level": "normal"
      },
      {
        "timestamp": "2025-08-01T01:00:00Z",
        "level": 2.18,
        "flow_rate": 47.2,
        "temperature": 26.3,
        "precipitation": 2.5,
        "risk_level": "normal"
      }
    ],
    "count": 120,
    "thresholds": {
      "normal": 0.0,
      "low": 1.5,
      "medium": 3.0,
      "high": 4.5,
      "critical": 6.0
    }
  }
}
```

---

## ⚠️ **3. Alertas activas**

### `GET /alerts`
Obtiene alertas activas del sistema.

**Query Parameters:**
- `station_id` (opcional): filtrar por estación
- `severity` (opcional): low, medium, high, critical

**Respuesta 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": "alert_001",
      "station_id": "CHIH3",
      "station_name": "Chinda",
      "river": "Ulúa",
      "severity": "high",
      "level": 4.67,
      "threshold": 4.5,
      "message": "Nivel del río Ulúa en Chinda ha superado el umbral alto (4.5m). Nivel actual: 4.67m",
      "created_at": "2025-08-05T14:15:00Z",
      "is_active": true,
      "estimated_peak": "2025-08-05T18:30:00Z"
    }
  ]
}
```

### `POST /alerts/acknowledge`
Marca una alerta como reconocida por el usuario.

**Body:**
```json
{
  "alert_id": "alert_001",
  "user_id": "firebase_user_id"
}
```

---

## 🔮 **4. Predicciones (Fase 2)**

### `GET /forecast`
Obtiene predicciones de nivel futuro.

**Query Parameters:**
- `station_id` (requerido)
- `horizon` (opcional): 1h, 3h, 6h, 12h, 24h (default: 6h)

**Respuesta 200:**
```json
{
  "success": true,
  "data": {
    "station_id": "CHIH3",
    "forecast_generated_at": "2025-08-05T14:30:00Z",
    "horizon": "6h",
    "model": "prophet_v1",
    "confidence": 0.85,
    "predictions": [
      {
        "timestamp": "2025-08-05T15:00:00Z",
        "predicted_level": 2.52,
        "confidence_lower": 2.45,
        "confidence_upper": 2.58,
        "risk_level": "low"
      },
      {
        "timestamp": "2025-08-05T16:00:00Z",
        "predicted_level": 2.61,
        "confidence_lower": 2.49,
        "confidence_upper": 2.72,
        "risk_level": "low"
      }
    ]
  }
}
```

---

## 👤 **5. Usuario y suscripción**

### `GET /user/profile`
Obtiene perfil del usuario autenticado.

**Respuesta 200:**
```json
{
  "success": true,
  "data": {
    "user_id": "firebase_user_id",
    "email": "usuario@example.com",
    "subscription": {
      "status": "active",
      "plan": "monthly",
      "price": 5.00,
      "currency": "USD",
      "current_period_start": "2025-08-01T00:00:00Z",
      "current_period_end": "2025-09-01T00:00:00Z",
      "stripe_customer_id": "cus_xxxxx"
    },
    "preferences": {
      "notifications": {
        "email": true,
        "push": true,
        "sound": true
      },
      "alert_thresholds": {
        "CHIH3": "medium",
        "SANH3": "high",
        "RCHH3": "medium"
      }
    }
  }
}
```

---

## 📰 **6. Noticias automatizadas (Fase 2)**

### `GET /news`
Obtiene noticias meteorológicas y sísmicas generadas por IA.

**Query Parameters:**
- `category` (opcional): weather, seismic, flooding
- `limit` (opcional): número de noticias (default: 10)

**Respuesta 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": "news_001",
      "title": "Precipitaciones moderadas esperadas en Valle de Sula",
      "summary": "Las condiciones atmosféricas indican lluvias de 10-25mm en las próximas 12 horas...",
      "category": "weather",
      "generated_at": "2025-08-05T12:00:00Z",
      "sources": ["NOAA", "AccuWeather RSS"],
      "ai_confidence": 0.92
    }
  ]
}
```

---

## 🚨 **Códigos de error estándar**

```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Token de autenticación inválido o expirado",
    "details": "Firebase JWT verification failed"
  }
}
```

**Códigos comunes:**
- `400` - BAD_REQUEST: parámetros inválidos
- `401` - UNAUTHORIZED: sin autenticación válida
- `403` - FORBIDDEN: suscripción inactiva
- `404` - NOT_FOUND: recurso no encontrado
- `429` - RATE_LIMITED: demasiadas peticiones
- `500` - INTERNAL_ERROR: error del servidor