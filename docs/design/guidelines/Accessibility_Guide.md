# Guía de Accesibilidad CMIPRO
## WCAG AA Compliance para Emergencias Hidrológicas

### 🎯 Objetivo de Accesibilidad

CMIPRO debe ser accesible para todas las personas del Valle de Sula, incluyendo:
- Personas con discapacidades visuales
- Personas con discapacidades auditivas  
- Personas con discapacidades motoras
- Personas con discapacidades cognitivas
- Adultos mayores con capacidades reducidas
- Usuarios en situaciones de estrés extremo

### ♿ Estándares de Cumplimiento

#### WCAG 2.1 AA Compliance
✅ **Nivel A:** Cumplimiento básico obligatorio  
✅ **Nivel AA:** Cumplimiento estándar (objetivo principal)  
🎯 **Nivel AAA:** Cumplimiento avanzado (donde sea posible)

### 🎨 Accesibilidad Visual

#### Contraste de Colores
| Combinación | Ratio | Cumple | Nivel |
|-------------|-------|--------|-------|
| Texto normal vs fondo | 4.5:1 | ✅ | AA |
| Texto grande vs fondo | 3:1 | ✅ | AA |
| Critical red vs blanco | 5.6:1 | ✅ | AA |
| Primary blue vs blanco | 4.8:1 | ✅ | AA |
| Risk yellow vs blanco | 4.5:1 | ✅ | AA |

#### Testing de Daltonismo
```css
/* Protanopia (8% hombres) - Dificultad rojo/verde */
.risk-critical::before {
  content: "⚠️"; /* Icono de apoyo */
  margin-right: 4px;
}

/* Deuteranopia (1% población) - Dificultad verde/rojo */
.risk-normal::before {
  content: "✅"; /* Icono de apoyo */
  margin-right: 4px;
}

/* Tritanopia (raro) - Dificultad azul/amarillo */
.risk-moderate {
  text-decoration: underline; /* Apoyo visual */
}
```

#### Tamaños de Fuente Accesibles
```css
/* Mínimos WCAG */
--text-minimum: 16px;     /* Cuerpo de texto */
--text-large: 18px;       /* Texto grande */
--touch-target: 44px;     /* Elementos táctiles */

/* Escalado para zoom 200% */
@media (min-resolution: 192dpi) {
  .text-scalable {
    font-size: calc(var(--text-base) * 1.2);
  }
}
```

### 🔊 Accesibilidad Auditiva

#### Alertas Visuales para Sordos
```tsx
interface VisualAlertProps {
  level: RiskLevel;
  message: string;
  vibration?: boolean; // Para móviles
}

// Implementación
const VisualAlert = ({ level, message, vibration }) => {
  useEffect(() => {
    // Vibración en móviles
    if (vibration && 'vibrate' in navigator) {
      const pattern = level === 'critical' ? [200, 100, 200] : [100];
      navigator.vibrate(pattern);
    }
    
    // Flash visual para alertas críticas
    if (level === 'critical') {
      document.body.classList.add('critical-flash');
      setTimeout(() => {
        document.body.classList.remove('critical-flash');
      }, 1000);
    }
  }, [level, vibration]);
};
```

#### Subtítulos y Transcripciones
- Todos los videos incluyen subtítulos
- Alertas de audio tienen equivalente visual
- Sonidos de notificación tienen indicador visual

### ⌨️ Accesibilidad de Teclado

#### Navegación por Tab
```css
/* Orden lógico de focus */
.focus-trap {
  outline: 2px solid var(--primary);
  outline-offset: 2px;
  border-radius: var(--radius-sm);
}

/* Skip links para navegación rápida */
.skip-link {
  position: absolute;
  top: -40px;
  left: 6px;
  background: var(--primary);
  color: white;
  padding: 8px;
  text-decoration: none;
  transform: translateY(-100%);
  transition: transform 0.3s;
}

.skip-link:focus {
  transform: translateY(0%);
}
```

