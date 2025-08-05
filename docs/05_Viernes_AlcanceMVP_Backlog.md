
# Viernes – Semana 0: Alcance MVP y Backlog

## 1. Definición del MVP

El Producto Mínimo Viable (MVP) es la primera versión funcional de la plataforma. Su objetivo es permitir el monitoreo de ríos críticos en Honduras con alertas y suscripciones activas.

### Alcance funcional de la versión 1.0:

| Módulo         | Descripción                                                                 |
|----------------|-----------------------------------------------------------------------------|
| 🛰 Ingesta de datos NOAA | Descargar, filtrar y parsear datos de las estaciones CHIH3, SANH3 y RCHH3 desde el endpoint NOAA HADS |
| 🧠 Backend API  | Endpoints REST para entregar datos estructurados (`/stations`, `/levels`, `/alerts`) |
| 📊 Frontend UI  | Dashboard responsivo que muestra estaciones, semáforo de riesgo y gráficas de nivel |
| ⚠️ Alertas      | Emisión de notificación sonora y browser push cuando el nivel supera umbral crítico |
| 🔐 Autenticación | Login, registro y recuperación de contraseña con Firebase Auth              |
| 💳 Suscripciones | Stripe Checkout para pagos mensuales recurrentes ($5)                      |
| 🧰 Infraestructura | Despliegue gratuito en AWS Free Tier: S3, CloudFront, Lambda, RDS, WAF, etc. |

---

## 2. Backlog inicial del proyecto

### Clasificación por áreas

| Categoría      | Descripción |
|----------------|-------------|
| Backend API    | Lógica y endpoints de FastAPI |
| Ingesta de datos | Lectura de fuentes NOAA/USGS |
| Frontend UI    | Interfaz en Next.js y Tailwind |
| Autenticación  | Firebase Auth |
| Pagos          | Stripe |
| Infraestructura| AWS + Terraform/CloudFormation |
| Diseño         | Figma, mockups, paleta |
| DevOps         | Repositorio, CI/CD, monitoreo |

---

### Formato Kanban sugerido

#### 📋 Por hacer

| Tarea                                                       | Categoría       |
|-------------------------------------------------------------|------------------|
| Crear endpoint `/stations` en FastAPI                       | Backend API      |
| Crear endpoint `/levels?station_id=&from=&to=`              | Backend API      |
| Implementar función Lambda para polling NOAA cada 5 min     | Ingesta de datos |
| Parsear datos HADS y filtrar CHIH3, SANH3, RCHH3            | Ingesta de datos |
| Conectar Firebase Auth con Next.js                          | Autenticación    |
| Crear semáforo de niveles en tarjetas                       | Frontend UI      |
| Gráfico de nivel de río con Recharts                        | Frontend UI      |
| Stripe Checkout básico (pago único o recurrente)            | Pagos            |
| Configurar WAF + HTTPS/TLS                                  | Infraestructura  |
| Diseño de alertas sonoras/browser push                      | Frontend UI      |

#### 🚧 En progreso

| Tarea                                 | Categoría |
|---------------------------------------|-----------|
| Bitácora de días previos (Lunes–Jueves) | Documentación |
| Configuración inicial de AWS           | Infraestructura |
| Carpeta base Terraform                 | DevOps |

#### 🧪 En pruebas

| Tarea                        | Categoría |
|-----------------------------|-----------|
| Pruebas de terminación de recursos AWS | Infraestructura |

#### ✅ Terminado

| Tarea                                               | Categoría    |
|-----------------------------------------------------|--------------|
| Registro de dominio `cmiweather.com`                | Infraestructura |
| Creación de repositorio Git y ramas `main` / `dev`  | DevOps       |
| Diseño preliminar en Figma (dashboard, login)       | Diseño       |
| Activación de alerta de presupuesto en AWS          | Infraestructura |

#### 💡 Ideas / Fase 2

| Idea                                                      | Categoría |
|-----------------------------------------------------------|-----------|
| Predicciones con Prophet / ARIMA                          | IA        |
| Integración de mapas Leaflet con zonas de riesgo          | Frontend  |
| Automatización de noticias con OpenAI (noticias IA)       | Contenido |
| Alerta por Telegram / WhatsApp                            | Comunicación |
| Registro de reportes ciudadanos con fotos geolocalizadas  | UX        |
