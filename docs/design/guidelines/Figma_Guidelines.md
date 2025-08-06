# Guías de Figma para CMIPRO
## Organización y Mejores Prácticas de Diseño

### 📁 Estructura de Archivos Figma

#### Archivo Principal: `CMIPRO_Design_System.fig`
```
📁 CMIPRO Design System
├── 🎨 Cover Page
├── 🧩 Design Tokens
├── 🎯 Components Library
├── 📱 Mobile Components
├── 🖥️ Desktop Components
├── 📊 Chart Components
├── 🚨 Alert Components
└── 🔧 Utilities & Icons
```

#### Archivo de Prototipos: `CMIPRO_Prototypes.fig`
```
📁 CMIPRO Prototypes
├── 🏠 User Flow Overview
├── 📱 Mobile Prototype
├── 💻 Desktop Prototype
├── 🔄 Interaction States
├── 📊 Data Visualization
└── 🧪 Testing Screens
```

### 🎨 Organización de Páginas

#### Página 1: Cover & Index
**Contenido:**
- Logo del proyecto y branding
- Índice de contenidos
- Información del proyecto (versión, fecha, responsables)
- Enlaces a recursos externos
- Changelog reciente

#### Página 2: Design Tokens
**Secciones:**
```
🎨 Colors
├── Risk Level Colors (6 niveles)
├── System Colors (primary, secondary, etc.)
├── State Colors (success, error, warning)
├── Dark Mode Variants
└── Accessibility Tests

📝 Typography
├── Font Family (Inter)
├── Font Scales (H1-H6, Body, Caption)
├── Line Heights
├── Font Weights
└── Mobile Adaptations

📐 Spacing
├── Spacing Scale (4px base)
├── Grid System
├── Component Spacing
└── Layout Margins

🔲 Elevation & Shadows
├── Card Shadows
├── Modal Shadows
├── Hover States
└── Focus States
```

#### Página 3: Components Library
**Organización por categorías:**
```
🧭 Navigation (8 componentes)
🌊 Stations & Monitoring (8 componentes)
🚨 Alerts & Notifications (7 componentes)
📊 Charts & Visualization (6 componentes)
🔐 Authentication & User (6 componentes)
📰 News & Content (4 componentes)
📝 Forms & Controls (8 componentes)
⚡ States & Feedback (7 componentes)
```

### 🔧 Configuración de Componentes

#### Master Components Structure
```
🧩 Component Name
├── 📋 Properties Panel
│   ├── Variant (Default, Hover, Active, Disabled)
│   ├── Size (sm, md, lg)
│   ├── State (normal, loading, error)
│   └── Content (text overrides)
├── 📐 Auto Layout
│   ├── Direction & Alignment
│   ├── Spacing Between Items
│   └── Padding
└── 🎨 Styling
    ├── Fill & Stroke
    ├── Effects (shadows, blur)
    └── Typography
```

#### Ejemplo: StationCard Component
```
🌊 StationCard
├── 📊 Variants
│   ├── Risk Level: normal | low | moderate | high | very-high | critical
│   ├── Size: compact | default | expanded
│   ├── State: default | loading | error | offline
│   └── Trend: rising | falling | stable
├── 🔄 Auto Layout
│   ├── Vertical direction
│   ├── 16px spacing between items
│   └── 20px padding all sides
├── 🎯 Instance Overrides
│   ├── Station Name (text)
│   ├── Current Level (number)
│   ├── Last Update (timestamp)
│   └── Location (text)
└── 🎨 Conditional Styling
    ├── Background color based on risk level
    ├── Border animation for critical
    └── Icon color matching risk level
```

### 🎯 Sistema de Variantes

#### Variant Properties Naming Convention
```
Property Type: Value Options
├── State: default | hover | active | focus | disabled | loading
├── Size: xs | sm | md | lg | xl
├── Type: primary | secondary | tertiary | danger | success
├── Risk: normal | low | moderate | high | very-high | critical
├── Layout: horizontal | vertical | grid
└── Content: text | icon | both | empty
```

