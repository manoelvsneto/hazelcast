# PowerShell script otimizado para ARM64
Write-Host "🚀 Deploy Hazelcast ARM64 para MicroK8s..." -ForegroundColor Green

# Verificar arquitetura
$arch = $env:PROCESSOR_ARCHITECTURE
Write-Host "📋 Arquitetura: $arch" -ForegroundColor Yellow

if ($arch -eq "ARM64") {
    Write-Host "✅ Sistema ARM64 nativo detectado" -ForegroundColor Green
    $dockerfile = "Dockerfile.arm64"
    $platformFlag = "--platform linux/arm64"
} else {
    Write-Host "⚠️  Cross-compilation para ARM64" -ForegroundColor Yellow
    $dockerfile = "Dockerfile.arm64"  
    $platformFlag = "--platform linux/arm64"
    
    # Verificar buildx
    $buildx = docker buildx version 2>$null
    if (-not $buildx) {
        Write-Host "📦 Configurando Docker buildx..." -ForegroundColor Cyan
        docker buildx create --name multiarch --driver docker-container --use
    }
}

# Verificar MicroK8s
Write-Host "📋 Verificando MicroK8s..." -ForegroundColor Yellow
& microk8s status --wait-ready

# Build Java
Write-Host "🔨 Construindo aplicação..." -ForegroundColor Yellow
& mvn clean package -q

# Build Docker ARM64
Write-Host "🐳 Construindo imagem ARM64..." -ForegroundColor Yellow
& docker build $platformFlag -f $dockerfile -t localhost:32000/hazelcast-client:latest .

# Push
Write-Host "📤 Enviando para registry..." -ForegroundColor Yellow
& docker push localhost:32000/hazelcast-client:latest

# Deploy apenas cliente (servidor já existe)
Write-Host "☸️  Deploy apenas cliente..." -ForegroundColor Yellow
& microk8s kubectl apply -f k8s/hazelcast-client-deployment.yaml

# Wait apenas cliente
Write-Host "⏳ Aguardando cliente ARM64..." -ForegroundColor Yellow
& microk8s kubectl wait --for=condition=ready pod -l app=hazelcast-client --timeout=300s

Write-Host "✅ Deploy do cliente ARM64 concluído!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Status do cliente:" -ForegroundColor Cyan
& microk8s kubectl get pods -l app=hazelcast-client -o wide
