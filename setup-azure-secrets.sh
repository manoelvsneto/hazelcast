#!/bin/bash

echo "🔐 Configuração de Secrets do Azure para Hazelcast"
echo "=================================================="
echo ""

# Função para criar secret SQL Server
create_sql_secret() {
    echo "📊 Configurando Azure SQL Server..."
    echo ""
    
    read -p "SQL Server Connection String: " SQL_CONN
    read -p "SQL Server Username: " SQL_USER
    read -s -p "SQL Server Password: " SQL_PASS
    echo ""
    echo ""
    
    if [[ -n "$SQL_CONN" && -n "$SQL_USER" && -n "$SQL_PASS" ]]; then
        microk8s kubectl create secret generic azure-sql-secret \
          --from-literal=connection-string="$SQL_CONN" \
          --from-literal=username="$SQL_USER" \
          --from-literal=password="$SQL_PASS" \
          --dry-run=client -o yaml | microk8s kubectl apply -f -
        
        echo "✅ Secret azure-sql-secret criado/atualizado"
    else
        echo "⚠️  Dados do SQL Server não fornecidos - pulando..."
    fi
}

# Função para criar secret Service Bus
create_servicebus_secret() {
    echo "📨 Configurando Azure Service Bus..."
    echo ""
    
    read -p "Service Bus Connection String: " SB_CONN
    
    if [[ -n "$SB_CONN" ]]; then
        microk8s kubectl create secret generic azure-servicebus-secret \
          --from-literal=connection-string="$SB_CONN" \
          --dry-run=client -o yaml | microk8s kubectl apply -f -
        
        echo "✅ Secret azure-servicebus-secret criado/atualizado"
    else
        echo "⚠️  Connection string do Service Bus não fornecida - pulando..."
    fi
}

# Menu principal
echo "Escolha uma opção:"
echo "1) Configurar Azure SQL Server"
echo "2) Configurar Azure Service Bus"
echo "3) Configurar ambos"
echo "4) Listar secrets existentes"
echo "5) Sair"
echo ""

read -p "Opção: " choice

case $choice in
    1)
        create_sql_secret
        ;;
    2)
        create_servicebus_secret
        ;;
    3)
        create_sql_secret
        echo ""
        create_servicebus_secret
        ;;
    4)
        echo "📋 Secrets existentes:"
        microk8s kubectl get secrets | grep azure
        echo ""
        echo "📋 Detalhes dos secrets:"
        microk8s kubectl describe secret azure-sql-secret 2>/dev/null || echo "azure-sql-secret não encontrado"
        echo ""
        microk8s kubectl describe secret azure-servicebus-secret 2>/dev/null || echo "azure-servicebus-secret não encontrado"
        ;;
    5)
        echo "👋 Saindo..."
        exit 0
        ;;
    *)
        echo "❌ Opção inválida"
        exit 1
        ;;
esac

echo ""
echo "🔍 Verificando secrets criados:"
microk8s kubectl get secrets | grep azure

echo ""
echo "🚀 Para deployar a aplicação:"
echo "   ./deploy-client-only.sh"
echo ""
echo "📊 Para ver logs:"
echo "   microk8s kubectl logs -l app=hazelcast-client -f"
