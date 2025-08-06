# Metodología de Cálculo de Riesgo Hidrológico
## Algoritmos y Procedimientos Técnicos - CMIPRO

---

## 🧮 Algoritmo Principal de Evaluación

### Función Base de Cálculo
```python
def calcular_nivel_riesgo(nivel_actual, estacion_id, epoca_ano, timestamp=None):
    """
    Calcula el nivel de riesgo hidrológico basado en umbrales dinámicos
    
    Args:
        nivel_actual (float): Nivel de agua actual en metros
        estacion_id (str): Identificador de la estación (CHIH3, SANH3, RCHH3)
        epoca_ano (str): 'dry', 'rainy', 'peak_rainy'
        timestamp (datetime): Timestamp para logs y auditoría
    
    Returns:
        dict: {
            'nivel': str,           # normal, low, moderate, high, very_high, critical
            'color': str,           # Código hexadecimal del color
            'accion': str,          # Acción recomendada
            'poblacion_riesgo': int # Estimado de personas en riesgo
        }
    """
    
    # Obtener umbrales ajustados por época
    umbrales = obtener_umbrales_ajustados(estacion_id, epoca_ano)
    
    # Evaluación de nivel
    if nivel_actual <= umbrales['normal_max']:
        return {
            'nivel': 'normal',
            'color': '#22C55E',
            'accion': 'monitoreo_rutinario',
            'poblacion_riesgo': 0
        }
    elif nivel_actual <= umbrales['low_max']:
        return {
            'nivel': 'low',
            'color': '#84CC16',
            'accion': 'vigilancia_continua',
            'poblacion_riesgo': 5000
        }
    elif nivel_actual <= umbrales['moderate_max']:
        return {
            'nivel': 'moderate',
            'color': '#EAB308',
            'accion': 'monitoreo_intensivo',
            'poblacion_riesgo': 25000
        }
    elif nivel_actual <= umbrales['high_max']:
        return {
            'nivel': 'high',
            'color': '#F97316',
            'accion': 'preparacion_evacuacion',
            'poblacion_riesgo': 100000
        }
    elif nivel_actual <= umbrales['very_high_max']:
        return {
            'nivel': 'very_high',
            'color': '#DC2626',
            'accion': 'evacuacion_preventiva',
            'poblacion_riesgo': 250000
        }
    else:
        return {
            'nivel': 'critical',
            'color': '#EF4444',
            'accion': 'evacuacion_inmediata',
            'poblacion_riesgo': 400000
        }
```

---

## 📊 Sistema de Umbrales Dinámicos

### Cálculo de Ajuste Estacional
```python
def obtener_umbrales_ajustados(estacion_id, epoca_ano):
    """
    Aplica factores de ajuste estacional a los umbrales base
    """
    umbrales_base = {
        'normal_max': 2.0,
        'low_max': 4.0,
        'moderate_max': 6.0,
        'high_max': 8.0,
        'very_high_max': 12.0
    }
    
    # Factores de ajuste por época
    factores = {
        'dry': 1.0,          # Sin ajuste
        'rainy': 0.9,        # Reducción 10%
        'peak_rainy': 0.85   # Reducción 15%
    }
    
    factor = factores.get(epoca_ano, 1.0)
    
    return {
        umbral: valor * factor 
        for umbral, valor in umbrales_base.items()
    }
```

### Determinación Automática de Época
```python
def determinar_epoca_ano(timestamp):
    """
    Determina la época del año basada en el mes
    """
    mes = timestamp.month
    
    if mes in [12, 1, 2, 3, 4, 5]:  # Diciembre - Mayo
        return 'dry'
    elif mes in [9, 10]:            # Septiembre - Octubre
        return 'peak_rainy'
    else:                           # Junio - Agosto, Noviembre
        return 'rainy'
```

---

## ⏱️ Sistema de Validación Temporal

