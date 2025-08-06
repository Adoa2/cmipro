# Biblioteca de Componentes CMIPRO
## 47 Componentes Reutilizables para Desarrollo

### 🧩 Categorías de Componentes

## 1. 🧭 Navegación y Layout (8 componentes)

### TopNavigation
**Descripción:** Barra superior con logo, menú usuario y estado de conexión
```tsx
interface TopNavigationProps {
  user?: User;
  connectionStatus: 'online' | 'offline' | 'reconnecting';
  onLogout: () => void;
}
```
**Estados:** Default, User logged, Offline mode
**Responsivo:** Colapsa en hamburger < 768px

### Sidebar
**Descripción:** Navegación lateral responsiva con secciones principales
```tsx
interface SidebarProps {
  isOpen: boolean;
  currentPath: string;
  onClose: () => void;
  menuItems: MenuItem[];
}
```
**Estados:** Open, Closed, Mobile overlay
**Animaciones:** Slide-in/out, backdrop fade

### Breadcrumbs
**Descripción:** Navegación de contexto para orientación del usuario
```tsx
interface BreadcrumbsProps {
  items: BreadcrumbItem[];
  separator?: React.ReactNode;
  maxItems?: number;
}
```
**Características:** Auto-truncate, separadores personalizables

### Footer
**Descripción:** Información de contacto, legal y enlaces útiles
```tsx
interface FooterProps {
  variant: 'full' | 'minimal';
  showSocialLinks?: boolean;
  customLinks?: FooterLink[];
}
```

### BottomNavigation
**Descripción:** Navegación inferior para mobile
```tsx
interface BottomNavigationProps {
  items: NavItem[];
  activeIndex: number;
  onChange: (index: number) => void;
}
```

### PageHeader
**Descripción:** Encabezado de página con título y acciones
```tsx
interface PageHeaderProps {
  title: string;
  subtitle?: string;
  actions?: React.ReactNode;
  breadcrumbs?: BreadcrumbItem[];
}
```

### ContentContainer
**Descripción:** Contenedor principal con padding y max-width
```tsx
interface ContentContainerProps {
  maxWidth?: 'sm' | 'md' | 'lg' | 'xl' | 'full';
  padding?: 'none' | 'sm' | 'md' | 'lg';
  children: React.ReactNode;
}
```

### GridLayout
**Descripción:** Sistema de grid responsivo
```tsx
interface GridLayoutProps {
  columns: number | { sm: number; md: number; lg: number };
  gap?: 'sm' | 'md' | 'lg';
  children: React.ReactNode;
}
```

## 2. 🌊 Estaciones y Monitoreo (8 componentes)

### StationCard
**Descripción:** Card principal con información de estación y nivel de riesgo
```tsx
interface StationCardProps {
  station: Station;
  currentLevel: number;
  riskLevel: RiskLevel;
  trend: 'rising' | 'falling' | 'stable';
  onClick?: () => void;
}
```
**Estados:** Normal, Alto riesgo, Crítico (con animación), Loading
**Animaciones:** Pulse para crítico, hover elevation

### RiskIndicator
**Descripción:** Semáforo visual con 6 niveles de riesgo
```tsx
interface RiskIndicatorProps {
  level: 'normal' | 'low' | 'moderate' | 'high' | 'very-high' | 'critical';
  size?: 'sm' | 'md' | 'lg';
  showLabel?: boolean;
  animated?: boolean;
}
```
**Colores:** Basado en paleta de riesgo del martes
**Animaciones:** Pulse para crítico, glow para muy alto

### LevelGauge
**Descripción:** Medidor visual tipo termómetro para nivel de agua
```tsx
interface LevelGaugeProps {
  currentLevel: number;
  maxLevel: number;
  thresholds: RiskThreshold[];
  unit: string;
  orientation?: 'vertical' | 'horizontal';
}
```
**Características:** Gradiente de colores, marcadores de umbral

### TrendArrow
**Descripción:** Indicador de tendencia (subiendo/bajando/estable)
```tsx
interface TrendArrowProps {
  trend: 'rising' | 'falling' | 'stable';
  magnitude?: 'low' | 'medium' | 'high';
  showValue?: boolean;
  value?: number;
}
```

### StationStatus
**Descripción:** Estado de conectividad y última actualización
```tsx
interface StationStatusProps {
  status: 'online' | 'offline' | 'maintenance';
  lastUpdate: Date;
  nextUpdate?: Date;
}
```

### QuickStats
**Descripción:** Métricas rápidas de múltiples estaciones
```tsx
interface QuickStatsProps {
  stats: {
    totalStations: number;
    activeAlerts: number;
    criticalStations: number;
    lastUpdate: Date;
  };
}
```

