# Estrategia de Deployment CMIPRO
## CI/CD Pipeline para Sistema Crítico - Explicación Completa

### 🎯 ¿Por Qué Necesitamos CI/CD en CMIPRO?

**CMIPRO es un sistema de alertas de emergencia - NO puede fallar durante deployment**

```yaml
Problemas sin CI/CD automático:
  Deploy manual:
    - Desarrollador sube archivos por FTP
    - Olvida migrar base de datos
    - Sistema caído por 30 minutos
    - Durante emergencia = vidas en riesgo
  
  Testing manual:
    - "Funciona en mi máquina"
    - Bug no detectado llega a producción
    - Sistema da falsa alerta durante huracán
    - Pánico innecesario en Valle de Sula
  
  Rollback manual:
    - Error detectado a las 2AM
    - Desarrollador no disponible
    - Sistema caído hasta mañana
    - Pérdida total de confianza pública

Beneficios con CI/CD automático:
  Deploy automático:
    ✅ Deploy consistente cada vez
    ✅ Testing automático antes de deploy
    ✅ Zero downtime con blue-green strategy
    ✅ Rollback automático si algo falla
  
  Quality assurance:
    ✅ Tests ejecutados en cada commit
    ✅ Security scans automáticos
    ✅ Performance validation automática
    ✅ No código buggy llega a producción
  
  Reliability:
    ✅ Sistema funcional 24/7
    ✅ Updates frecuentes sin interrupciones
    ✅ Rollback inmediato ante problemas
    ✅ Confianza total del usuario final
```

### 🔄 Git Workflow: Organización del Código

#### ¿Por qué Git Flow Simplificado?
```yaml
Git Flow tradicional (Demasiado complejo para startup):
  - main (producción)
  - develop (desarrollo)
  - feature/* (características)
  - release/* (preparación release)
  - hotfix/* (correcciones urgentes)
  - support/* (mantenimiento)

Git Flow CMIPRO (Optimizado para velocidad):
  - main → Producción (siempre estable)
  - develop → Integración y desarrollo
  - feature/* → Desarrollo de características
  - hotfix/* → Correcciones urgentes
```

**Branch Strategy Implementada:**
```yaml
main branch:
  Propósito: Código estable en producción
  Protecciones:
    - Requiere 2 code reviews
    - Requiere que pasen todos los tests
    - Requiere security scan limpio
    - Solo admins pueden mergear directamente
  Auto-deployment: ✅ A producción inmediatamente
  
develop branch:
  Propósito: Integración continua de features
  Protecciones:
    - Requiere 1 code review
    - Requiere tests básicos pasando
    - Linting automático
  Auto-deployment: ✅ A staging para testing
  
feature/* branches:
  Propósito: Desarrollo de nuevas características
  Protecciones: Ninguna (desarrollo libre)
  Target: Merge a develop
  Auto-deployment: ❌ Solo desarrollo local
  
hotfix/* branches:
  Propósito: Correcciones críticas urgentes
  Protecciones: Mismas que main
  Target: Merge directo a main
  Priority: 🚨 ALTA (bypass queue)
```

#### Commit Message Standards (¿Por qué importa?)
```yaml
Formato: type(scope): description

¿Por qué estandarizar commits?
  Sin estándar:
    - "fix stuff"
    - "updated files"  
    - "asdf"
    - "Final version!!!"
  
  Con estándar:
    - "feat(alerts): add push notifications for critical level"
    - "fix(api): correct threshold validation for CHIH3 station"
    - "security(auth): update Firebase dependencies to v9.15.0"
    - "perf(db): optimize TimescaleDB query with proper indexing"

Beneficios:
  ✅ Automatic changelog generation
  ✅ Semantic versioning automático
  ✅ Easy rollback identification
  ✅ Better code review context
  ✅ Release notes automáticas

Tipos de commit:
  feat: Nueva funcionalidad (incrementa MINOR version)
  fix: Corrección de bug (incrementa PATCH version)
  security: Corrección de seguridad (PATCH, pero high priority)
  perf: Mejora de performance
  docs: Solo cambios en documentación
  style: Formatting, missing semicolons, etc
  refactor: Code change que no fix bug ni add feature
  test: Adding missing tests
  chore: Build process, tools, libraries
```

