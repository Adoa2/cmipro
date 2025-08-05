# Día 4 – Jueves Semana 0  
## 🌐 Dominio, Infraestructura y Presupuesto Inicial

---

### 1. Registro de dominio

- Se adquirió el dominio `cmiweather.com` a través del proveedor Namecheap.
- La privacidad WHOIS (WhoisGuard) fue activada para proteger los datos personales del registro.
- Se desactivaron servicios innecesarios como:
  - ❌ Hosting compartido (Stellar Hosting)
  - ❌ PremiumDNS
  - ❌ Instalación de WordPress o redirección
- El DNS aún no ha sido configurado y se establecerá en producción.

**Costo total del dominio:**  
- Registro inicial: $6.49  
- ICANN fee: $0.20  
- **Total:** $6.69 USD (por 1 año)

---

### 2. Infraestructura en la nube

Se eligió una arquitectura **desacoplada y serverless**, en línea con las mejores prácticas para un SaaS moderno y escalable.  
No se utilizarán servicios tradicionales como cPanel, VPS ni servidores dedicados.

#### Componentes definidos:

| Componente           | Tecnología/Proveedor            |
|----------------------|----------------------------------|
| Frontend             | Vercel (desarrollo) / AWS S3 + CloudFront (producción) |
| Backend (API REST)   | FastAPI alojado en AWS Lambda + API Gateway |
| Base de datos        | Amazon RDS (PostgreSQL + TimescaleDB) |
| Archivos estáticos   | Amazon S3                        |
| Seguridad            | AWS WAF + Shield                 |
| CDN global           | AWS CloudFront                   |
| DNS final            | AWS Route 53                     |

Se eliminó una cuenta anterior de AWS que presentaba servicios activos (EC2, RDS) para evitar cobros no deseados.  
También se removieron buckets protegidos, instancias con políticas deny y recursos vinculados a Elastic Beanstalk.

---

### 3. Estimación de presupuesto inicial

| Recurso                         | Costo mensual estimado    |
|----------------------------------|----------------------------|
| AWS (con Free Tier activo)       | $0 – $5 USD                |
| AWS (post Free Tier)             | $30 – $45 USD              |
| OpenAI API (GPT-4 Turbo)         | $10 USD (límite de control)|
| Firebase Authentication          | $0 (hasta 10,000 MAU)      |
| Stripe (pagos)                   | Comisión variable por transacción |
| Dominio `.com`                   | $6.69 USD anual            |
| Vercel (frontend en pruebas)     | $0 USD (free tier)         |

> **Total estimado mensual (con Free Tier):** $10–15 USD  
> **Total estimado mensual (sin Free Tier):** $30–45 USD

---

### 4. Tareas realizadas

- [x] Compra de dominio y configuración mínima sin servicios innecesarios
- [x] Selección de arquitectura desacoplada basada en la nube
- [x] Limpieza y cierre de cuenta AWS anterior para evitar cobros ocultos
- [x] Evaluación financiera del proyecto en escenarios iniciales y escalados

---

### 📁 Ruta del archivo en el repositorio:

```bash
docs/04_Jueves_Dominio_Infraestructura_Presupuesto.md