### StationList
**Descripción:** Lista compacta de estaciones con estado
```tsx
interface StationListProps {
  stations: Station[];
  sortBy?: 'name' | 'risk' | 'level';
  filterBy?: RiskLevel[];
  onStationClick: (station: Station) => void;
}
```

### RiverMap
**Descripción:** Mapa simple con ubicación de estaciones (Fase 2)
```tsx
interface RiverMapProps {
  stations: StationLocation[];
  selectedStation?: string;
  onStationSelect: (stationId: string) => void;
  showRiskColors?: boolean;
}
```

## 3. 🚨 Alertas y Notificaciones (7 componentes)

### AlertBanner
**Descripción:** Banner de alerta crítica en la parte superior
```tsx
interface AlertBannerProps {
  alert: Alert;
  variant: 'info' | 'warning' | 'error' | 'critical';
  dismissible?: boolean;
  onDismiss?: () => void;
  animated?: boolean;
}
```
**Animaciones:** Slide-down, pulse para crítico

### NotificationToast
**Descripción:** Notificaciones emergentes tipo toast
```tsx
interface NotificationToastProps {
  message: string;
  variant: 'success' | 'error' | 'warning' | 'info';
  duration?: number;
  onClose: () => void;
  actions?: ToastAction[];
}
```
**Posición:** Top-right por defecto
**Animaciones:** Slide-in, fade-out

### AlertCard
**Descripción:** Card de alerta en dashboard o centro de alertas
```tsx
interface AlertCardProps {
  alert: Alert;
  onAcknowledge?: () => void;
  onDismiss?: () => void;
  showActions?: boolean;
  compact?: boolean;
}
```

### AlertHistoryItem
**Descripción:** Elemento de historial de alertas
```tsx
interface AlertHistoryItemProps {
  alert: HistoricalAlert;
  showDetails?: boolean;
  onToggleDetails?: () => void;
}
```

### EmergencyButton
**Descripción:** Botón de emergencia prominente
```tsx
interface EmergencyButtonProps {
  type: 'call' | 'evacuate' | 'report';
  size?: 'md' | 'lg';
  disabled?: boolean;
  onClick: () => void;
}
```
**Características:** Rojo prominente, animación sutil

### AlertCounter
**Descripción:** Contador de alertas activas con badge
```tsx
interface AlertCounterProps {
  count: number;
  maxDisplay?: number;
  variant?: 'default' | 'critical';
  onClick?: () => void;
}
```

### SoundToggle
**Descripción:** Control para activar/desactivar sonidos de alerta
```tsx
interface SoundToggleProps {
  enabled: boolean;
  onChange: (enabled: boolean) => void;
  size?: 'sm' | 'md';
}
```

## 4. 📊 Gráficos y Visualización (6 componentes)

### TimeSeriesChart
**Descripción:** Gráfico de líneas para series temporales con Recharts
```tsx
interface TimeSeriesChartProps {
  data: TimeSeriesData[];
  height?: number;
  showPrediction?: boolean;
  thresholds?: RiskThreshold[];
  onPointClick?: (point: TimeSeriesData) => void;
}
```
**Características:** Líneas de umbral, zoom, tooltip

### RiskLevelChart
**Descripción:** Gráfico de barras por nivel de riesgo
```tsx
interface RiskLevelChartProps {
  data: RiskLevelData[];
  orientation?: 'vertical' | 'horizontal';
  showPercentages?: boolean;
  interactive?: boolean;
}
```

### PopulationImpactMeter
**Descripción:** Contador de población en riesgo en tiempo real
```tsx
interface PopulationImpactMeterProps {
  currentRisk: number;
  totalPopulation: number;
  animateChanges?: boolean;
  showBreakdown?: boolean;
}
```
**Animaciones:** Counter animation, color transitions

### WeatherWidget
**Descripción:** Widget compacto de condiciones meteorológicas
```tsx
interface WeatherWidgetProps {
  data: WeatherData;
  variant?: 'minimal' | 'detailed';
  showForecast?: boolean;
}
```

### MetricsCard
**Descripción:** Card de métricas con valor principal y tendencia
```tsx
interface MetricsCardProps {
  title: string;
  value: number | string;
  unit?: string;
  trend?: TrendData;
  format?: 'number' | 'percentage' | 'currency';
  size?: 'sm' | 'md' | 'lg';
}
```

### DataTable
**Descripción:** Tabla de datos con sorting y filtros
```tsx
interface DataTableProps<T> {
  data: T[];
  columns: TableColumn<T>[];
  sortable?: boolean;
  filterable?: boolean;
  pagination?: boolean;
  onRowClick?: (row: T) => void;
}
```

## 5. 🔐 Autenticación y Usuario (6 componentes)