#### Atajos de Teclado
```tsx
const KeyboardShortcuts = {
  'Alt + 1': 'Ir a dashboard principal',
  'Alt + 2': 'Ir a alertas activas', 
  'Alt + 3': 'Ir a estaciones',
  'Alt + E': 'Botón de emergencia',
  'Escape': 'Cerrar modal/dropdown',
  'Enter': 'Activar elemento enfocado',
  'Space': 'Activar checkbox/button',
  'Arrow Keys': 'Navegar listas/menús'
};
```

### 🧠 Accesibilidad Cognitiva

#### Lenguaje Claro y Simple
```tsx
// ❌ Lenguaje técnico complejo
"El nivel hidrológico ha superado el umbral crítico establecido"

// ✅ Lenguaje claro para emergencias  
"PELIGRO: El río está muy alto. Evacúe inmediatamente."
```

#### Iconografía Universal
```tsx
const AccessibleIcons = {
  critical: { icon: '🚨', label: 'Emergencia crítica' },
  high: { icon: '⚠️', label: 'Peligro alto' },
  moderate: { icon: '⚡', label: 'Precaución' },
  low: { icon: '👁️', label: 'Vigilancia' },
  normal: { icon: '✅', label: 'Seguro' }
};
```

#### Consistencia de Interfaz
- Navegación siempre en la misma ubicación
- Botones principales con mismo color/forma
- Mensajes de error claros y específicos
- Confirmaciones antes de acciones importantes

### 📱 Accesibilidad Móvil

#### Touch Targets
```css
/* Tamaño mínimo 44x44px */
.touch-target {
  min-height: 44px;
  min-width: 44px;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Espaciado entre elementos táctiles */
.touch-list > * + * {
  margin-top: 8px;
}
```

#### Orientación y Zoom
```css
/* Soportar ambas orientaciones */
@media (orientation: landscape) {
  .mobile-layout {
    flex-direction: row;
  }
}

/* Zoom hasta 200% sin scroll horizontal */
.responsive-container {
  max-width: 100%;
  overflow-x: hidden;
}
```

### 🔧 Implementación Técnica

#### Semantic HTML
```html
<!-- Estructura semántica clara -->
<main role="main" aria-label="Dashboard principal">
  <section aria-labelledby="alerts-heading">
    <h2 id="alerts-heading">Alertas Activas</h2>
    <ul role="list">
      <li role="listitem">
        <article aria-label="Alerta crítica Río Ulúa">
          <h3>Río Ulúa - Nivel Crítico</h3>
          <p>Evacúe inmediatamente la zona</p>
          <button aria-label="Confirmar recibo de alerta crítica">
            Entendido
          </button>
        </article>
      </li>
    </ul>
  </section>
</main>
```

#### ARIA Labels y Roles
```tsx
interface AccessibleComponentProps {
  'aria-label'?: string;
  'aria-labelledby'?: string;
  'aria-describedby'?: string;
  'aria-expanded'?: boolean;
  'aria-hidden'?: boolean;
  role?: string;
}

// Ejemplo: StationCard accesible
const StationCard = ({ station, riskLevel, ...props }) => (
  <article
    role="article"
    aria-label={`Estación ${station.name}, nivel de riesgo ${riskLevel}`}
    {...props}
  >
    <h3 id={`station-${station.id}-title`}>
      {station.name}
    </h3>
    <div 
      aria-labelledby={`station-${station.id}-title`}
      aria-describedby={`station-${station.id}-desc`}
    >
      <RiskIndicator level={riskLevel} />
    </div>
    <p id={`station-${station.id}-desc`}>
      Nivel actual: {station.currentLevel}m
    </p>
  </article>
);
```

#### Screen Reader Optimization
```tsx
// Texto solo para lectores de pantalla
const ScreenReaderOnly = ({ children }) => (
  <span className="sr-only">
    {children}
  </span>
);

// CSS para .sr-only
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}
```

