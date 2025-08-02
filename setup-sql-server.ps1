# 🗄️ Setup SQL Server Database for Hazelcast
# Executa o script de criação das tabelas

param(
    [Parameter(Mandatory=$false)]
    [string]$ServerName = "localhost",
    
    [Parameter(Mandatory=$false)]
    [string]$DatabaseName = "hazelcast_db",
    
    [Parameter(Mandatory=$false)]
    [string]$Username = "sa",
    
    [Parameter(Mandatory=$false)]
    [string]$Password = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$UseWindowsAuth = $false
)

Write-Host "🗄️  Setup SQL Server Database for Hazelcast" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Verificar se o arquivo SQL existe
$sqlFile = Join-Path $PSScriptRoot "sql-server-schema.sql"
if (-not (Test-Path $sqlFile)) {
    Write-Host "❌ Arquivo SQL não encontrado: $sqlFile" -ForegroundColor Red
    exit 1
}

# Construir connection string
if ($UseWindowsAuth) {
    $connectionString = "Server=$ServerName;Database=$DatabaseName;Integrated Security=True;TrustServerCertificate=True;"
    Write-Host "🔐 Usando autenticação Windows" -ForegroundColor Yellow
} else {
    if ([string]::IsNullOrEmpty($Password)) {
        $securePassword = Read-Host "Digite a senha do SQL Server" -AsSecureString
        $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
    }
    $connectionString = "Server=$ServerName;Database=$DatabaseName;User Id=$Username;Password=$Password;TrustServerCertificate=True;"
    Write-Host "🔐 Usando autenticação SQL Server" -ForegroundColor Yellow
}

Write-Host "📊 Configuração:" -ForegroundColor Cyan
Write-Host "   Server: $ServerName" -ForegroundColor White
Write-Host "   Database: $DatabaseName" -ForegroundColor White
Write-Host "   Username: $Username" -ForegroundColor White
Write-Host ""

try {
    Write-Host "🔗 Testando conexão com SQL Server..." -ForegroundColor Yellow
    
    # Verificar se SqlServer module está disponível
    if (-not (Get-Module -ListAvailable -Name SqlServer)) {
        Write-Host "⚠️  Módulo SqlServer não encontrado. Tentando instalar..." -ForegroundColor Yellow
        
        try {
            Install-Module -Name SqlServer -Scope CurrentUser -Force -AllowClobber
            Write-Host "✅ Módulo SqlServer instalado com sucesso!" -ForegroundColor Green
        } catch {
            Write-Host "❌ Erro ao instalar módulo SqlServer: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "💡 Instale manualmente: Install-Module -Name SqlServer" -ForegroundColor Yellow
            exit 1
        }
    }
    
    Import-Module SqlServer -Force
    
    # Testar conexão
    $testQuery = "SELECT 1 as test"
    $testResult = Invoke-Sqlcmd -ConnectionString $connectionString -Query $testQuery -QueryTimeout 30
    
    if ($testResult.test -eq 1) {
        Write-Host "✅ Conexão com SQL Server estabelecida!" -ForegroundColor Green
    } else {
        Write-Host "❌ Erro na conexão com SQL Server" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "🚀 Executando script de criação do schema..." -ForegroundColor Yellow
    
    # Executar script SQL
    $result = Invoke-Sqlcmd -ConnectionString $connectionString -InputFile $sqlFile -QueryTimeout 120 -Verbose
    
    Write-Host "✅ Script executado com sucesso!" -ForegroundColor Green
    Write-Host ""
    
    # Verificar tabelas criadas
    Write-Host "🔍 Verificando tabelas criadas..." -ForegroundColor Yellow
    $tablesQuery = @"
SELECT 
    TABLE_NAME as Tabela,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = t.TABLE_NAME) as Colunas
FROM INFORMATION_SCHEMA.TABLES t
WHERE TABLE_NAME IN ('users', 'user_events')
    AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME
"@
    
    $tables = Invoke-Sqlcmd -ConnectionString $connectionString -Query $tablesQuery
    
    if ($tables.Count -gt 0) {
        Write-Host "📊 Tabelas encontradas:" -ForegroundColor Green
        $tables | Format-Table -AutoSize
    } else {
        Write-Host "⚠️  Nenhuma tabela encontrada!" -ForegroundColor Yellow
    }
    
    # Verificar dados de exemplo
    Write-Host "🔍 Verificando dados inseridos..." -ForegroundColor Yellow
    $dataQuery = @"
SELECT 'users' as tabela, COUNT(*) as total FROM users
UNION ALL
SELECT 'user_events' as tabela, COUNT(*) as total FROM user_events
"@
    
    $dataCount = Invoke-Sqlcmd -ConnectionString $connectionString -Query $dataQuery
    
    Write-Host "📈 Contagem de registros:" -ForegroundColor Green
    $dataCount | Format-Table -AutoSize
    
    Write-Host ""
    Write-Host "🎉 Setup do banco de dados concluído com sucesso!" -ForegroundColor Green
    Write-Host "✅ Tabelas criadas: users, user_events" -ForegroundColor Green
    Write-Host "✅ Índices criados para performance" -ForegroundColor Green
    Write-Host "✅ Dados de exemplo inseridos" -ForegroundColor Green
    Write-Host "🚀 Pronto para usar com Hazelcast!" -ForegroundColor Green
    
} catch {
    Write-Host ""
    Write-Host "❌ Erro durante execução:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Dicas para resolução:" -ForegroundColor Yellow
    Write-Host "   1. Verificar se SQL Server está rodando" -ForegroundColor White
    Write-Host "   2. Verificar credenciais de acesso" -ForegroundColor White
    Write-Host "   3. Verificar se database '$DatabaseName' existe" -ForegroundColor White
    Write-Host "   4. Verificar conectividade de rede (se servidor remoto)" -ForegroundColor White
    Write-Host ""
    Write-Host "🔧 Exemplo de uso:" -ForegroundColor Cyan
    Write-Host "   .\setup-sql-server.ps1 -ServerName 'localhost' -DatabaseName 'hazelcast_db' -Username 'sa'" -ForegroundColor White
    Write-Host "   .\setup-sql-server.ps1 -ServerName 'servidor.database.windows.net' -UseWindowsAuth" -ForegroundColor White
    
    exit 1
}

Write-Host ""
Write-Host "📝 Próximos passos:" -ForegroundColor Cyan
Write-Host "   1. Configurar connection string no Azure DevOps pipeline" -ForegroundColor White
Write-Host "   2. Atualizar variáveis SQL_SERVER_* no pipeline" -ForegroundColor White
Write-Host "   3. Fazer deploy da aplicação Hazelcast" -ForegroundColor White
Write-Host "   4. Verificar logs da aplicação para confirmar conexão" -ForegroundColor White