### LoginForm
**Descripción:** Formulario de inicio de sesión con Firebase
```tsx
interface LoginFormProps {
  onSuccess: (user: User) => void;
  onError: (error: string) => void;
  showSocialLogin?: boolean;
  redirectUrl?: string;
}
```
**Validación:** Email format, password strength
**OAuth:** Google, Facebook integration

### RegisterForm
**Descripción:** Formulario de registro de nuevos usuarios
```tsx
interface RegisterFormProps {
  onSuccess: (user: User) => void;
  onError: (error: string) => void;
  requireEmailVerification?: boolean;
}
```

### UserProfile
**Descripción:** Perfil de usuario con información de suscripción
```tsx
interface UserProfileProps {
  user: User;
  subscription?: Subscription;
  onUpdate: (userData: Partial<User>) => void;
  editable?: boolean;
}
```

### PasswordReset
**Descripción:** Componente para recuperación de contraseña
```tsx
interface PasswordResetProps {
  onSuccess: () => void;
  onError: (error: string) => void;
  email?: string;
}
```

### UserAvatar
**Descripción:** Avatar de usuario con iniciales o imagen
```tsx
interface UserAvatarProps {
  user: User;
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl';
  showStatus?: boolean;
  onClick?: () => void;
}
```

### UserMenu
**Descripción:** Menú desplegable de usuario
```tsx
interface UserMenuProps {
  user: User;
  onLogout: () => void;
  menuItems?: UserMenuItem[];
}
```

## 6. 📰 Noticias y Contenido (4 componentes)

### NewsCard
**Descripción:** Card de noticia con badge IA y resumen
```tsx
interface NewsCardProps {
  article: NewsArticle;
  variant?: 'compact' | 'detailed';
  showAIBadge?: boolean;
  onRead?: () => void;
}
```

### AIBadge
**Descripción:** Badge indicando contenido generado por IA
```tsx
interface AIBadgeProps {
  variant?: 'default' | 'minimal';
  tooltip?: string;
  size?: 'sm' | 'md';
}
```

### NewsFilter
**Descripción:** Filtros de categoría para noticias
```tsx
interface NewsFilterProps {
  categories: NewsCategory[];
  selectedCategories: string[];
  onCategoryChange: (categories: string[]) => void;
}
```

### ShareButton
**Descripción:** Botón para compartir noticias y alertas
```tsx
interface ShareButtonProps {
  url: string;
  title: string;
  description?: string;
  platforms?: SharePlatform[];
  onShare?: (platform: string) => void;
}
```

## 7. 📝 Formularios y Controles (8 componentes)

### InputField
**Descripción:** Campo de entrada con validación y estados
```tsx
interface InputFieldProps {
  type?: 'text' | 'email' | 'password' | 'number';
  label: string;
  placeholder?: string;
  error?: string;
  required?: boolean;
  disabled?: boolean;
  value: string;
  onChange: (value: string) => void;
}
```

### SelectDropdown
**Descripción:** Selector desplegable personalizable
```tsx
interface SelectDropdownProps<T> {
  options: SelectOption<T>[];
  value?: T;
  onChange: (value: T) => void;
  placeholder?: string;
  searchable?: boolean;
  multiple?: boolean;
  disabled?: boolean;
}
```

### ToggleSwitch
**Descripción:** Interruptor para preferencias booleanas
```tsx
interface ToggleSwitchProps {
  checked: boolean;
  onChange: (checked: boolean) => void;
  label?: string;
  disabled?: boolean;
  size?: 'sm' | 'md' | 'lg';
}
```

### DateRangePicker
**Descripción:** Selector de rango de fechas para consultas
```tsx
interface DateRangePickerProps {
  startDate?: Date;
  endDate?: Date;
  onChange: (range: DateRange) => void;
  maxDate?: Date;
  minDate?: Date;
  presets?: DatePreset[];
}
```

### Button
**Descripción:** Botón base con múltiples variantes
```tsx
interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'danger' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  loading?: boolean;
  icon?: React.ReactNode;
  children: React.ReactNode;
  onClick?: () => void;
}
```

### SearchInput
**Descripción:** Campo de búsqueda con sugerencias
```tsx
interface SearchInputProps {
  value: string;
  onChange: (value: string) => void;
  onSearch: (query: string) => void;
  suggestions?: string[];
  placeholder?: string;
  debounceMs?: number;
}
```

### Checkbox
**Descripción:** Checkbox con estados y validación
```tsx
interface CheckboxProps {
  checked: boolean;
  onChange: (checked: boolean) => void;
  label?: string;
  indeterminate?: boolean;
  disabled?: boolean;
  error?: string;
}
```

### RadioGroup
**Descripción:** Grupo de radio buttons
```tsx
interface RadioGroupProps<T> {
  options: RadioOption<T>[];
  value?: T;
  onChange: (value: T) => void;
  name: string;
  orientation?: 'horizontal' | 'vertical';
}
```

