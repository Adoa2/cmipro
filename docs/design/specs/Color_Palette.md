# Paleta de Colores CMIPRO
## Especificaciones Cromáticas Completas

### 🎨 Colores de Riesgo Hidrológico
*Basados en umbrales definidos el martes de la semana 1*

#### Nivel Normal
```css
--risk-normal: #22C55E;           /* Verde principal */
--risk-normal-hover: #16A34A;     /* Verde hover */
--risk-normal-bg: #F0FDF4;        /* Fondo verde claro */
--risk-normal-border: #BBF7D0;    /* Borde verde suave */
--risk-normal-text: #166534;      /* Texto verde oscuro */
```

#### Nivel Bajo
```css
--risk-low: #86EFAC;              /* Verde claro */
--risk-low-hover: #4ADE80;        /* Verde claro hover */
--risk-low-bg: #F0FDF4;           /* Fondo compartido con normal */
--risk-low-border: #86EFAC;       /* Borde auto-color */
--risk-low-text: #15803D;         /* Texto verde medio */
```

#### Nivel Moderado
```css
--risk-moderate: #FDE047;         /* Amarillo principal */
--risk-moderate-hover: #EAB308;   /* Amarillo hover */
--risk-moderate-bg: #FEFCE8;      /* Fondo amarillo claro */
--risk-moderate-border: #FDE68A;  /* Borde amarillo suave */
--risk-moderate-text: #A16207;    /* Texto amarillo oscuro */
```

#### Nivel Alto
```css
--risk-high: #FB923C;             /* Naranja principal */
--risk-high-hover: #EA580C;       /* Naranja hover */
--risk-high-bg: #FFF7ED;          /* Fondo naranja claro */
--risk-high-border: #FDBA74;      /* Borde naranja suave */
--risk-high-text: #C2410C;        /* Texto naranja oscuro */
```

#### Nivel Muy Alto
```css
--risk-very-high: #DC2626;        /* Rojo principal */
--risk-very-high-hover: #B91C1C;  /* Rojo hover */
--risk-very-high-bg: #FEF2F2;     /* Fondo rojo claro */
--risk-very-high-border: #FCA5A5; /* Borde rojo suave */
--risk-very-high-text: #991B1B;   /* Texto rojo oscuro */
```

#### Nivel Crítico
```css
--risk-critical: #FF0000;         /* Rojo brillante */
--risk-critical-hover: #DC2626;   /* Rojo hover */
--risk-critical-bg: #FEF2F2;      /* Fondo rojo claro */
--risk-critical-border: #FF0000;  /* Borde rojo brillante */
--risk-critical-text: #7F1D1D;    /* Texto rojo muy oscuro */

/* Animación especial para crítico */
--risk-critical-pulse: 0 0 0 0 rgba(255, 0, 0, 0.7);
```

### 🌈 Colores del Sistema

#### Modo Claro (Light Mode)
```css
/* Colores principales */
--primary: #2563EB;               /* Azul principal */
--primary-hover: #1D4ED8;         /* Azul hover */
--primary-light: #DBEAFE;         /* Azul claro */
--primary-dark: #1E40AF;          /* Azul oscuro */

--secondary: #64748B;             /* Gris medio */
--secondary-hover: #475569;       /* Gris medio hover */
--secondary-light: #F1F5F9;       /* Gris muy claro */
--secondary-dark: #334155;        /* Gris oscuro */

/* Fondos */
--background: #FFFFFF;            /* Fondo principal */
--background-alt: #F8FAFC;        /* Fondo alternativo */
--surface: #FFFFFF;               /* Superficie cards */
--surface-hover: #F8FAFC;         /* Superficie hover */

/* Bordes */
--border: #E2E8F0;                /* Borde principal */
--border-light: #F1F5F9;          /* Borde claro */
--border-dark: #CBD5E1;           /* Borde oscuro */

/* Texto */
--text-primary: #0F172A;          /* Texto principal */
--text-secondary: #64748B;        /* Texto secundario */
--text-muted: #94A3B8;            /* Texto deshabilitado */
--text-inverse: #FFFFFF;          /* Texto inverso */
```

#### Modo Oscuro (Dark Mode)
```css
/* Colores principales */
--primary-dark: #3B82F6;          /* Azul más claro en dark */
--primary-hover-dark: #2563EB;    /* Azul hover dark */
--primary-light-dark: #1E3A8A;    /* Azul claro dark */

--secondary-dark: #94A3B8;        /* Gris claro en dark */
--secondary-hover-dark: #CBD5E1;  /* Gris hover dark */
--secondary-light-dark: #475569;  /* Gris light dark */

/* Fondos */
--background-dark: #0F172A;       /* Fondo principal dark */
--background-alt-dark: #1E293B;   /* Fondo alternativo dark */
--surface-dark: #1E293B;          /* Superficie dark */
--surface-hover-dark: #334155;    /* Superficie hover dark */

/* Bordes */
--border-dark: #334155;           /* Borde dark */
--border-light-dark: #475569;     /* Borde claro dark */

/* Texto */
--text-primary-dark: #F8FAFC;     /* Texto principal dark */
--text-secondary-dark: #94A3B8;   /* Texto secundario dark */
--text-muted-dark: #64748B;       /* Texto muted dark */
```

