-- ============================================================================
-- SCRIPT DE VALIDACIÓN POSTGRESQL - CMIPRO
-- Archivo: test_database.sql
-- Propósito: Validar que todo funciona correctamente
-- ============================================================================

-- 1. Información de conexión
SELECT 
    'Conexión exitosa a PostgreSQL' as status,
    version() as postgres_version,
    current_database() as database,
    current_user as user,
    now() as timestamp;

-- 2. Verificar extensiones instaladas
SELECT name, default_version, installed_version 
FROM pg_available_extensions 
WHERE name IN ('uuid-ossp', 'pg_stat_statements')
ORDER BY name;

-- 3. Verificar tablas creadas
SELECT 
    schemaname,
    tablename,
    tableowner,
    hasindexes,
    hasrules,
    hastriggers
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- 4. Verificar estaciones cargadas
SELECT 
    station_id,
    station_name,
    river_name,
    nesdis_id,
    threshold_critical,
    population_risk_critical,
    is_active
FROM stations
ORDER BY station_id;

-- 5. Contar registros por tabla
SELECT 
    'stations' as table_name, COUNT(*) as records FROM stations
UNION ALL
SELECT 
    'hydrologic_readings', COUNT(*) FROM hydrologic_readings
UNION ALL
SELECT 
    'alerts', COUNT(*) FROM alerts
UNION ALL
SELECT 
    'users', COUNT(*) FROM users
UNION ALL
SELECT 
    'ai_news', COUNT(*) FROM ai_news
ORDER BY table_name;

-- 6. Probar función calculate_risk_level - Nivel CRÍTICO
SELECT 
    'PRUEBA FUNCIÓN - NIVEL CRÍTICO' as test_name,
    'CHIH3' as station_id,
    13.5 as test_level,
    *
FROM calculate_risk_level('CHIH3', 13.5);

-- 7. Probar función calculate_risk_level - Nivel ALTO
SELECT 
    'PRUEBA FUNCIÓN - NIVEL ALTO' as test_name,
    'SANH3' as station_id,
    8.5 as test_level,
    *
FROM calculate_risk_level('SANH3', 8.5);

-- 8. Probar función calculate_risk_level - Nivel NORMAL
SELECT 
    'PRUEBA FUNCIÓN - NIVEL NORMAL' as test_name,
    'RCHH3' as station_id,
    1.8 as test_level,
    *
FROM calculate_risk_level('RCHH3', 1.8);

-- 9. Insertar datos de prueba usando función
SELECT 
    'INSERCIÓN PRUEBA CHIH3' as test_name,
    insert_hydrologic_reading(
        'CHIH3',
        CURRENT_TIMESTAMP - INTERVAL '10 minutes',
        9.2,
        145.5,
        'good',
        '{"source": "test", "method": "automated", "quality_score": 0.95}'::jsonb
    ) as reading_id;

SELECT 
    'INSERCIÓN PRUEBA SANH3' as test_name,
    insert_hydrologic_reading(
        'SANH3',
        CURRENT_TIMESTAMP - INTERVAL '5 minutes',
        4.8,
        78.2,
        'fair',
        '{"source": "test", "method": "automated", "quality_score": 0.87}'::jsonb
    ) as reading_id;

SELECT 
    'INSERCIÓN PRUEBA RCHH3' as test_name,
    insert_hydrologic_reading(
        'RCHH3',
        CURRENT_TIMESTAMP,
        2.1,
        NULL,
        'good',
        '{"source": "test", "method": "manual"}'::jsonb
    ) as reading_id;

-- 10. Verificar datos insertados
SELECT 
    'DATOS INSERTADOS' as verification,
    station_id,
    water_level_m,
    risk_level,
    population_at_risk,
    alert_triggered,
    timestamp_utc,
    data_quality
FROM hydrologic_readings
WHERE station_id IN ('CHIH3', 'SANH3', 'RCHH3')
ORDER BY timestamp_utc DESC
LIMIT 5;