### Filtro Anti-Fluctuaciones
```python
def validar_sostenimiento_nivel(estacion_id, nivel_actual, nivel_calculado):
    """
    Valida que el nivel se sostenga el tiempo mínimo antes de activar alertas
    """
    tiempos_minimos = {
        'critical': 0,      # Inmediato
        'very_high': 120,   # 2 minutos
        'high': 300,        # 5 minutos
        'moderate': 600,    # 10 minutos
        'low': 900          # 15 minutos
    }
    
    tiempo_requerido = tiempos_minimos.get(nivel_calculado, 0)
    
    # Verificar historial de lecturas
    historial = obtener_historial_reciente(estacion_id, tiempo_requerido)
    
    # Validar que todas las lecturas cumplan el umbral
    for lectura in historial:
        if calcular_nivel_riesgo(lectura.nivel, estacion_id, 
                               determinar_epoca_ano(lectura.timestamp))['nivel'] != nivel_calculado:
            return False
    
    return True
```

### Control de Frecuencia de Alertas
```python
def calcular_frecuencia_alerta(nivel_riesgo):
    """
    Determina la frecuencia de notificaciones según el nivel
    """
    frecuencias = {
        'critical': 30,     # 30 segundos
        'very_high': 120,   # 2 minutos  
        'high': 300,        # 5 minutos
        'moderate': 600,    # 10 minutos
        'low': 1800         # 30 minutos
    }
    
    return frecuencias.get(nivel_riesgo, 3600)  # Default: 1 hora
```

---

## 🎯 Estimación de Poblaciones en Riesgo

### Modelo de Impacto Poblacional
```python
def estimar_poblacion_riesgo(estacion_id, nivel_agua):
    """
    Estima la población en riesgo basada en modelos geoespaciales
    """
    
    # Mapas de población por zona de inundación
    zonas_impacto = {
        'CHIH3': {  # Río Ulúa - Chinda
            2: 0,      # 0-2m: Sin riesgo
            4: 3000,   # 2-4m: Comunidades rurales
            6: 15000,  # 4-6m: Agricultura + caseríos
            8: 75000,  # 6-8m: Sectores urbanos periféricos
            12: 200000, # 8-12m: Ciudades principales sectores
            15: 400000  # >12m: Evacuación masiva regional
        },
        'SANH3': {  # Río Ulúa - Santiago
            2: 0,
            4: 2000,
            6: 10000,
            8: 50000,
            12: 150000,
            15: 300000
        },
        'RCHH3': {  # Río Chamelecón - El Tablón
            2: 0,
            4: 5000,
            6: 20000,
            8: 80000,
            12: 180000,
            15: 350000
        }
    }
    
    mapa = zonas_impacto.get(estacion_id, {})
    
    # Encontrar el rango de impacto más cercano
    for umbral in sorted(mapa.keys()):
        if nivel_agua <= umbral:
            return mapa[umbral]
    
    # Si supera todos los umbrales, retornar el máximo
    return max(mapa.values()) if mapa else 0
```

### Agregación Multi-Estación
```python
def calcular_riesgo_regional():
    """
    Calcula el riesgo agregado considerando todas las estaciones
    """
    estaciones = ['CHIH3', 'SANH3', 'RCHH3']
    riesgo_maximo = 'normal'
    poblacion_total = 0
    
    for estacion in estaciones:
        nivel_actual = obtener_ultimo_nivel(estacion)
        epoca = determinar_epoca_ano(datetime.now())
        
        riesgo_estacion = calcular_nivel_riesgo(nivel_actual, estacion, epoca)
        poblacion_total += riesgo_estacion['poblacion_riesgo']
        
        # El riesgo regional es el máximo de todas las estaciones
        if es_mayor_riesgo(riesgo_estacion['nivel'], riesgo_maximo):
            riesgo_maximo = riesgo_estacion['nivel']
    
    return {
        'nivel_regional': riesgo_maximo,
        'poblacion_total_riesgo': poblacion_total,
        'estaciones_criticas': obtener_estaciones_por_nivel('critical')
    }
```

---

## 🔄 Sistema de Retroalimentación y Calibración

