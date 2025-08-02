#!/bin/bash

# Script de Deploy Melhorado para MicroK8s
set -e

echo "🚀 Iniciando deploy do Hazelcast no MicroK8s..."

# Verificar se MicroK8s está rodando
echo "📋 Verificando status do MicroK8s..."
microk8s status --wait-ready

# Construir aplicação Java
echo "🔨 Construindo aplicação Java..."
mvn clean package -q

# Construir imagem Docker para ARM64
echo "🐳 Construindo imagem Docker para ARM64..."
docker build --platform linux/arm64 -f Dockerfile.arm64 -t localhost:32000/hazelcast-client:latest .

# Push para registry local
echo "📤 Enviando imagem para registry..."
docker push localhost:32000/hazelcast-client:latest

# Aplicar apenas o cliente (servidor já está rodando)
echo "☸️  Deployando apenas o cliente Hazelcast..."

echo "  - Hazelcast Client..."
microk8s kubectl apply -f k8s/hazelcast-client-deployment.yaml

# Aguardar apenas o cliente ficar pronto
echo "⏳ Aguardando cliente ficar pronto..."
microk8s kubectl wait --for=condition=ready pod -l app=hazelcast-client --timeout=300s

# Mostrar status
echo "✅ Deploy do cliente concluído com sucesso!"
echo ""
echo "📊 Status do cliente:"
microk8s kubectl get pods -l app=hazelcast-client

echo ""
echo "📝 Para ver os logs do cliente:"
echo "  Hazelcast Client: microk8s kubectl logs -l app=hazelcast-client -f"

echo ""
echo "🔗 Para acessar o cliente localmente:"
echo "  Client: microk8s kubectl port-forward service/hazelcast-client-service 8080:8080"