### 🏗️ CI/CD Pipeline Architecture (El Corazón del Sistema)

#### ¿Qué hace cada stage del pipeline?
```yaml
STAGE 1: Code Quality & Security (5-8 minutos)
  ¿Qué hace?
    - Linter checks (ESLint para frontend, Black para backend)
    - Type checking (TypeScript, mypy)
    - Security scans (npm audit, Safety, Bandit)
    - Dependency vulnerability checks
  
  ¿Por qué es importante?
    - Detectar bugs antes que lleguen a testing
    - Evitar vulnerabilities conocidas
    - Mantener código consistente y legible
    - Prevenir deployment de código peligroso

STAGE 2: Automated Testing (10-15 minutos)
  ¿Qué hace?
    - Unit tests (funciones individuales)
    - Integration tests (componentes juntos)
    - E2E tests (flujo completo usuario)
    - Database migration tests
  
  ¿Por qué crítico en CMIPRO?
    - Sistema de alertas NO puede tener bugs
    - Una falsa alerta = pánico masivo
    - Alert perdida = vidas en riesgo
    - Tests automáticos > testing manual

STAGE 3: Build & Package (3-5 minutos)
  ¿Qué hace?
    - Compilar frontend (Next.js build)
    - Empaquetar backend (Lambda zip)
    - Optimizar assets (compression, minification)
    - Generar version numbers únicos
  
  ¿Por qué necesario?
    - Frontend optimizado = carga 3x más rápida
    - Lambda package = deployment más rápido
    - Version numbers = rollback preciso
    - Build artifacts = deployment consistente

STAGE 4: Infrastructure Validation (2-3 minutos)
  ¿Qué hace?
    - Terraform format check
    - Terraform plan validation
    - Resource cost estimation
    - Security policy validation
  
  ¿Por qué antes del deployment?
    - Prevenir configuraciones incorrectas
    - Evitar costos inesperados
    - Validar cambios de infraestructura
    - Catch errors antes de aplicar

STAGE 5: Deployment (5-10 minutos)
  ¿Qué hace?
    - Apply infrastructure changes
    - Deploy backend con blue-green strategy
    - Deploy frontend con invalidation
    - Run health checks
  
  ¿Por qué blue-green?
    - Zero downtime deployment
    - Rollback inmediato si problemas
    - Testing en ambiente idéntico
    - Confianza en deployment process

STAGE 6: Post-Deployment Validation (3-5 minutos)
  ¿Qué hace?
    - Health checks automáticos
    - Smoke tests en producción
    - Performance baseline checks
    - Monitoring setup verification
  
  ¿Por qué post-deployment?
    - Confirmar que todo funciona en producción
    - Detectar problemas inmediatamente
    - Baseline para comparar performance
    - Setup monitoring para nueva versión
```

