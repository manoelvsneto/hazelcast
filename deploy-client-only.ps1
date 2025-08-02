# Script PowerShell para deploy APENAS do cliente
Write-Host "🚀 Deploy apenas do cliente Hazelcast..." -ForegroundColor Green

# Verificar MicroK8s
Write-Host "📋 Verificando MicroK8s..." -ForegroundColor Yellow
& microk8s status --wait-ready

# Build Java
Write-Host "🔨 Construindo aplicação..." -ForegroundColor Yellow
& mvn clean package -q

# Build Docker ARM64
Write-Host "🐳 Construindo imagem ARM64..." -ForegroundColor Yellow
& docker build --platform linux/arm64 -f Dockerfile.arm64 -t localhost:32000/hazelcast-client:latest .

# Push
Write-Host "📤 Enviando para registry..." -ForegroundColor Yellow
& docker push localhost:32000/hazelcast-client:latest

# Deploy apenas cliente
Write-Host "☸️  Deploy APENAS do cliente..." -ForegroundColor Yellow
& microk8s kubectl apply -f k8s/hazelcast-client-deployment.yaml

# Wait
Write-Host "⏳ Aguardando cliente..." -ForegroundColor Yellow
& microk8s kubectl wait --for=condition=ready pod -l app=hazelcast-client --timeout=300s

Write-Host "✅ Cliente deployado!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Status do cliente:" -ForegroundColor Cyan
& microk8s kubectl get pods -l app=hazelcast-client -o wide

Write-Host ""
Write-Host "📝 Comandos úteis:" -ForegroundColor Magenta
Write-Host "  Logs: microk8s kubectl logs -l app=hazelcast-client -f"
Write-Host "  Port forward: microk8s kubectl port-forward service/hazelcast-client-service 8080:8080"