### Validación Post-Evento
```python
def validar_precision_sistema(evento_id):
    """
    Analiza la precisión del sistema después de un evento real
    """
    evento = obtener_evento_historico(evento_id)
    
    metricas = {
        'tiempo_alerta_temprana': None,
        'precision_nivel_maximo': None,
        'evacuaciones_correlacionadas': None,
        'falsos_positivos': 0,
        'falsos_negativos': 0
    }
    
    # Analizar tiempo de alerta vs evento real
    primera_alerta = evento.primera_alerta_critica
    pico_evento = evento.nivel_maximo_alcanzado
    
    if primera_alerta and pico_evento:
        metricas['tiempo_alerta_temprana'] = (
            pico_evento.timestamp - primera_alerta.timestamp
        ).total_seconds() / 3600  # Horas
    
    # Analizar precisión de predicción
    nivel_predicho = primera_alerta.nivel_predicho if primera_alerta else None
    nivel_real = pico_evento.nivel if pico_evento else None
    
    if nivel_predicho and nivel_real:
        metricas['precision_nivel_maximo'] = abs(nivel_real - nivel_predicho)
    
    return metricas
```

### Ajuste Automático de Umbrales
```python
def ajustar_umbrales_basado_en_eventos():
    """
    Ajusta umbrales basándose en eventos históricos recientes
    """
    eventos_recientes = obtener_eventos_ultimos_2_anos()
    
    for evento in eventos_recientes:
        # Analizar correlación entre nivel y evacuaciones reales
        if evento.evacuaciones_copeco > 50000 and evento.nivel_maximo < 12:
            # Si hubo evacuaciones masivas con nivel <12m, ajustar umbral crítico
            sugerir_ajuste_umbral('critical', evento.nivel_maximo - 0.5)
        
        elif evento.evacuaciones_copeco < 10000 and evento.nivel_maximo > 8:
            # Si no hubo evacuaciones significativas con nivel >8m, revisar umbral muy alto
            sugerir_ajuste_umbral('very_high', evento.nivel_maximo + 0.5)
    
    return generar_reporte_ajustes()
```

---

## 🚨 Algoritmos de Alerta y Notificación

### Motor de Decisión de Alertas
```python
def evaluar_necesidad_alerta(estacion_id, nivel_actual):
    """
    Determina si se debe enviar una alerta basada en múltiples factores
    """
    epoca = determinar_epoca_ano(datetime.now())
    riesgo_actual = calcular_nivel_riesgo(nivel_actual, estacion_id, epoca)
    
    # Verificar sostenimiento temporal
    if not validar_sostenimiento_nivel(estacion_id, nivel_actual, riesgo_actual['nivel']):
        return {'enviar_alerta': False, 'razon': 'nivel_no_sostenido'}
    
    # Verificar frecuencia para evitar spam
    ultima_alerta = obtener_ultima_alerta(estacion_id, riesgo_actual['nivel'])
    frecuencia_requerida = calcular_frecuencia_alerta(riesgo_actual['nivel'])
    
    if ultima_alerta and (datetime.now() - ultima_alerta.timestamp).total_seconds() < frecuencia_requerida:
        return {'enviar_alerta': False, 'razon': 'frecuencia_no_cumplida'}
    
    # Evaluar tendencia (subiendo/bajando)
    tendencia = calcular_tendencia_nivel(estacion_id, ventana_minutos=30)
    
    return {
        'enviar_alerta': True,
        'nivel': riesgo_actual['nivel'],
        'tendencia': tendencia,
        'poblacion_riesgo': riesgo_actual['poblacion_riesgo'],
        'accion_recomendada': riesgo_actual['accion']
    }
```