#### Boolean Properties
```
✅ Has Icon: true/false
✅ Has Badge: true/false  
✅ Is Loading: true/false
✅ Is Selected: true/false
✅ Show Label: true/false
✅ Is Animated: true/false
```

### 🎨 Estilos y Efectos

#### Text Styles Naming
```
📝 Typography Styles
├── Heading/H1/Desktop
├── Heading/H1/Mobile
├── Heading/H2/Desktop
├── Heading/H2/Mobile
├── Body/Large/Regular
├── Body/Large/Medium
├── Body/Base/Regular
├── Body/Base/Medium
├── Body/Small/Regular
├── Caption/Regular
├── Caption/Medium
└── Overline/Uppercase
```

#### Color Styles Naming
```
🎨 Color Styles
├── Risk/Normal/Background
├── Risk/Normal/Text
├── Risk/Critical/Background
├── Risk/Critical/Text
├── System/Primary/Default
├── System/Primary/Hover
├── System/Background/Light
├── System/Background/Dark
├── Text/Primary/Light
├── Text/Primary/Dark
└── Border/Default/Light
```

#### Effect Styles
```
✨ Effects
├── Shadow/Card/Default
├── Shadow/Card/Hover
├── Shadow/Modal/Default
├── Shadow/Critical/Pulse
├── Blur/Backdrop/Light
├── Blur/Backdrop/Dark
└── Glow/Critical/Animation
```

### 🔄 Prototyping Guidelines

#### Interaction Types
```
🖱️ Mouse Interactions
├── Click/Tap → Navigate to screen
├── Hover → Show hover state
├── Long Press → Show context menu
└── Drag → Scroll or reorder

⌨️ Keyboard Interactions
├── Tab → Focus next element
├── Enter → Activate button/link
├── Escape → Close modal/dropdown
└── Arrow Keys → Navigate lists

📱 Touch Gestures
├── Swipe Left/Right → Navigate screens
├── Pull to Refresh → Reload data
├── Pinch to Zoom → Scale content
└── Two-finger Scroll → Scroll content
```

#### Animation Easing
```
⚡ Timing Functions
├── Ease Out: entrada de elementos
├── Ease In: salida de elementos  
├── Ease In Out: transformaciones
├── Linear: progreso y loading
└── Spring: efectos dinámicos
```

#### Duration Guidelines
```
⏱️ Animation Durations
├── Micro (100ms): feedback inmediato
├── Quick (200ms): transiciones estándar
├── Base (300ms): cambios de estado
├── Slow (500ms): transiciones complejas
└── Critical Pulse (1000ms): alertas críticas
```

### 📱 Responsive Design Setup

#### Frames & Breakpoints
```
📱 Mobile Frames
├── iPhone SE (375×667)
├── iPhone 14 (390×844)
├── Samsung Galaxy (360×800)
└── iPhone 14 Pro Max (430×932)

💻 Desktop Frames
├── MacBook Air (1440×900)
├── Desktop HD (1920×1080)
├── Desktop QHD (2560×1440)
└── Desktop 4K (3840×2160)

📱 Tablet Frames
├── iPad (768×1024)
├── iPad Pro (834×1194)
└── Surface Pro (912×1368)
```

#### Auto Layout Configuration
```
🔄 Responsive Settings
├── Hug Contents: para elementos que se ajustan al contenido
├── Fill Container: para elementos que llenan el espacio disponible
├── Fixed Width/Height: para elementos con tamaño específico
└── Min/Max Constraints: para límites de crecimiento
```

### 🧪 Testing & Handoff

#### Design QA Checklist
```
✅ Consistency Checks
├── [ ] Colores usan styles definidos
├── [ ] Tipografía usa text styles
├── [ ] Espaciado sigue la escala 4px
├── [ ] Componentes usan master components
├── [ ] Estados hover/active definidos
├── [ ] Responsive behavior configurado
└── [ ] Accessibility contrast passed

✅ Component Validation
├── [ ] Todas las variantes funcionan
├── [ ] Text overrides permiten personalización
├── [ ] Auto layout no se rompe con contenido largo
├── [ ] Componentes anidados mantienen consistencia
└── [ ] Exports coinciden con especificaciones
```