### 🧪 Testing de Accesibilidad

#### Herramientas Automatizadas
```bash
# Testing con axe-core
npm install --save-dev @axe-core/react
npm install --save-dev jest-axe

# Testing con Lighthouse
npx lighthouse <url> --only-categories=accessibility
```

#### Testing Manual
```tsx
// Checklist de testing manual
const AccessibilityChecklist = {
  keyboard: [
    '✅ Todos los elementos interactivos accesibles por Tab',
    '✅ Orden de tab lógico y predecible',
    '✅ Focus visible en todos los elementos',
    '✅ Escape cierra modales y dropdowns'
  ],
  
  screenReader: [
    '✅ Títulos jerárquicos (H1, H2, H3)',
    '✅ Landmarks y regiones identificadas',
    '✅ Texto alternativo en imágenes',
    '✅ Estados de elementos comunicados'
  ],
  
  visual: [
    '✅ Contraste mínimo 4.5:1',
    '✅ Zoom 200% funcional',
    '✅ No dependencia solo del color',
    '✅ Texto legible en todos los tamaños'
  ]
};
```

#### Testing con Usuarios Reales
- Sesiones con usuarios con discapacidades visuales
- Testing con adultos mayores del Valle de Sula
- Validación en situaciones de estrés simuladas
- Feedback de organizaciones de discapacidad locales

### 📊 Métricas de Accesibilidad

#### KPIs de Seguimiento
```typescript
interface AccessibilityMetrics {
  contrastRatio: number;        // Objetivo: >4.5
  keyboardNavigation: number;   // Objetivo: 100%
  screenReaderSupport: number;  // Objetivo: 100%
  loadTimeAccessible: number;   // Objetivo: <3s
  errorRate: number;           // Objetivo: <1%
}
```

#### Reportes Automáticos
- Testing diario con axe-core en CI/CD
- Lighthouse accessibility score >90
- Validación WAVE sin errores críticos
- Color Oracle para daltonismo

### 🔄 Mantenimiento Continuo

#### Proceso de Validación
1. **Diseño:** Validar contraste en Figma
2. **Desarrollo:** Testing automático en PR
3. **QA:** Checklist manual obligatorio
4. **Deploy:** Lighthouse score validation
5. **Post-deploy:** Monitoring continuo

#### Training del Equipo
- Workshop WCAG para todo el equipo
- Testing con tecnologías asistivas
- Revisión mensual de métricas
- Actualizaciones de guidelines

### 🌍 Contexto Local - Valle de Sula

#### Consideraciones Culturales
- Iconografía comprensible localmente
- Lenguaje en español centroamericano
- Consideración de niveles de educación
- Acceso a tecnologías asistivas limitado

#### Adaptaciones Específicas
```tsx
// Mensajes adaptados al contexto local
const LocalizedMessages = {
  critical: "¡PELIGRO INMEDIATO! Salga de la zona del río ahora mismo",
  high: "El río está creciendo. Prepárese para evacuar",
  moderate: "Manténgase alerta. El río puede crecer",
  evacuation: "Diríjase a los refugios en escuelas y centros comunitarios"
};
```

#### Conectividad Limitada
- Offline-first approach para accesibilidad
- Información crítica cached localmente
- Progressive enhancement
- Funcionalidad básica sin JavaScript

### ✅ Checklist Final de Accesibilidad

#### Pre-launch Validation
- [ ] Contraste validado con Color Oracle
- [ ] Navegación por teclado 100% funcional
- [ ] Screen reader testing con NVDA/JAWS
- [ ] Mobile accessibility en dispositivos reales
- [ ] Testing con usuarios con discapacidades
- [ ] Lighthouse accessibility score >95
- [ ] Validación WAVE sin errores
- [ ] Testing en conexiones lentas
- [ ] Validación con JavaScript deshabilitado
- [ ] Documentación de accesibilidad completa