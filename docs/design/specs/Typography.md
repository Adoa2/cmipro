# Especificaciones Tipográficas CMIPRO
## Sistema Tipográfico Optimizado para Emergencias

### 🔤 Font Stack Principal

#### Fuente Primaria: Inter
```css
font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Helvetica Neue', Arial, sans-serif;
```

**Justificación de Inter:**
- ✅ Optimizada para interfaces digitales
- ✅ Excelente legibilidad en pantallas pequeñas
- ✅ Amplio rango de pesos disponibles
- ✅ Soporte completo para caracteres latinos
- ✅ Diseñada específicamente para UI/UX
- ✅ Open source y libre uso comercial

#### Fuente Secundaria: System Fonts
```css
font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', Arial, sans-serif;
```

**Uso como fallback:**
- Garantiza carga instantánea
- Consistencia con SO del usuario
- Reduce weight de la página

### 📏 Jerarquía Tipográfica

#### Desktop & Tablet (768px+)
| Nivel | Tamaño | Line Height | Peso | Letter Spacing | Uso |
|-------|--------|-------------|------|----------------|-----|
| **H1** | 40px (2.5rem) | 48px (1.2) | 700 | -0.025em | Títulos principales |
| **H2** | 32px (2rem) | 40px (1.25) | 600 | -0.02em | Títulos de sección |
| **H3** | 24px (1.5rem) | 32px (1.33) | 600 | -0.015em | Subtítulos |
| **H4** | 20px (1.25rem) | 28px (1.4) | 500 | -0.01em | Encabezados de cards |
| **H5** | 18px (1.125rem) | 26px (1.44) | 500 | 0em | Sub-encabezados |
| **H6** | 16px (1rem) | 24px (1.5) | 500 | 0em | Encabezados menores |

#### Body Text
| Tipo | Tamaño | Line Height | Peso | Uso |
|------|--------|-------------|------|-----|
| **Body Large** | 18px (1.125rem) | 28px (1.56) | 400 | Texto destacado |
| **Body** | 16px (1rem) | 24px (1.5) | 400 | Texto base |
| **Body Small** | 14px (0.875rem) | 20px (1.43) | 400 | Texto secundario |
| **Caption** | 12px (0.75rem) | 16px (1.33) | 500 | Etiquetas, metadata |
| **Overline** | 11px (0.6875rem) | 16px (1.45) | 600 | Categorías, badges |

#### Mobile (< 768px)
| Nivel | Tamaño | Line Height | Ajuste vs Desktop |
|-------|--------|-------------|-------------------|
| **H1** | 32px (2rem) | 40px (1.25) | -8px |
| **H2** | 28px (1.75rem) | 36px (1.29) | -4px |
| **H3** | 22px (1.375rem) | 30px (1.36) | -2px |
| **H4** | 18px (1.125rem) | 26px (1.44) | -2px |
| **Body** | 16px (1rem) | 24px (1.5) | Sin cambio |
| **Body Small** | 14px (0.875rem) | 20px (1.43) | Sin cambio |

### 🎯 Pesos de Fuente (Font Weights)

#### Pesos Disponibles
```css
--font-weight-normal: 400;        /* Regular/Normal */
--font-weight-medium: 500;        /* Medium */
--font-weight-semibold: 600;      /* Semibold */
--font-weight-bold: 700;          /* Bold */
```

#### Uso por Contexto
| Peso | Contexto de Uso |
|------|-----------------|
| **400 (Normal)** | Texto de cuerpo, párrafos, descripiones |
| **500 (Medium)** | Labels, captions, texto secundario destacado |
| **600 (Semibold)** | Subtítulos, encabezados de cards, navegación |
| **700 (Bold)** | Títulos principales, alertas críticas, CTAs |

### 📐 Espaciado y Líneas

#### Line Height Rules
```css
/* Títulos - Más compacto para impacto visual */
--line-height-tight: 1.2;         /* H1 */
--line-height-snug: 1.3;          /* H2, H3 */
--line-height-normal: 1.4;        /* H4, H5, H6 */

/* Texto de cuerpo - Más espacioso para legibilidad */
--line-height-relaxed: 1.5;       /* Body text */
--line-height-loose: 1.6;         /* Body large */
```

#### Letter Spacing
```css
/* Títulos grandes - Spacing negativo para cohesión */
--letter-spacing-tighter: -0.025em;  /* H1 */
--letter-spacing-tight: -0.02em;     /* H2 */
--letter-spacing-normal: 0em;        /* H3+ y body */

/* Texto pequeño - Spacing positivo para legibilidad */
--letter-spacing-wide: 0.025em;      /* Overlines, badges */
```

### 🎨 Estilos Contextuales

#### Alertas y Estados Críticos
```css
.alert-critical-text {
  font-size: 18px;
  font-weight: 700;
  line-height: 1.4;
  letter-spacing: 0.01em;
  text-transform: uppercase;
  color: var(--risk-critical);
}

.alert-high-text {
  font-size: 16px;
  font-weight: 600;
  line-height: 1.5;
  color: var(--risk-high);
}
```

