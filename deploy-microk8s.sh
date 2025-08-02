#!/bin/bash

# Script de Deploy para MicroK8s
# Execute este script para fazer deploy do Hazelcast no seu cluster MicroK8s

set -e

# Configurações
NAMESPACE="default"
REGISTRY="localhost:32000"  # Registro local do MicroK8s
IMAGE_NAME="hazelcast-client"
VERSION="latest"

echo "🚀 Iniciando deploy do Hazelcast no MicroK8s..."

# Verificar se o MicroK8s está rodando
if ! microk8s status --wait-ready; then
    echo "❌ MicroK8s não está rodando. Inicie com: microk8s start"
    exit 1
fi

# Habilitar addons necessários
echo "📦 Habilitando addons do MicroK8s..."
microk8s enable dns
microk8s enable registry
microk8s enable storage

# Construir a aplicação Java
echo "🔨 Construindo aplicação Java..."
mvn clean package -DskipTests

# Construir imagem Docker
echo "🐳 Construindo imagem Docker..."
docker build -t ${REGISTRY}/${IMAGE_NAME}:${VERSION} .

# Fazer push da imagem para o registro local
echo "📤 Enviando imagem para registro local..."
docker push ${REGISTRY}/${IMAGE_NAME}:${VERSION}

# Aplicar manifests do Kubernetes
echo "☸️ Aplicando manifests do Kubernetes..."

# RBAC primeiro
microk8s kubectl apply -f k8s/hazelcast-rbac.yaml

# ConfigMap
microk8s kubectl apply -f k8s/hazelcast-configmap.yaml

# Services
microk8s kubectl apply -f k8s/hazelcast-service.yaml

# Deployments
microk8s kubectl apply -f k8s/hazelcast-deployment.yaml

# Atualizar deployment do cliente com a imagem correta
sed "s|YOUR_REGISTRY|${REGISTRY}|g" k8s/hazelcast-client-deployment.yaml | \
sed "s|latest|${VERSION}|g" | \
microk8s kubectl apply -f -

# Aguardar pods ficarem prontos
echo "⏳ Aguardando pods ficarem prontos..."
microk8s kubectl wait --for=condition=ready pod -l app=hazelcast --timeout=300s
microk8s kubectl wait --for=condition=ready pod -l app=hazelcast-client --timeout=300s

# Mostrar status
echo "📊 Status do deployment:"
microk8s kubectl get pods -l app=hazelcast -o wide
microk8s kubectl get pods -l app=hazelcast-client -o wide
microk8s kubectl get services

# Mostrar logs do Hazelcast
echo "📝 Logs do Hazelcast (últimas 10 linhas):"
microk8s kubectl logs -l app=hazelcast --tail=10

echo "✅ Deploy concluído com sucesso!"
echo "🌐 Acesse o cluster Hazelcast em: http://localhost:30080"
echo "📊 Para ver logs: microk8s kubectl logs -f -l app=hazelcast"
echo "🔍 Para verificar status: microk8s kubectl get pods"