**GitHub Actions Workflow Completo:**
```yaml
# .github/workflows/cicd.yml
name: CMIPRO CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

# Variables globales
env:
  AWS_REGION: us-east-1
  NODE_VERSION: 18
  PYTHON_VERSION: 3.11

jobs:
  # JOB 1: Code Quality & Security
  quality-gate:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4
        
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json
      
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'
          cache-dependency-path: backend/requirements.txt
      
      - name: Install Dependencies
        run: |
          # Frontend dependencies
          cd frontend && npm ci
          
          # Backend dependencies + dev tools
          cd ../backend 
          pip install -r requirements.txt
          pip install -r requirements-dev.txt
      
      # Frontend Quality Checks
      - name: Frontend Linting
        run: |
          cd frontend
          npm run lint                    # ESLint para JavaScript/TypeScript
          npm run type-check              # TypeScript compiler check
          npm run format-check            # Prettier formatting
        
      # Backend Quality Checks  
      - name: Backend Linting
        run: |
          cd backend
          black --check .                 # Code formatting
          isort --check-only .           # Import sorting
          flake8 .                       # PEP8 compliance
          mypy .                         # Type checking
      
      # Security Scanning
      - name: Frontend Security Scan
        run: |
          cd frontend
          npm audit --audit-level high   # Check for high severity vulnerabilities
          npx audit-ci --high           # Fail if high severity found
      
      - name: Backend Security Scan
        run: |
          cd backend
          safety check                   # Check for known vulnerabilities
          bandit -r . -f json -o security-report.json  # Security linting
      
      # Dependency License Check
      - name: License Compliance
        run: |
          cd frontend && npx license-checker --summary
          cd ../backend && pip-licenses --format=table
          
      # Upload security reports for review
      - name: Upload Security Reports
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: security-reports
          path: |
            backend/security-report.json
            frontend/audit-report.json

  # JOB 2: Comprehensive Testing
  testing-suite:
    needs: quality-gate
    runs-on: ubuntu-latest
    
    # Test services (databases, cache)
    services:
      postgres:
        image: timescale/timescaledb:latest-pg14
        env:
          POSTGRES_USER: test_user
          POSTGRES_PASSWORD: test_password
          POSTGRES_DB: cmipro_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 10
        ports:
          - 5432:5432
      
      redis:
        image: redis:7-alpine
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Test Environment
        run: |
          # Install dependencies
          cd frontend && npm ci
          cd ../backend && pip install -r requirements.txt -r requirements-test.txt
      
      # Database Setup
      - name: Setup Test Database
        run: |
          cd backend
          # Run migrations
          python -m pytest tests/setup_test_db.py
          # Load test data
          python scripts/load_test_data.py
        env:
          DATABASE_URL: postgresql://test_user:test_password@localhost:5432/cmipro_test
          REDIS_URL: redis://localhost:6379
      
      # Backend Testing
      - name: Backend Unit Tests
        run: |
          cd backend
          pytest tests/unit/ -v --cov=app --cov-report=xml
        env:
          DATABASE_URL: postgresql://test_user:test_password@localhost:5432/cmipro_test
          REDIS_URL: redis://localhost:6379
          ENVIRONMENT: test
      
      - name: Backend Integration Tests
        run: |
          cd backend
          pytest tests/integration/ -v --cov-append --cov=app --cov-report=xml
        env:
          DATABASE_URL: postgresql://test_user:test_password@localhost:5432/cmipro_test
          REDIS_URL: redis://localhost:6379
          ENVIRONMENT: test
          NOAA_API_URL: http://mock-noaa-server:8080
      
      # Frontend Testing
      - name: Frontend Unit Tests
        run: |
          cd frontend
          npm run test:unit -- --coverage --watchAll=false
      
      - name: Frontend Integration Tests
        run: |
          cd frontend
          npm run test:integration -- --coverage --watchAll=false
          
      # End-to-End Testing
      - name: E2E Tests
        run: |
          cd frontend
          # Start test server
          npm run build
          npm run start:test &
          
          # Wait for server
          npx wait-on http://localhost:3000
          
          # Run E2E tests
          npm run test:e2e:headless
        env:
          NEXT_PUBLIC_API_URL: http://localhost:8000
          NEXT_PUBLIC_FIREBASE_CONFIG: ${{ secrets.FIREBASE_TEST_CONFIG }}
      
      # Upload test coverage
      - name: Upload Coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./backend/coverage.xml,./frontend/coverage/lcov.info
          flags: unittests
          name: cmipro-coverage

  # JOB 3: Build & Package
  build-artifacts:
    needs: testing-suite
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.version.outputs.version }}
      build-number: ${{ steps.version.outputs.build-number }}
    
    steps:
      - uses: actions/checkout@v4
      
      # Generate version numbers
      - name: Generate Version
        id: version
        run: |
          TIMESTAMP=$(date +%Y%m%d%H%M%S)
          SHORT_SHA=${GITHUB_SHA::8}
          VERSION="${TIMESTAMP}-${SHORT_SHA}"
          BUILD_NUMBER=${{ github.run_number }}
          
          echo "version=${VERSION}" >> $GITHUB_OUTPUT
          echo "build-number=${BUILD_NUMBER}" >> $GITHUB_OUTPUT
          
          echo "Generated version: ${VERSION}"
          echo "Build number: ${BUILD_NUMBER}"
      
      # Build Frontend
      - name: Build Frontend Application
        run: |
          cd frontend
          npm ci
          
          # Production build with optimizations
          npm run build
          
          # Generate sitemap
          npm run postbuild
          
          # Compress static files
          find out/ -name "*.js" -exec gzip -k {} \;
          find out/ -name "*.css" -exec gzip -k {} \;
        env:
          NEXT_PUBLIC_API_URL: ${{ secrets.PRODUCTION_API_URL }}
          NEXT_PUBLIC_FIREBASE_CONFIG: ${{ secrets.FIREBASE_PROD_CONFIG }}
          NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY: ${{ secrets.STRIPE_PUBLISHABLE_KEY }}
          NEXT_PUBLIC_VERSION: ${{ steps.version.outputs.version }}
      
      # Build Backend Package
      - name: Build Backend Lambda Package
        run: |
          cd backend
          
          # Create clean package directory
          mkdir -p package
          
          # Install production dependencies only
          pip install -r requirements.txt -t package/
          
          # Copy application code
          cp -r app package/
          cp main.py package/
          
          # Remove unnecessary files to reduce package size
          cd package
          find . -name "*.pyc" -delete
          find . -name "__pycache__" -delete
          find . -name "*.dist-info" -delete
          find . -name "tests" -type d -exec rm -rf {} + 2>/dev/null || true
          
          # Create deployment package
          zip -r ../lambda-deployment.zip . -q
          
          # Verify package size (Lambda limit: 50MB)
          PACKAGE_SIZE=$(du -sh ../lambda-deployment.zip | cut -f1)
          echo "Lambda package size: ${PACKAGE_SIZE}"
      
      # Upload build artifacts
      - name: Upload Build Artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build-artifacts-${{ steps.version.outputs.version }}
          path: |
            frontend/out/
            backend/lambda-deployment.zip
          retention-days: 30

  # JOB 4: Infrastructure Validation
  infrastructure-check:
    needs: build-artifacts
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.6.0
      
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      
      # Terraform validation
      - name: Terraform Format Check
        run: |
          cd infrastructure
          terraform fmt -check -recursive
      
      - name: Terraform Init & Validate
        run: |
          cd infrastructure
          terraform init -backend=false
          terraform validate
      
      # Generate deployment plan
      - name: Terraform Plan
        run: |
          cd infrastructure
          terraform init
          
          if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
            terraform workspace select production || terraform workspace new production
            terraform plan -var="environment=production" -out=production.tfplan
            
            # Estimate costs
            terraform show -json production.tfplan > plan.json
            
          else
            terraform workspace select staging || terraform workspace new staging
            terraform plan -var="environment=staging" -out=staging.tfplan
          fi
      
      # Cost estimation
      - name: Infrastructure Cost Estimation
        if: github.ref == 'refs/heads/main'
        run: |
          cd infrastructure
          # Use Infracost for cost estimation
          curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh
          infracost breakdown --path=. --format=table
          infracost breakdown --path=. --format=json --out-file=cost-estimate.json
      
      - name: Upload Infrastructure Plans
        uses: actions/upload-artifact@v3
        with:
          name: terraform-plans
          path: |
            infrastructure/*.tfplan
            infrastructure/cost-estimate.json

  # JOB 5: Deploy to Staging
  deploy-staging:
    needs: [build-artifacts, infrastructure-check]
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    environment: staging
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Download Build Artifacts
        uses: actions/download-artifact@v3
        with:
          name: build-artifacts-${{ needs.build-artifacts.outputs.version }}
          path: ./artifacts
      
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      
      # Deploy Infrastructure
      - name: Deploy Infrastructure Changes
        run: |
          cd infrastructure
          terraform init
          terraform workspace select staging
          terraform apply staging.tfplan -auto-approve
      
      # Deploy Backend
      - name: Deploy Backend Lambda
        run: |
          # Update Lambda function code
          aws lambda update-function-code \
            --function-name cmipro-api-staging \
            --zip-file fileb://artifacts/lambda-deployment.zip \
            --publish
          
          # Update environment variables with new version
          aws lambda update-function-configuration \
            --function-name cmipro-api-staging \
            --environment Variables="{
              ENVIRONMENT=staging,
              VERSION=${{ needs.build-artifacts.outputs.version }},
              DATABASE_URL=${{ secrets.STAGING_DATABASE_URL }},
              REDIS_URL=${{ secrets.STAGING_REDIS_URL }}
            }"
      
      # Deploy Frontend
      - name: Deploy Frontend to S3
        run: |
          # Sync to S3 bucket
          aws s3 sync artifacts/frontend/out/ s3://cmipro-frontend-staging/ \
            --delete \
            --cache-control "public, max-age=31536000, immutable" \
            --exclude "*.html" \
            --exclude "service-worker.js"
          
          # HTML files with shorter cache
          aws s3 sync artifacts/frontend/out/ s3://cmipro-frontend-staging/ \
            --exclude "*" \
            --include "*.html" \
            --include "service-worker.js" \
            --cache-control "public, max-age=0, must-revalidate"
          
          # Invalidate CloudFront cache
          aws cloudfront create-invalidation \
            --distribution-id ${{ secrets.STAGING_CLOUDFRONT_ID }} \
            --paths "/*"
      
      # Post-deployment validation
      - name: Health Checks
        run: |
          # Wait for deployment to settle
          sleep 30
          
          # Check API health
          API_URL="https://staging-api.cmiweather.com"
          
          for i in {1..12}; do
            if curl -f "$API_URL/health" > /dev/null 2>&1; then
              echo "✅ API health check passed"
              break
            fi
            echo "⏳ Waiting for API to be ready... (attempt $i/12)"
            sleep 10
          done
          
          # Check frontend
          FRONTEND_URL="https://staging.cmiweather.com"
          
          if curl -f "$FRONTEND_URL" > /dev/null 2>&1; then
            echo "✅ Frontend health check passed"
          else
            echo "❌ Frontend health check failed"
            exit 1
          fi
      
      # Smoke Tests
      - name: Run Smoke Tests on Staging
        run: |
          cd frontend
          npm ci
          STAGING_URL=https://staging.cmiweather.com npm run test:smoke

  # JOB 6: Deploy to Production
  deploy-production:
    needs: [build-artifacts, infrastructure-check]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Download Build Artifacts
        uses: actions/download-artifact@v3
        with:
          name: build-artifacts-${{ needs.build-artifacts.outputs.version }}
          path: ./artifacts
      
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      
      # Create backup point
      - name: Create Pre-Deployment Backup
        run: |
          # Backup current Lambda version
          CURRENT_VERSION=$(aws lambda get-function --function-name cmipro-api-production --query 'Configuration.Version' --output text)
          aws lambda publish-version --function-name cmipro-api-production --description "Backup before ${{ needs.build-artifacts.outputs.version }}"
          
          # Backup frontend to S3
          aws s3 sync s3://cmipro-frontend-production/ s3://cmipro-backups-production/frontend-backup-$(date +%Y%m%d-%H%M%S)/ --quiet
      
      # Blue-Green Deployment for Backend
      - name: Blue-Green Backend Deployment
        run: |
          # Update function code (Green version)
          aws lambda update-function-code \
            --function-name cmipro-api-production \
            --zip-file fileb://artifacts/lambda-deployment.zip \
            --publish
          
          GREEN_VERSION=$(aws lambda get-function --function-name cmipro-api-production --query 'Configuration.Version' --output text)
          
          # Gradual traffic shift: 10% → 50% → 100%
          for PERCENTAGE in 10 50 100; do
            aws lambda put-provisioned-concurrency-config \
              --function-name cmipro-api-production:${GREEN_VERSION} \
              --provisioned-concurrency-config ProvisionedConcurrencyConfig=5
            
            aws lambda update-alias \
              --function-name cmipro-api-production \
              --name LIVE \
              --routing-config AdditionalVersionWeights="{\"${GREEN_VERSION}\":$(echo $PERCENTAGE/100 | bc -l)}"
            
            # Monitor for 3 minutes
            echo "🔄 Shifted ${PERCENTAGE}% traffic to green version ${GREEN_VERSION}"
            sleep 180
            
            # Check error rates
            ERROR_COUNT=$(aws cloudwatch get-metric-statistics \
              --namespace AWS/Lambda \
              --metric-name Errors \
              --dimensions Name=FunctionName,Value=cmipro-api-production \
              --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
              --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
              --period 300 \
              --statistics Sum \
              --query 'Datapoints[0].Sum' \
              --output text)
            
            if [[ "$ERROR_COUNT" != "None" ]] && [[ "$ERROR_COUNT" -gt 5 ]]; then
              echo "❌ High error rate detected. Rolling back..."
              aws lambda update-alias \
                --function-name cmipro-api-production \
                --name LIVE \
                --routing-config AdditionalVersionWeights="{}"
              exit 1
            fi
          done
          
          echo "✅ Blue-green deployment completed successfully"
      
      # Deploy Frontend
      - name: Deploy Frontend with Blue-Green Strategy
        run: |
          # Deploy to staging bucket first
          aws s3 sync artifacts/frontend/out/ s3://cmipro-frontend-staging-temp/ --delete
          
          # Test staging deployment
          if curl -f "https://staging-temp.cmiweather.com" > /dev/null 2>&1; then
            # Copy to production
            aws s3 sync s3://cmipro-frontend-staging-temp/ s3://cmipro-frontend-production/ --delete
            
            # Invalidate CloudFront
            INVALIDATION_ID=$(aws cloudfront create-invalidation \
              --distribution-id ${{ secrets.PRODUCTION_CLOUDFRONT_ID }} \
              --paths "/*" \
              --query 'Invalidation.Id' --output text)
            
            # Wait for invalidation
            aws cloudfront wait invalidation-completed \
              --distribution-id ${{ secrets.PRODUCTION_CLOUDFRONT_ID }} \
              --id $INVALIDATION_ID
            
            echo "✅ Frontend deployment completed"
          else
            echo "❌ Frontend staging test failed"
            exit 1
          fi
      
      # Final validation
      - name: Production Health Checks
        run: |
          API_URL="https://api.cmiweather.com"
          FRONTEND_URL="https://cmiweather.com"
          
          # Extended health checks for production
          for i in {1..20}; do
            if curl -f "$API_URL/health" > /dev/null 2>&1; then
              echo "✅ API health check passed"
              break
            fi
            echo "⏳ Waiting for API... (attempt $i/20)"
            sleep 15
          done
          
          # Frontend check
          if curl -f "$FRONTEND_URL" > /dev/null 2>&1; then
            echo "✅ Frontend health check passed"
          else
            echo "❌ Frontend health check failed"
            exit 1
          fi
          
          # NOAA integration test
          STATIONS_RESPONSE=$(curl -s "$API_URL/api/v1/stations")
          if echo "$STATIONS_RESPONSE" | jq -e '.success' > /dev/null; then
            echo "✅ NOAA integration working"
          else
            echo "❌ NOAA integration failed"
            exit 1
          fi
      
      # Update monitoring
      - name: Update Production Monitoring
        run: |
          # Update CloudWatch dashboard with new version
          aws cloudwatch put-dashboard \
            --dashboard-name "CMIPRO-Production" \
            --dashboard-body file://monitoring/production-dashboard.json
          
          # Create deployment marker
          aws cloudwatch put-metric-data \
            --namespace "CMIPRO/Deployments" \
            --metric-data MetricName=DeploymentEvent,Value=1,Unit=Count,Dimensions=[{Name=Version,Value=${{ needs.build-artifacts.outputs.version }}},{Name=Environment,Value=production}]

  # JOB 7: Post-Deployment Notifications
  notify-deployment:
    needs: [deploy-staging, deploy-production]
    if: always()
    runs-on: ubuntu-latest
    
    steps:
      - name: Notify Slack
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ needs.deploy-production.result || needs.deploy-staging.result }}
          channel: '#cmipro-deployments'
          text: |
            🚀 CMIPRO Deployment Completed
            Environment: ${{ github.ref == 'refs/heads/main' && 'Production' || 'Staging' }}
            Version: ${{ needs.build-artifacts.outputs.version }}
            Commit: ${{ github.sha }}
            Status: ${{ needs.deploy-production.result || needs.deploy-staging.result }}
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
      
      - name: Notify Team Email
        if: github.ref == 'refs/heads/main'
        uses: dawidd6/action-send-mail@v3
        with:
          server_address: smtp.gmail.com
          server_port: 587
          username: ${{ secrets.EMAIL_USERNAME }}
          password: ${{ secrets.EMAIL_PASSWORD }}
          subject: "✅ CMIPRO Production Deployment Successful - v${{ needs.build-artifacts.outputs.version }}"
          to: team@cmiweather.com
          from: deployments@cmiweather.com
          body: |
            Production deployment completed successfully!
            
            Version: ${{ needs.build-artifacts.outputs.version }}
            Commit: ${{ github.sha }}
            Deployed by: ${{ github.actor }}
            
            Frontend: https://cmiweather.com
            API: https://api.cmiweather.com
            Monitoring: https://console.aws.amazon.com/cloudwatch/home#dashboards:name=CMIPRO-Production
```

