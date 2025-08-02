# PowerShell Script para Deploy no MicroK8s
# Execute: .\deploy-microk8s.ps1

Write-Host "🚀 Iniciando deploy do Hazelcast no MicroK8s..." -ForegroundColor Green

# Verificar se MicroK8s está rodando
Write-Host "📋 Verificando status do MicroK8s..." -ForegroundColor Yellow
& microk8s status --wait-ready
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro: MicroK8s não está rodando" -ForegroundColor Red
    exit 1
}

# Construir aplicação Java
Write-Host "🔨 Construindo aplicação Java..." -ForegroundColor Yellow
& mvn clean package -q
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro: Falha ao construir aplicação" -ForegroundColor Red
    exit 1
}

# Construir imagem Docker para ARM64
Write-Host "🐳 Construindo imagem Docker para ARM64..." -ForegroundColor Yellow
& docker build --platform linux/arm64 -f Dockerfile.arm64 -t localhost:32000/hazelcast-client:latest .
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro: Falha ao construir imagem" -ForegroundColor Red
    exit 1
}

# Push para registry local
Write-Host "📤 Enviando imagem para registry..." -ForegroundColor Yellow
& docker push localhost:32000/hazelcast-client:latest
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro: Falha ao enviar imagem" -ForegroundColor Red
    exit 1
}

# Deploy apenas o cliente (servidor já existe)
Write-Host "☸️  Deployando apenas o cliente..." -ForegroundColor Yellow

Write-Host "  - Hazelcast Client..." -ForegroundColor Cyan
& microk8s kubectl apply -f k8s/hazelcast-client-deployment.yaml

# Aguardar apenas o cliente ficar pronto
Write-Host "⏳ Aguardando cliente ficar pronto..." -ForegroundColor Yellow
& microk8s kubectl wait --for=condition=ready pod -l app=hazelcast-client --timeout=300s

# Mostrar status
Write-Host "✅ Deploy do cliente concluído com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Status do cliente:" -ForegroundColor Cyan
& microk8s kubectl get pods -l app=hazelcast-client

Write-Host ""
Write-Host "📝 Para ver os logs do cliente:" -ForegroundColor Magenta
Write-Host "  Hazelcast Client: microk8s kubectl logs -l app=hazelcast-client -f"

Write-Host ""
Write-Host "🔗 Para acessar o cliente localmente:" -ForegroundColor Magenta
Write-Host "  Client: microk8s kubectl port-forward service/hazelcast-client-service 8080:8080"
