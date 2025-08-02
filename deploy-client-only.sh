#!/bin/bash

# Script para deploy APENAS do cliente Hazelcast
# Use quando já tiver o servidor Hazelcast rodando
set -e

echo "🚀 Deploy apenas do cliente Hazelcast..."

# Verificar se MicroK8s está rodando
echo "📋 Verificando MicroK8s..."
microk8s status --wait-ready

# Construir aplicação Java
echo "🔨 Construindo aplicação Java..."
mvn clean package -q

# Construir imagem Docker para ARM64
echo "🐳 Construindo imagem Docker ARM64..."
docker build --platform linux/arm64 -f Dockerfile.arm64 -t localhost:32000/hazelcast-client:latest .

# Push para registry local
echo "📤 Enviando para registry..."
docker push localhost:32000/hazelcast-client:latest

# Deploy apenas o cliente
echo "☸️  Deployando APENAS o cliente..."
microk8s kubectl apply -f k8s/hazelcast-client-deployment.yaml

# Aguardar cliente ficar pronto
echo "⏳ Aguardando cliente ficar pronto..."
microk8s kubectl wait --for=condition=ready pod -l app=hazelcast-client --timeout=300s

echo "✅ Cliente deployado com sucesso!"
echo ""
echo "📊 Status do cliente:"
microk8s kubectl get pods -l app=hazelcast-client -o wide

echo ""
echo "📝 Logs do cliente:"
echo "  microk8s kubectl logs -l app=hazelcast-client -f"

echo ""
echo "🔗 Port forward do cliente:"
echo "  microk8s kubectl port-forward service/hazelcast-client-service 8080:8080"

echo ""
echo "🔍 Verificar se conectou ao servidor existente:"
echo "  microk8s kubectl logs -l app=hazelcast-client --tail=20"