-- 11. Probar vista dashboard_summary
SELECT 
    'VISTA DASHBOARD' as test_name,
    station_id,
    station_name,
    current_level,
    current_risk,
    population_at_risk,
    data_status
FROM dashboard_summary
ORDER BY station_id;

-- 12. Probar función get_latest_readings
SELECT 
    'FUNCIÓN ÚLTIMAS LECTURAS' as test_name,
    *
FROM get_latest_readings(24)
ORDER BY station_id;

-- 13. Verificar índices creados
SELECT 
    'ÍNDICES CREADOS' as verification,
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename IN ('hydrologic_readings', 'stations', 'alerts', 'users')
  AND schemaname = 'public'
ORDER BY tablename, indexname;

-- 14. Verificar triggers
SELECT 
    'TRIGGERS CREADOS' as verification,
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- 15. Estadísticas de rendimiento
SELECT 
    'ESTADÍSTICAS TABLAS' as verification,
    schemaname,
    tablename,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes,
    n_live_tup as live_rows
FROM pg_stat_user_tables
WHERE tablename IN ('hydrologic_readings', 'stations', 'alerts', 'users')
ORDER BY tablename;

-- 16. Verificar constraints
SELECT 
    'CONSTRAINTS ACTIVOS' as verification,
    conname as constraint_name,
    conrelid::regclass as table_name,
    contype as constraint_type
FROM pg_constraint
WHERE connamespace = 'public'::regnamespace
  AND contype IN ('c', 'f', 'p', 'u')  -- check, foreign key, primary key, unique
ORDER BY conrelid::regclass::text, conname;

-- 17. Tamaño de base de datos
SELECT 
    'TAMAÑO BASE DE DATOS' as info,
    pg_size_pretty(pg_database_size(current_database())) as database_size;

-- 18. Tamaño por tabla
SELECT 
    'TAMAÑO POR TABLA' as info,
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- 19. Probar consulta de rendimiento
EXPLAIN ANALYZE 
SELECT 
    station_id, 
    water_level_m, 
    risk_level, 
    timestamp_utc
FROM hydrologic_readings 
WHERE station_id = 'CHIH3' 
  AND timestamp_utc > CURRENT_TIMESTAMP - INTERVAL '24 hours'
ORDER BY timestamp_utc DESC
LIMIT 10;

-- 20. Estado final del testing
SELECT 
    'TESTING COMPLETADO EXITOSAMENTE' as final_status,
    COUNT(DISTINCT tablename) as total_tables,
    NOW() as completed_at
FROM pg_tables 
WHERE schemaname = 'public';

-- ============================================================================
-- RESULTADOS ESPERADOS
-- ============================================================================
/*
RESULTADOS ESPERADOS:

✅ Conexión exitosa a PostgreSQL 16.4
✅ Extensiones uuid-ossp y pg_stat_statements instaladas  
✅ 5 tablas principales creadas
✅ 3 estaciones iniciales insertadas (CHIH3, SANH3, RCHH3)
✅ Función calculate_risk_level operativa (3 niveles probados)
✅ Función insert_hydrologic_reading funcional
✅ 3 lecturas de prueba insertadas correctamente
✅ Vista dashboard_summary mostrando datos actuales
✅ Índices optimizados creados (4+ índices por tabla crítica)
✅ Triggers automáticos para updated_at
✅ Constraints de integridad validados
✅ Base de datos <5MB inicialmente
✅ Consultas optimizadas <100ms

ACCIONES SI HAY ERRORES:
- Conexión fallida: Verificar Security Groups y credenciales
- Tablas no creadas: Revisar logs PostgreSQL en CloudWatch
- Funciones no operativas: Verificar sintaxis PL/pgSQL
- Rendimiento lento: Verificar índices y EXPLAIN ANALYZE
- Datos no insertados: Verificar constraints y tipos de datos
*/