#### Enlaces y Navegación
```css
.nav-link {
  font-size: 16px;
  font-weight: 500;
  line-height: 1.5;
  color: var(--text-secondary);
  text-decoration: none;
}

.nav-link:hover {
  color: var(--primary);
  text-decoration: underline;
  text-underline-offset: 4px;
}
```

#### Botones
```css
.button-text {
  font-size: 16px;
  font-weight: 600;
  line-height: 1.25;
  letter-spacing: 0.01em;
}

.button-small-text {
  font-size: 14px;
  font-weight: 500;
  line-height: 1.25;
}
```

### 📱 Consideraciones Mobile

#### Touch-Friendly Typography
- **Tamaño mínimo:** 16px para evitar zoom en iOS
- **Touch targets:** Mínimo 44x44px para elementos interactivos
- **Contrast:** Mínimo 4.5:1 para WCAG AA compliance

#### Performance Mobile
```css
/* Optimización de carga */
@font-face {
  font-family: 'Inter';
  font-display: swap; /* Muestra fallback durante carga */
  src: url('/fonts/inter-var.woff2') format('woff2-variations');
}
```

### ♿ Accesibilidad Tipográfica

#### WCAG Guidelines Compliance
- ✅ **AA Compliance:** Contraste mínimo 4.5:1
- ✅ **AAA Compliance:** Contraste mínimo 7:1 para texto pequeño
- ✅ **Zoom:** Soporta 200% zoom sin pérdida funcional
- ✅ **Screen Readers:** Jerarquía semántica correcta

#### Tamaños Mínimos Accesibles
| Contexto | Tamaño Mínimo | Justificación |
|----------|---------------|---------------|
| Texto principal | 16px | Evita zoom en mobile |
| Texto secundario | 14px | Límite de legibilidad |
| Captions/labels | 12px | Solo para metadata |
| Touch targets | 44px altura | Apple/WCAG guidelines |

### 🔧 Variables CSS Tipográficas

```css
:root {
  /* Font Families */
  --font-family-primary: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
  --font-family-system: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  
  /* Font Sizes */
  --text-xs: 0.6875rem;    /* 11px */
  --text-sm: 0.75rem;      /* 12px */
  --text-base: 0.875rem;   /* 14px */
  --text-lg: 1rem;         /* 16px */
  --text-xl: 1.125rem;     /* 18px */
  --text-2xl: 1.25rem;     /* 20px */
  --text-3xl: 1.5rem;      /* 24px */
  --text-4xl: 1.75rem;     /* 28px */
  --text-5xl: 2rem;        /* 32px */
  --text-6xl: 2.5rem;      /* 40px */
  
  /* Font Weights */
  --font-normal: 400;
  --font-medium: 500;
  --font-semibold: 600;
  --font-bold: 700;
  
  /* Line Heights */
  --leading-tight: 1.2;
  --leading-snug: 1.3;
  --leading-normal: 1.4;
  --leading-relaxed: 1.5;
  --leading-loose: 1.6;
  
  /* Letter Spacing */
  --tracking-tighter: -0.025em;
  --tracking-tight: -0.02em;
  --tracking-normal: 0em;
  --tracking-wide: 0.025em;
}
```

### 📊 Clases Utilitarias

#### Responsive Typography
```css
/* Desktop First Approach */
.text-responsive-h1 {
  font-size: 2.5rem;      /* 40px */
  line-height: 1.2;
}

@media (max-width: 767px) {
  .text-responsive-h1 {
    font-size: 2rem;       /* 32px */
    line-height: 1.25;
  }
}

/* Truncation Utilities */
.truncate {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
```

#### Estado y Contexto
```css
.text-critical {
  color: var(--risk-critical);
  font-weight: var(--font-bold);
}

.text-muted {
  color: var(--text-muted);
  font-weight: var(--font-normal);
}

.text-success {
  color: var(--success);
  font-weight: var(--font-medium);
}
```

### 🎯 Casos de Uso Específicos CMIPRO

#### Dashboard de Niveles de Río
```css
.river-level-display {
  font-size: 2rem;
  font-weight: 700;
  line-height: 1.2;
  font-variant-numeric: tabular-nums; /* Números monoespaciados */
}

.river-level-unit {
  font-size: 1.125rem;
  font-weight: 500;
  color: var(--text-secondary);
}
```

#### Alertas de Emergencia
```css
.emergency-alert {
  font-size: 1.125rem;
  font-weight: 700;
  line-height: 1.4;
  text-transform: uppercase;
  letter-spacing: 0.025em;
}
```

#### Metadata Temporal
```css
.timestamp {
  font-size: 0.875rem;
  font-weight: 400;
  color: var(--text-secondary);
  font-variant-numeric: tabular-nums;
}
```

### 📈 Loading Strategy

#### Progressive Font Loading
```css
/* Stage 1: System font immediate display */
body {
  font-family: -apple-system, BlinkMacSystemFont, sans-serif;
}

/* Stage 2: Web font with swap */
.fonts-loaded body {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
}
```

#### Performance Optimization
- **Preload:** Critical font weights (400, 600)
- **Font-display:** swap para evitar FOIT
- **Subset:** Solo caracteres latinos necesarios
- **Variable fonts:** Considerar para reducir requests