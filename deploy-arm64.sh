#!/bin/bash

# Script otimizado para deploy ARM64 no MicroK8s
set -e

echo "🚀 Deploy Hazelcast ARM64 para MicroK8s..."

# Verificar arquitetura
ARCH=$(uname -m)
echo "📋 Arquitetura detectada: $ARCH"

if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    echo "✅ Sistema ARM64 detectado - otimizando para arquitetura nativa"
    DOCKERFILE="Dockerfile.arm64"
    PLATFORM_FLAG="--platform linux/arm64"
else
    echo "⚠️  Sistema x86_64 detectado - construindo para ARM64 (cross-compilation)"
    DOCKERFILE="Dockerfile.arm64"
    PLATFORM_FLAG="--platform linux/arm64"
    
    # Verificar se buildx está disponível para cross-compilation
    if ! docker buildx version >/dev/null 2>&1; then
        echo "❌ Docker buildx não encontrado. Instalando..."
        docker buildx create --name multiarch --driver docker-container --use || true
    fi
fi

# Verificar se MicroK8s está rodando
echo "📋 Verificando MicroK8s..."
microk8s status --wait-ready

# Construir aplicação Java
echo "🔨 Construindo aplicação Java..."
mvn clean package -q

# Construir imagem Docker ARM64
echo "🐳 Construindo imagem Docker ARM64..."
docker build $PLATFORM_FLAG -f $DOCKERFILE -t localhost:32000/hazelcast-client:latest .

# Push para registry local
echo "📤 Enviando para registry MicroK8s..."
docker push localhost:32000/hazelcast-client:latest

# Deploy apenas cliente (servidor já existe)
echo "☸️  Deployando apenas o cliente..."
microk8s kubectl apply -f k8s/hazelcast-client-deployment.yaml

# Aguardar apenas o cliente
echo "⏳ Aguardando cliente ARM64..."
microk8s kubectl wait --for=condition=ready pod -l app=hazelcast-client --timeout=300s

echo "✅ Deploy do cliente ARM64 concluído!"
echo ""
echo "📊 Verificando cliente ARM64:"
microk8s kubectl get pods -l app=hazelcast-client -o wide
echo ""
echo "🔍 Verificar logs do cliente:"
echo "  microk8s kubectl logs -l app=hazelcast-client -f"
