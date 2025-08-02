#!/bin/bash

# 🗄️ Setup SQL Server Database for Hazelcast
# Executa o script de criação das tabelas

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Parâmetros padrão
SERVER_NAME="${1:-localhost}"
DATABASE_NAME="${2:-hazelcast_db}"
USERNAME="${3:-sa}"
PASSWORD="${4:-}"

echo -e "${GREEN}🗄️  Setup SQL Server Database for Hazelcast${NC}"
echo -e "${GREEN}=============================================${NC}"

# Verificar se o arquivo SQL existe
SQL_FILE="$(dirname "$0")/sql-server-schema.sql"
if [ ! -f "$SQL_FILE" ]; then
    echo -e "${RED}❌ Arquivo SQL não encontrado: $SQL_FILE${NC}"
    exit 1
fi

# Solicitar senha se não fornecida
if [ -z "$PASSWORD" ]; then
    echo -e "${YELLOW}🔐 Digite a senha do SQL Server:${NC}"
    read -s PASSWORD
fi

echo -e "${CYAN}📊 Configuração:${NC}"
echo -e "${WHITE}   Server: $SERVER_NAME${NC}"
echo -e "${WHITE}   Database: $DATABASE_NAME${NC}"
echo -e "${WHITE}   Username: $USERNAME${NC}"
echo ""

# Verificar se sqlcmd está instalado
if ! command -v sqlcmd &> /dev/null; then
    echo -e "${RED}❌ sqlcmd não encontrado!${NC}"
    echo -e "${YELLOW}💡 Instale o SQL Server command line tools:${NC}"
    echo -e "${WHITE}   Ubuntu/Debian: apt-get install mssql-tools${NC}"
    echo -e "${WHITE}   RHEL/CentOS: yum install mssql-tools${NC}"
    echo -e "${WHITE}   macOS: brew install mssql-tools${NC}"
    echo -e "${WHITE}   Ou baixe de: https://docs.microsoft.com/en-us/sql/tools/sqlcmd-utility${NC}"
    exit 1
fi

echo -e "${YELLOW}🔗 Testando conexão com SQL Server...${NC}"

# Testar conexão
TEST_QUERY="SELECT 1 as test"
if sqlcmd -S "$SERVER_NAME" -d "$DATABASE_NAME" -U "$USERNAME" -P "$PASSWORD" -Q "$TEST_QUERY" -h -1 -W > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Conexão com SQL Server estabelecida!${NC}"
else
    echo -e "${RED}❌ Erro na conexão com SQL Server${NC}"
    echo -e "${YELLOW}💡 Verifique:${NC}"
    echo -e "${WHITE}   - Se o SQL Server está rodando${NC}"
    echo -e "${WHITE}   - Se as credenciais estão corretas${NC}"
    echo -e "${WHITE}   - Se o database '$DATABASE_NAME' existe${NC}"
    echo -e "${WHITE}   - Se a conectividade de rede está OK${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}🚀 Executando script de criação do schema...${NC}"

# Executar script SQL
if sqlcmd -S "$SERVER_NAME" -d "$DATABASE_NAME" -U "$USERNAME" -P "$PASSWORD" -i "$SQL_FILE"; then
    echo -e "${GREEN}✅ Script executado com sucesso!${NC}"
else
    echo -e "${RED}❌ Erro ao executar script SQL${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}🔍 Verificando tabelas criadas...${NC}"

# Verificar tabelas
TABLES_QUERY="
SELECT 
    TABLE_NAME as Tabela,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = t.TABLE_NAME) as Colunas
FROM INFORMATION_SCHEMA.TABLES t
WHERE TABLE_NAME IN ('users', 'user_events')
    AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME
"

echo -e "${GREEN}📊 Tabelas encontradas:${NC}"
sqlcmd -S "$SERVER_NAME" -d "$DATABASE_NAME" -U "$USERNAME" -P "$PASSWORD" -Q "$TABLES_QUERY" -h -1

echo ""
echo -e "${YELLOW}🔍 Verificando dados inseridos...${NC}"

# Verificar dados
DATA_QUERY="
SELECT 'users' as tabela, COUNT(*) as total FROM users
UNION ALL
SELECT 'user_events' as tabela, COUNT(*) as total FROM user_events
"

echo -e "${GREEN}📈 Contagem de registros:${NC}"
sqlcmd -S "$SERVER_NAME" -d "$DATABASE_NAME" -U "$USERNAME" -P "$PASSWORD" -Q "$DATA_QUERY" -h -1

echo ""
echo -e "${GREEN}🎉 Setup do banco de dados concluído com sucesso!${NC}"
echo -e "${GREEN}✅ Tabelas criadas: users, user_events${NC}"
echo -e "${GREEN}✅ Índices criados para performance${NC}"
echo -e "${GREEN}✅ Dados de exemplo inseridos${NC}"
echo -e "${GREEN}🚀 Pronto para usar com Hazelcast!${NC}"

echo ""
echo -e "${CYAN}📝 Próximos passos:${NC}"
echo -e "${WHITE}   1. Configurar connection string no Azure DevOps pipeline${NC}"
echo -e "${WHITE}   2. Atualizar variáveis SQL_SERVER_* no pipeline${NC}"
echo -e "${WHITE}   3. Fazer deploy da aplicação Hazelcast${NC}"
echo -e "${WHITE}   4. Verificar logs da aplicação para confirmar conexão${NC}"

echo ""
echo -e "${CYAN}🔧 Exemplo de uso:${NC}"
echo -e "${WHITE}   ./setup-sql-server.sh localhost hazelcast_db sa${NC}"
echo -e "${WHITE}   ./setup-sql-server.sh servidor.database.windows.net mydb admin${NC}"
