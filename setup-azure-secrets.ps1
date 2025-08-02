# PowerShell script para configurar secrets do Azure
Write-Host "🔐 Configuração de Secrets do Azure para Hazelcast" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""

function Create-SqlSecret {
    Write-Host "📊 Configurando Azure SQL Server..." -ForegroundColor Yellow
    Write-Host ""
    
    $sqlConn = Read-Host "SQL Server Connection String"
    $sqlUser = Read-Host "SQL Server Username"
    $sqlPass = Read-Host "SQL Server Password" -AsSecureString
    $sqlPassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sqlPass))
    
    if ($sqlConn -and $sqlUser -and $sqlPassPlain) {
        & microk8s kubectl create secret generic azure-sql-secret `
          --from-literal=connection-string="$sqlConn" `
          --from-literal=username="$sqlUser" `
          --from-literal=password="$sqlPassPlain" `
          --dry-run=client -o yaml | microk8s kubectl apply -f -
        
        Write-Host "✅ Secret azure-sql-secret criado/atualizado" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Dados do SQL Server não fornecidos - pulando..." -ForegroundColor Yellow
    }
}

function Create-ServiceBusSecret {
    Write-Host "📨 Configurando Azure Service Bus..." -ForegroundColor Yellow
    Write-Host ""
    
    $sbConn = Read-Host "Service Bus Connection String"
    
    if ($sbConn) {
        & microk8s kubectl create secret generic azure-servicebus-secret `
          --from-literal=connection-string="$sbConn" `
          --dry-run=client -o yaml | microk8s kubectl apply -f -
        
        Write-Host "✅ Secret azure-servicebus-secret criado/atualizado" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Connection string do Service Bus não fornecida - pulando..." -ForegroundColor Yellow
    }
}

# Menu principal
Write-Host "Escolha uma opção:" -ForegroundColor Cyan
Write-Host "1) Configurar Azure SQL Server"
Write-Host "2) Configurar Azure Service Bus" 
Write-Host "3) Configurar ambos"
Write-Host "4) Listar secrets existentes"
Write-Host "5) Sair"
Write-Host ""

$choice = Read-Host "Opção"

switch ($choice) {
    1 {
        Create-SqlSecret
    }
    2 {
        Create-ServiceBusSecret
    }
    3 {
        Create-SqlSecret
        Write-Host ""
        Create-ServiceBusSecret
    }
    4 {
        Write-Host "📋 Secrets existentes:" -ForegroundColor Cyan
        & microk8s kubectl get secrets | Select-String "azure"
        Write-Host ""
        Write-Host "📋 Detalhes dos secrets:" -ForegroundColor Cyan
        try {
            & microk8s kubectl describe secret azure-sql-secret
        } catch {
            Write-Host "azure-sql-secret não encontrado"
        }
        Write-Host ""
        try {
            & microk8s kubectl describe secret azure-servicebus-secret
        } catch {
            Write-Host "azure-servicebus-secret não encontrado"
        }
    }
    5 {
        Write-Host "👋 Saindo..." -ForegroundColor Green
        exit 0
    }
    default {
        Write-Host "❌ Opção inválida" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "🔍 Verificando secrets criados:" -ForegroundColor Cyan
& microk8s kubectl get secrets | Select-String "azure"

Write-Host ""
Write-Host "🚀 Para deployar a aplicação:" -ForegroundColor Magenta
Write-Host "   .\deploy-client-only.ps1"
Write-Host ""
Write-Host "📊 Para ver logs:" -ForegroundColor Magenta
Write-Host "   microk8s kubectl logs -l app=hazelcast-client -f"