## 8. ⚡ Estados y Feedback (7 componentes)

### LoadingSpinner
**Descripción:** Indicador de carga con diferentes tamaños
```tsx
interface LoadingSpinnerProps {
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl';
  color?: string;
  overlay?: boolean;
  text?: string;
}
```

### LoadingSkeleton
**Descripción:** Skeleton loader para contenido
```tsx
interface LoadingSkeletonProps {
  variant?: 'text' | 'card' | 'avatar' | 'chart';
  width?: string | number;
  height?: string | number;
  count?: number;
  animated?: boolean;
}
```

### EmptyState
**Descripción:** Estado vacío con ilustración y acciones
```tsx
interface EmptyStateProps {
  title: string;
  description?: string;
  illustration?: React.ReactNode;
  action?: EmptyStateAction;
  size?: 'sm' | 'md' | 'lg';
}
```

### ErrorState
**Descripción:** Estado de error con opciones de recuperación
```tsx
interface ErrorStateProps {
  error: Error;
  onRetry?: () => void;
  onReport?: () => void;
  showDetails?: boolean;
}
```

### SuccessState
**Descripción:** Estado de éxito para confirmaciones
```tsx
interface SuccessStateProps {
  title: string;
  description?: string;
  action?: SuccessAction;
  autoHide?: number;
}
```

### ProgressBar
**Descripción:** Barra de progreso para procesos largos
```tsx
interface ProgressBarProps {
  value: number;
  max?: number;
  variant?: 'default' | 'success' | 'warning' | 'danger';
  showLabel?: boolean;
  animated?: boolean;
}
```

### StatusBadge
**Descripción:** Badge de estado con colores semánticos
```tsx
interface StatusBadgeProps {
  status: 'active' | 'inactive' | 'pending' | 'error';
  text?: string;
  size?: 'sm' | 'md';
  variant?: 'solid' | 'outline' | 'soft';
}
```

### 🎨 Patrones de Uso

#### Composición de Componentes
```tsx
// Ejemplo: Dashboard de estación
<ContentContainer maxWidth="xl">
  <PageHeader 
    title="Monitoreo de Estaciones"
    subtitle="Valle de Sula - Honduras"
    actions={<EmergencyButton type="call" />}
  />
  
  <GridLayout columns={{sm: 1, md: 2, lg: 3}} gap="md">
    {stations.map(station => (
      <StationCard
        key={station.id}
        station={station}
        currentLevel={station.currentLevel}
        riskLevel={station.riskLevel}
        trend={station.trend}
      />
    ))}
  </GridLayout>
  
  {alerts.length > 0 && (
    <AlertBanner
      alert={alerts[0]}
      variant="critical"
      animated={true}
    />
  )}
</ContentContainer>
```

### 📐 Especificaciones Técnicas

#### Props Interface Patterns
```tsx
// Base component props
interface BaseComponentProps {
  className?: string;
  testId?: string;
  children?: React.ReactNode;
}

// Interactive component props
interface InteractiveProps extends BaseComponentProps {
  disabled?: boolean;
  loading?: boolean;
  onClick?: () => void;
}

// Form component props
interface FormComponentProps extends BaseComponentProps {
  name: string;
  required?: boolean;
  error?: string;
  disabled?: boolean;
}
```

#### Size System
```tsx
type ComponentSize = 'xs' | 'sm' | 'md' | 'lg' | 'xl';

const sizeMap = {
  xs: { padding: '4px 8px', fontSize: '12px' },
  sm: { padding: '6px 12px', fontSize: '14px' },
  md: { padding: '8px 16px', fontSize: '16px' },
  lg: { padding: '12px 24px', fontSize: '18px' },
  xl: { padding: '16px 32px', fontSize: '20px' }
};
```

### 🔧 Implementación con Tailwind CSS

#### Utility Classes Pattern
```tsx
// Componente base usando clases utilitarias
const Button = ({ variant, size, children, ...props }) => {
  const baseClasses = 'inline-flex items-center justify-center font-medium transition-colors focus:outline-none focus:ring-2';
  
  const variantClasses = {
    primary: 'bg-primary text-white hover:bg-primary-dark',
    secondary: 'bg-secondary text-white hover:bg-secondary-dark',
    danger: 'bg-error text-white hover:bg-error-hover'
  };
  
  const sizeClasses = {
    sm: 'px-3 py-1.5 text-sm rounded',
    md: 'px-4 py-2 text-base rounded-md', 
    lg: 'px-6 py-3 text-lg rounded-lg'
  };
  
  return (
    <button 
      className={`${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]}`}
      {...props}
    >
      {children}
    </button>
  );
};
```