### Generación de Mensajes Contextuales
```python
def generar_mensaje_alerta(alerta_data, estacion_id):
    """
    Genera mensaje de alerta personalizado según contexto
    """
    templates = {
        'critical': {
            'titulo': '🚨 EVACUACIÓN INMEDIATA',
            'mensaje': 'Nivel CRÍTICO {nivel:.1f}m en {ubicacion}. EVACUAR AHORA. {poblacion:,} personas en riesgo inmediato.',
            'sonido': 'sirena_emergencia',
            'prioridad': 'MAXIMA'
        },
        'very_high': {
            'titulo': '⚠️ EVACUACIÓN PREVENTIVA',
            'mensaje': 'Nivel MUY ALTO {nivel:.1f}m en {ubicacion}. Iniciar evacuación preventiva. {poblacion:,} personas en riesgo.',
            'sonido': 'alerta_alta',
            'prioridad': 'ALTA'
        },
        'high': {
            'titulo': '🟠 PREPARAR EVACUACIÓN',
            'mensaje': 'Nivel ALTO {nivel:.1f}m en {ubicacion}. Preparar evacuación. {poblacion:,} personas en alerta.',
            'sonido': 'alerta_media',
            'prioridad': 'MEDIA'
        },
        'moderate': {
            'titulo': '🟡 MONITOREO INTENSIVO',
            'mensaje': 'Nivel MODERADO {nivel:.1f}m en {ubicacion}. Vigilancia continua. {poblacion:,} personas en observación.',
            'sonido': 'notificacion',
            'prioridad': 'BAJA'
        }
    }
    
    template = templates.get(alerta_data['nivel'], templates['moderate'])
    ubicacion = obtener_nombre_ubicacion(estacion_id)
    
    return {
        'titulo': template['titulo'],
        'mensaje': template['mensaje'].format(
            nivel=alerta_data['nivel_agua'],
            ubicacion=ubicacion,
            poblacion=alerta_data['poblacion_riesgo']
        ),
        'sonido': template['sonido'],
        'prioridad': template['prioridad'],
        'timestamp': datetime.now(),
        'tendencia': alerta_data.get('tendencia', 'estable')
    }
```

---

## 📈 Algoritmos de Tendencia y Predicción

### Cálculo de Tendencias
```python
def calcular_tendencia_nivel(estacion_id, ventana_minutos=30):
    """
    Calcula la tendencia del nivel de agua usando regresión lineal
    """
    import numpy as np
    from sklearn.linear_model import LinearRegression
    
    # Obtener datos de la ventana temporal
    desde = datetime.now() - timedelta(minutes=ventana_minutos)
    lecturas = obtener_lecturas_periodo(estacion_id, desde, datetime.now())
    
    if len(lecturas) < 3:
        return {'tendencia': 'insuficientes_datos', 'pendiente': 0}
    
    # Preparar datos para regresión
    timestamps = np.array([(r.timestamp - lecturas[0].timestamp).total_seconds() 
                          for r in lecturas]).reshape(-1, 1)
    niveles = np.array([r.nivel for r in lecturas])
    
    # Calcular regresión lineal
    modelo = LinearRegression()
    modelo.fit(timestamps, niveles)
    
    pendiente = modelo.coef_[0]  # m/segundo
    pendiente_por_hora = pendiente * 3600  # m/hora
    
    # Clasificar tendencia
    if abs(pendiente_por_hora) < 0.1:
        tendencia = 'estable'
    elif pendiente_por_hora > 0.5:
        tendencia = 'subiendo_rapido'
    elif pendiente_por_hora > 0.1:
        tendencia = 'subiendo'
    elif pendiente_por_hora < -0.5:
        tendencia = 'bajando_rapido'
    else:
        tendencia = 'bajando'
    
    return {
        'tendencia': tendencia,
        'pendiente_hora': pendiente_por_hora,
        'confianza': modelo.score(timestamps, niveles)
    }
```