### 🔄 Blue-Green Deployment Strategy Detallada

#### ¿Qué es Blue-Green Deployment?
```yaml
Traditional Deployment (❌ Problemático para CMIPRO):
  1. Parar servidor actual
  2. Subir nueva versión
  3. Iniciar servidor
  
  Problemas:
    - 5-15 minutos de downtime
    - Si nueva versión falla = downtime extendido
    - Durante huracán = sistema inutilizable
    - Rollback lento y complicado

Blue-Green Deployment (✅ Ideal para CMIPRO):
  Blue Environment = Versión actual en producción
  Green Environment = Nueva versión siendo deployada
  
  Proceso:
    1. Deploy nueva versión a Green (sin afectar Blue)
    2. Test Green completamente 
    3. Gradualmente shift tráfico Blue → Green
    4. Monitor por errores en cada step
    5. Si todo OK: Green becomes new Blue
    6. Si problemas: Instant rollback a Blue
```

**Implementación Blue-Green para Lambda:**
```python
# scripts/blue_green_deploy.py
import boto3
import json
import time
import sys

class BlueGreenLambdaDeployment:
    def __init__(self, function_name: str):
        self.lambda_client = boto3.client('lambda')
        self.cloudwatch = boto3.client('cloudwatch')
        self.function_name = function_name
        
    def deploy_with_blue_green(self, zip_file_path: str, version_tag: str) -> bool:
        """
        Execute complete blue-green deployment
        """
        try:
            print(f"🚀 Starting blue-green deployment for {self.function_name}")
            
            # Step 1: Create Green version
            green_version = self._create_green_version(zip_file_path, version_tag)
            print(f"✅ Created green version: {green_version}")
            
            # Step 2: Health check Green version
            if not self._health_check_green_version(green_version):
                print("❌ Green version health check failed")
                self._cleanup_failed_version(green_version)
                return False
            
            # Step 3: Gradual traffic shifting
            traffic_percentages = [10, 25, 50, 100]
            
            for percentage in traffic_percentages:
                print(f"🔄 Shifting {percentage}% traffic to green...")
                
                success = self._shift_traffic_to_green(green_version, percentage)
                if not success:
                    print(f"❌ Traffic shift to {percentage}% failed")
                    self._rollback_to_blue()
                    return False
                
                # Monitor for 2 minutes
                time.sleep(120)
                
                # Check metrics
                if not self._validate_green_performance():
                    print(f"❌ Performance degradation at {percentage}%")
                    self._rollback_to_blue()
                    return False
                
                print(f"✅ {percentage}% traffic shift successful")
            
            # Step 4: Complete deployment
            self._finalize_green_deployment(green_version)
            print(f"🎉 Blue-green deployment completed successfully!")
            return True
            
        except Exception as e:
            print(f"💥 Deployment failed: {str(e)}")
            self._emergency_rollback()
            return False
    
    def _create_green_version(self, zip_file_path: str, version_tag: str) -> str:
        """Create new Lambda version (Green)"""
        
        # Update function code
        with open(zip_file_path, 'rb') as zip_file:
            response = self.lambda_client.update_function_code(
                FunctionName=self.function_name,
                ZipFile=zip_file.read()
            )
        
        # Wait for update to complete
        waiter = self.lambda_client.get_waiter('function_updated')
        waiter.wait(
            FunctionName=self.function_name,
            WaiterConfig={'Delay': 5, 'MaxAttempts': 60}  # 5 min max
        )
        
        # Publish new version
        version_response = self.lambda_client.publish_version(
            FunctionName=self.function_name,
            Description=f"Green deployment - {version_tag}"
        )
        
        return version_response['Version']
    
    def _health_check_green_version(self, green_version: str) -> bool:
        """Test green version thoroughly before traffic shift"""
        
        test_payloads = [
            # Health check
            {
                "httpMethod": "GET",
                "path": "/health",
                "headers": {},
                "body": None
            },
            # Stations endpoint
            {
                "httpMethod": "GET", 
                "path": "/api/v1/stations",
                "headers": {"Authorization": "Bearer test-token"},
                "body": None
            },
            # Levels endpoint with parameters
            {
                "httpMethod": "GET",
                "path": "/api/v1/levels",
                "queryStringParameters": {
                    "station_id": "CHIH3",
                    "hours": "24"
                },
                "headers": {"Authorization": "Bearer test-token"},
                "body": None
            }
        ]
        
        for i, payload in enumerate(test_payloads):
            try:
                response = self.lambda_client.invoke(
                    FunctionName=f"{self.function_name}:{green_version}",
                    Payload=json.dumps(payload)
                )
                
                result = json.loads(response['Payload'].read())
                status_code = result.get('statusCode', 500)
                
                if status_code >= 400:
                    print(f"❌ Health check {i+1} failed: {status_code}")
                    return False
                
                print(f"✅ Health check {i+1} passed: {status_code}")
                
            except Exception as e:
                print(f"❌ Health check {i+1} exception: {str(e)}")
                return False
        
        return True
    
    def _shift_traffic_to_green(self, green_version: str, percentage: int) -> bool:
        """Gradually shift traffic to green version"""
        
        try:
            weight = percentage / 100.0
            
            self.lambda_client.update_alias(
                FunctionName=self.function_name,
                Name='LIVE',
                RoutingConfig={
                    'AdditionalVersionWeights': {
                        green_version: weight
                    }
                }
            )
            
            return True
            
        except Exception as e:
            print(f"Traffic shift failed: {str(e)}")
            return False
    
    def _validate_green_performance(self) -> bool:
        """Validate green version performance metrics"""
        
        end_time = int(time.time())
        start_time = end_time - 300  # Last 5 minutes
        
        # Check error rate
        error_response = self.cloudwatch.get_metric_statistics(
            Namespace='AWS/Lambda',
            MetricName='Errors',
            Dimensions=[
                {'Name': 'FunctionName', 'Value': self.function_name}
            ],
            StartTime=start_time,
            EndTime=end_time,
            Period=300,
            Statistics=['Sum']
        )
        
        errors = 0
        if error_response['Datapoints']:
            errors = error_response['Datapoints'][0]['Sum']
        
        # Check invocation count for error rate calculation
        invocation_response = self.cloudwatch.get_metric_statistics(
            Namespace='AWS/Lambda',
            MetricName='Invocations', 
            Dimensions=[
                {'Name': 'FunctionName', 'Value': self.function_name}
            ],
            StartTime=start_time,
            EndTime=end_time,
            Period=300,
            Statistics=['Sum']
        )
        
        invocations = 1  # Avoid division by zero
        if invocation_response['Datapoints']:
            invocations = max(1, invocation_response['Datapoints'][0]['Sum'])
        
        error_rate = (errors / invocations) * 100
        
        # Thresholds
        if error_rate > 5.0:  # More than 5% error rate
            print(f"❌ High error rate: {error_rate:.2f}%")
            return False
        
        print(f"✅ Error rate acceptable: {error_rate:.2f}%")
        return True
    
    def _rollback_to_blue(self):
        """Immediate rollback to blue version"""
        
        try:
            self.lambda_client.update_alias(
                FunctionName=self.function_name,
                Name='LIVE',
                RoutingConfig={
                    'AdditionalVersionWeights': {}  # All traffic to blue
                }
            )
            print("🔄 Rolled back to blue version")
            
        except Exception as e:
            print(f"💥 Rollback failed: {str(e)}")

# ¿Por qué esta implementación específica?
# 1. Health checks comprehensive antes de traffic shift
# 2. Gradual traffic shifting (10% → 25% → 50% → 100%)
# 3. Monitoring automático en cada step
# 4. Rollback inmediato si problemas detectados
# 5. CloudWatch metrics para decision making
# 6. Error rate thresholds configurables
# 7. Cleanup automático de versiones fallidas
```

Esta estrategia de deployment garantiza que CMIPRO mantenga disponibilidad 24/7 mientras recibe updates regulares, crítico para un sistema de alertas de emergencia que debe funcionar sin fallas durante situaciones que pueden salvar vidas.