#### Developer Handoff Process
```
🚀 Handoff Steps
1. Generar specs automáticas en Figma
2. Exportar assets en formatos correctos
3. Documentar componentes especiales
4. Crear ejemplos de uso
5. Validar implementación vs diseño
6. Iterar basado en feedback técnico
```

### 📤 Export Guidelines

#### Asset Export Settings
```
📁 Export Organization
├── icons/
│   ├── 24x24/ (SVG, PNG 1x 2x)
│   ├── 32x32/ (SVG, PNG 1x 2x)
│   └── 48x48/ (SVG, PNG 1x 2x)
├── illustrations/
│   ├── empty-states/ (SVG)
│   ├── error-states/ (SVG)
│   └── success-states/ (SVG)
├── logos/
│   ├── logo-light.svg
│   ├── logo-dark.svg
│   └── logo-icon-only.svg
└── backgrounds/
    ├── patterns/ (PNG, SVG)
    └── gradients/ (CSS, SVG)
```

#### Export Specifications
```
🖼️ Image Formats
├── Icons: SVG (preferred), PNG fallback
├── Illustrations: SVG for simple, PNG for complex
├── Photos: WebP (preferred), JPG fallback
├── Logos: SVG (scalable), PNG for legacy
└── Backgrounds: CSS gradients, SVG patterns

📐 Size Specifications
├── Icons: 16px, 20px, 24px, 32px, 48px
├── Thumbnails: 150x150, 300x300
├── Cards: 300x200, 400x300
└── Hero images: 1200x600, 1920x1080
```

### 🎯 Best Practices

#### Component Design Principles
```
🎨 Design Principles
├── Consistency: usar master components siempre
├── Scalability: componentes que crecen con contenido
├── Accessibility: contraste y tamaños apropiados
├── Performance: exports optimizados
└── Maintainability: naming conventions claros
```

#### Collaboration Guidelines
```
👥 Team Collaboration
├── Usar comentarios para feedback específico
├── Crear branches para experimentos
├── Sincronizar cambios regularmente
├── Documentar decisiones importantes
└── Validar con desarrolladores antes de finalizar
```

#### Version Control
```
📝 Version Management
├── Semantic versioning (1.0.0)
├── Changelog para cada actualización
├── Tags para releases importantes
├── Backup de versiones estables
└── Documentación de breaking changes
```

### 🔗 Recursos y Plugins Útiles

#### Plugins Recomendados
```
🔌 Figma Plugins
├── Auto Layout: optimización de layouts
├── Content Reel: contenido realista
├── Stark: testing de accesibilidad
├── Fig Tokens: sincronización de design tokens
├── Component Inspector: validación de consistencia
├── Remove BG: remoción de fondos
├── Unsplash: imágenes de stock
└── Iconify: librería de iconos
```

#### Recursos Externos
```
🌐 External Resources
├── Inter Font: https://rsms.me/inter/
├── Heroicons: https://heroicons.com/
├── Tailwind Colors: https://tailwindcss.com/docs/colors
├── WCAG Guidelines: https://www.w3.org/WAI/WCAG21/
└── Material Design: https://material.io/design
```

### 📋 Workflow Checklist

#### Daily Design Tasks
```
📅 Daily Checklist
├── [ ] Sync latest changes from team
├── [ ] Review and respond to comments
├── [ ] Update components if needed
├── [ ] Test responsive behavior
├── [ ] Export new assets if required
├── [ ] Update documentation
└── [ ] Commit changes with clear message
```

#### Weekly Review Tasks
```
📅 Weekly Checklist
├── [ ] Review component usage across project
├── [ ] Identify inconsistencies or redundancies
├── [ ] Update design system documentation
├── [ ] Plan improvements for next iteration
├── [ ] Sync with development team
└── [ ] Backup important files
```