### Predicción a Corto Plazo (Fase 2)
```python
def predecir_nivel_futuro(estacion_id, horas_adelante=1):
    """
    Predice el nivel futuro basándose en tendencias históricas
    """
    # Obtener datos históricos (últimas 24 horas)
    datos_historicos = obtener_lecturas_ultimas_horas(estacion_id, 24)
    
    if len(datos_historicos) < 12:  # Mínimo 12 lecturas
        return {'prediccion': None, 'confianza': 0}
    
    # Usar Prophet para predicción (implementación futura)
    from fbprophet import Prophet
    
    # Preparar datos para Prophet
    df = pd.DataFrame({
        'ds': [lectura.timestamp for lectura in datos_historicos],
        'y': [lectura.nivel for lectura in datos_historicos]
    })
    
    # Crear y entrenar modelo
    modelo = Prophet(
        changepoint_prior_scale=0.05,
        seasonality_prior_scale=10.0,
        holidays_prior_scale=10.0,
        seasonality_mode='multiplicative'
    )
    modelo.fit(df)
    
    # Generar predicción
    futuro = modelo.make_future_dataframe(periods=horas_adelante, freq='H')
    prediccion = modelo.predict(futuro)
    
    nivel_predicho = prediccion.iloc[-1]['yhat']
    intervalo_confianza = (
        prediccion.iloc[-1]['yhat_lower'],
        prediccion.iloc[-1]['yhat_upper']
    )
    
    return {
        'nivel_predicho': nivel_predicho,
        'intervalo_confianza': intervalo_confianza,
        'confianza': calcular_confianza_prediccion(prediccion),
        'tiempo_prediccion': horas_adelante
    }
```

---

## 🔍 Validación y Control de Calidad

### Validación de Datos de Entrada
```python
def validar_lectura_sensor(nivel, estacion_id, timestamp):
    """
    Valida que la lectura del sensor sea consistente
    """
    validaciones = {
        'rango_fisico': False,
        'continuidad_temporal': False,
        'consistencia_regional': False
    }
    
    # 1. Validar rango físico posible
    if 0 <= nivel <= 25:  # Rango físico posible en Honduras
        validaciones['rango_fisico'] = True
    
    # 2. Validar continuidad temporal (cambio máximo 2m/hora)
    ultima_lectura = obtener_ultima_lectura_valida(estacion_id)
    if ultima_lectura:
        tiempo_transcurrido = (timestamp - ultima_lectura.timestamp).total_seconds() / 3600
        cambio_nivel = abs(nivel - ultima_lectura.nivel)
        
        if tiempo_transcurrido > 0 and (cambio_nivel / tiempo_transcurrido) <= 2.0:
            validaciones['continuidad_temporal'] = True
    else:
        validaciones['continuidad_temporal'] = True  # Primera lectura
    
    # 3. Validar consistencia regional (estaciones cercanas)
    estaciones_cercanas = obtener_estaciones_cercanas(estacion_id)
    lecturas_cercanas = [obtener_ultima_lectura_valida(est) for est in estaciones_cercanas]
    
    if lecturas_cercanas:
        niveles_cercanos = [l.nivel for l in lecturas_cercanas if l]
        if niveles_cercanos:
            nivel_promedio_regional = sum(niveles_cercanos) / len(niveles_cercanos)
            # Permitir variación del 50% respecto al promedio regional
            if abs(nivel - nivel_promedio_regional) <= nivel_promedio_regional * 0.5:
                validaciones['consistencia_regional'] = True
    else:
        validaciones['consistencia_regional'] = True  # No hay estaciones cercanas
    
    return {
        'valida': all(validaciones.values()),
        'validaciones': validaciones,
        'accion': 'aceptar' if all(validaciones.values()) else 'rechazar'
    }
```

### Sistema de Redundancia
```python
def obtener_lectura_con_redundancia(estacion_id):
    """
    Obtiene lectura con sistema de redundancia y fallback
    """
    fuentes = [
        {'tipo': 'noaa_primary', 'peso': 1.0},
        {'tipo': 'noaa_backup', 'peso': 0.8},
        {'tipo': 'sensor_local', 'peso': 0.6},
        {'tipo': 'estimacion_satelital', 'peso': 0.4}
    ]
    
    lecturas_validas = []
    
    for fuente in fuentes:
        try:
            lectura = obtener_lectura_fuente(estacion_id, fuente['tipo'])
            validacion = validar_lectura_sensor(lectura.nivel, estacion_id, lectura.timestamp)
            
            if validacion['valida']:
                lecturas_validas.append({
                    'nivel': lectura.nivel,
                    'peso': fuente['peso'],
                    'fuente': fuente['tipo'],
                    'timestamp': lectura.timestamp
                })
        except Exception as e:
            log_error(f"Error obteniendo lectura de {fuente['tipo']}: {e}")
    
    if not lecturas_validas:
        return None
    
    # Calcular nivel ponderado
    nivel_ponderado = sum(l['nivel'] * l['peso'] for l in lecturas_validas) / sum(l['peso'] for l in lecturas_validas)
    
    return {
        'nivel': nivel_ponderado,
        'fuentes_usadas': [l['fuente'] for l in lecturas_validas],
        'confianza': min(l['peso'] for l in lecturas_validas),
        'timestamp': max(l['timestamp'] for l in lecturas_validas)
    }
```