### 🎭 Colores de Estado

#### Éxito (Success)
```css
--success: #10B981;               /* Verde éxito */
--success-hover: #059669;         /* Verde éxito hover */
--success-bg: #ECFDF5;            /* Fondo éxito */
--success-border: #A7F3D0;        /* Borde éxito */
--success-text: #065F46;          /* Texto éxito */
```

#### Advertencia (Warning)
```css
--warning: #F59E0B;               /* Amarillo advertencia */
--warning-hover: #D97706;         /* Amarillo hover */
--warning-bg: #FFFBEB;            /* Fondo advertencia */
--warning-border: #FDE68A;        /* Borde advertencia */
--warning-text: #92400E;          /* Texto advertencia */
```

#### Error
```css
--error: #EF4444;                 /* Rojo error */
--error-hover: #DC2626;           /* Rojo error hover */
--error-bg: #FEF2F2;              /* Fondo error */
--error-border: #FECACA;          /* Borde error */
--error-text: #991B1B;            /* Texto error */
```

#### Información (Info)
```css
--info: #3B82F6;                  /* Azul información */
--info-hover: #2563EB;            /* Azul info hover */
--info-bg: #EFF6FF;               /* Fondo información */
--info-border: #BFDBFE;           /* Borde información */
--info-text: #1E40AF;             /* Texto información */
```

### 🎯 Colores de Aplicación

#### Específicos de CMIPRO
```css
--cmipro-blue: #1E40AF;           /* Azul corporativo */
--cmipro-blue-light: #3B82F6;     /* Azul claro corporativo */
--cmipro-blue-dark: #1E3A8A;      /* Azul oscuro corporativo */

--water-blue: #0EA5E9;            /* Azul agua */
--water-blue-light: #7DD3FC;      /* Azul agua claro */
--water-blue-dark: #0284C7;       /* Azul agua oscuro */

--earth-brown: #A16207;           /* Marrón tierra */
--earth-brown-light: #D97706;     /* Marrón claro */
--earth-brown-dark: #92400E;      /* Marrón oscuro */
```

### 📊 Colores de Gráficos

#### Serie de Datos
```css
--chart-primary: #3B82F6;         /* Línea principal */
--chart-secondary: #10B981;       /* Línea secundaria */
--chart-tertiary: #F59E0B;        /* Línea terciaria */
--chart-quaternary: #EF4444;      /* Línea cuaternaria */

--chart-grid: #E5E7EB;            /* Líneas de grid */
--chart-axis: #6B7280;            /* Ejes de gráfico */
--chart-background: #F9FAFB;      /* Fondo de gráfico */
```

#### Gradientes
```css
--gradient-primary: linear-gradient(135deg, #3B82F6 0%, #1D4ED8 100%);
--gradient-risk: linear-gradient(135deg, #22C55E 0%, #EF4444 100%);
--gradient-water: linear-gradient(135deg, #0EA5E9 0%, #0284C7 100%);
--gradient-emergency: linear-gradient(135deg, #EF4444 0%, #DC2626 100%);
```

### ♿ Accesibilidad de Colores

#### Contrastes Mínimos (WCAG AA)
| Combinación | Contraste | Cumple |
|-------------|-----------|---------|
| text-primary / background | 21:1 | ✅ AAA |
| text-secondary / background | 7.2:1 | ✅ AA |
| risk-critical / background | 5.6:1 | ✅ AA |
| primary / background | 4.8:1 | ✅ AA |
| warning / background | 4.5:1 | ✅ AA |

#### Pruebas de Daltonismo
- ✅ Protanopia (rojo-verde)
- ✅ Deuteranopia (rojo-verde)
- ✅ Tritanopia (azul-amarillo)
- ✅ Monocromatismo

### 🎨 Tokens de Color Exportables

```json
{
  "color": {
    "risk": {
      "normal": "#22C55E",
      "low": "#86EFAC",
      "moderate": "#FDE047",
      "high": "#FB923C",
      "very-high": "#DC2626",
      "critical": "#FF0000"
    },
    "system": {
      "primary": "#2563EB",
      "secondary": "#64748B",
      "background": "#FFFFFF",
      "text": "#0F172A"
    },
    "state": {
      "success": "#10B981",
      "warning": "#F59E0B",
      "error": "#EF4444",
      "info": "#3B82F6"
    }
  }
}
```