---

## 📊 Métricas de Rendimiento del Sistema

### KPIs de Precisión
```python
def calcular_kpis_precision():
    """
    Calcula indicadores clave de rendimiento del sistema
    """
    periodo = datetime.now() - timedelta(days=30)  # Últimos 30 días
    
    kpis = {
        'precision_alertas_criticas': calcular_precision_alertas('critical', periodo),
        'tiempo_promedio_alerta': calcular_tiempo_promedio_alerta(periodo),
        'falsos_positivos_rate': calcular_falsos_positivos_rate(periodo),
        'disponibilidad_sistema': calcular_uptime(periodo),
        'correlacion_evacuaciones': calcular_correlacion_copeco(periodo)
    }
    
    return kpis

def calcular_precision_alertas(nivel, periodo):
    """
    Calcula precisión de alertas para un nivel específico
    """
    alertas_enviadas = obtener_alertas_periodo(nivel, periodo)
    eventos_reales = obtener_eventos_reales_periodo(periodo)
    
    verdaderos_positivos = 0
    falsos_positivos = 0
    
    for alerta in alertas_enviadas:
        evento_real = buscar_evento_real_cercano(alerta, eventos_reales, ventana_horas=6)
        if evento_real and evento_real.nivel_maximo >= get_umbral_nivel(nivel):
            verdaderos_positivos += 1
        else:
            falsos_positivos += 1
    
    total_alertas = len(alertas_enviadas)
    precision = verdaderos_positivos / total_alertas if total_alertas > 0 else 0
    
    return {
        'precision': precision,
        'verdaderos_positivos': verdaderos_positivos,
        'falsos_positivos': falsos_positivos,
        'total_alertas': total_alertas
    }
```

---

## 🔧 Configuración y Mantenimiento

### Parámetros Configurables
```python
CONFIGURACION_SISTEMA = {
    'umbrales_base': {
        'normal_max': 2.0,
        'low_max': 4.0,
        'moderate_max': 6.0,
        'high_max': 8.0,
        'very_high_max': 12.0
    },
    'ajustes_estacionales': {
        'dry': 1.0,
        'rainy': 0.9,
        'peak_rainy': 0.85
    },
    'tiempos_sostenimiento': {
        'critical': 0,
        'very_high': 120,
        'high': 300,
        'moderate': 600,
        'low': 900
    },
    'frecuencias_alerta': {
        'critical': 30,
        'very_high': 120,
        'high': 300,
        'moderate': 600,
        'low': 1800
    },
    'validacion_datos': {
        'cambio_maximo_por_hora': 2.0,
        'variacion_regional_max': 0.5,
        'rango_fisico_min': 0.0,
        'rango_fisico_max': 25.0
    }
}
```

### Funciones de Mantenimiento
```python
def ejecutar_mantenimiento_diario():
    """
    Ejecuta rutinas de mantenimiento diario del sistema
    """
    tareas = [
        limpiar_datos_antiguos,
        recalcular_estadisticas,
        validar_integridad_umbrales,
        generar_reporte_precision,
        verificar_conectividad_fuentes,
        optimizar_indices_base_datos
    ]
    
    resultados = {}
    for tarea in tareas:
        try:
            resultado = tarea()
            resultados[tarea.__name__] = {'estado': 'exitoso', 'detalles': resultado}
        except Exception as e:
            resultados[tarea.__name__] = {'estado': 'error', 'error': str(e)}
    
    return resultados
```

---

*Documento técnico completo - Metodología de Cálculo de Riesgo*  
*Versión: 2.0 (Actualizada con umbrales revisados)*  
*Fecha: Martes, Semana 1*