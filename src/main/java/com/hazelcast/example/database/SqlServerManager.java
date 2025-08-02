package com.hazelcast.example.database;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * Gerenciador de conexão com Azure SQL Server
 */
public class SqlServerManager {
    private static final Logger logger = LoggerFactory.getLogger(SqlServerManager.class);
    
    private final HikariDataSource dataSource;
    
    public SqlServerManager(String connectionString, String username, String password) {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl(connectionString);
        config.setUsername(username);
        config.setPassword(password);
        config.setDriverClassName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        
        // Configurações de pool
        config.setMaximumPoolSize(10);
        config.setMinimumIdle(2);
        config.setConnectionTimeout(30000);
        config.setIdleTimeout(600000);
        config.setMaxLifetime(1800000);
        config.setLeakDetectionThreshold(60000);
        
        // Configurações específicas do SQL Server
        config.addDataSourceProperty("trustServerCertificate", "true");
        config.addDataSourceProperty("encrypt", "true");
        config.addDataSourceProperty("loginTimeout", "30");
        
        this.dataSource = new HikariDataSource(config);
        
        logger.info("SQL Server connection pool initialized");
    }
    
    /**
     * Testa a conexão com o banco
     */
    public boolean testConnection() {
        try (Connection conn = dataSource.getConnection()) {
            return conn.isValid(5);
        } catch (SQLException e) {
            logger.error("Failed to test SQL Server connection", e);
            return false;
        }
    }
    
    /**
     * Executa uma query SELECT
     */
    public List<String> executeQuery(String sql, Object... parameters) {
        List<String> results = new ArrayList<>();
        
        try (Connection conn = dataSource.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            // Definir parâmetros
            for (int i = 0; i < parameters.length; i++) {
                stmt.setObject(i + 1, parameters[i]);
            }
            
            try (ResultSet rs = stmt.executeQuery()) {
                int columnCount = rs.getMetaData().getColumnCount();
                
                while (rs.next()) {
                    StringBuilder row = new StringBuilder();
                    for (int i = 1; i <= columnCount; i++) {
                        if (i > 1) row.append(", ");
                        row.append(rs.getString(i));
                    }
                    results.add(row.toString());
                }
            }
            
        } catch (SQLException e) {
            logger.error("Failed to execute query: " + sql, e);
        }
        
        return results;
    }
    
    /**
     * Executa um comando INSERT/UPDATE/DELETE
     */
    public int executeUpdate(String sql, Object... parameters) {
        try (Connection conn = dataSource.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            // Definir parâmetros
            for (int i = 0; i < parameters.length; i++) {
                stmt.setObject(i + 1, parameters[i]);
            }
            
            int rowsAffected = stmt.executeUpdate();
            logger.debug("Query executed successfully, {} rows affected", rowsAffected);
            return rowsAffected;
            
        } catch (SQLException e) {
            logger.error("Failed to execute update: " + sql, e);
            return -1;
        }
    }
    
    /**
     * Cria as tabelas de exemplo se não existirem
     */
    public void createTablesIfNotExists() {
        String createUsersTable = "IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='users' AND xtype='U') " +
            "CREATE TABLE users (" +
            "    id BIGINT IDENTITY(1,1) PRIMARY KEY," +
            "    user_id NVARCHAR(100) NOT NULL UNIQUE," +
            "    username NVARCHAR(255) NOT NULL," +
            "    email NVARCHAR(255)," +
            "    created_at DATETIME2 DEFAULT GETDATE()," +
            "    last_login DATETIME2" +
            ")";
        
        String createEventsTable = "IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='user_events' AND xtype='U') " +
            "CREATE TABLE user_events (" +
            "    id BIGINT IDENTITY(1,1) PRIMARY KEY," +
            "    user_id NVARCHAR(100) NOT NULL," +
            "    event_type NVARCHAR(100) NOT NULL," +
            "    event_data NVARCHAR(MAX)," +
            "    created_at DATETIME2 DEFAULT GETDATE()" +
            ")";
        
        executeUpdate(createUsersTable);
        executeUpdate(createEventsTable);
        
        logger.info("Database tables created/verified");
    }
    
    /**
     * Executa uma operação UPSERT (INSERT ou UPDATE) usando MERGE do SQL Server
     * @param tableName Nome da tabela
     * @param keyColumn Coluna que será usada como chave para verificar se o registro existe
     * @param columns Array com os nomes das colunas (incluindo a chave)
     * @param values Array com os valores correspondentes às colunas
     * @return Número de linhas afetadas
     */
    public int executeUpsert(String tableName, String keyColumn, String[] columns, Object[] values) {
        if (columns.length != values.length) {
            throw new IllegalArgumentException("Number of columns must match number of values");
        }
        
        // Construir a query MERGE dinamicamente
        StringBuilder mergeQuery = new StringBuilder();
        mergeQuery.append("MERGE ").append(tableName).append(" AS target ");
        mergeQuery.append("USING (SELECT ");
        
        // Adicionar SELECTs para os valores
        for (int i = 0; i < columns.length; i++) {
            if (i > 0) mergeQuery.append(", ");
            mergeQuery.append("? AS ").append(columns[i]);
        }
        
        mergeQuery.append(") AS source ");
        mergeQuery.append("ON target.").append(keyColumn).append(" = source.").append(keyColumn).append(" ");
        
        // WHEN MATCHED (UPDATE)
        mergeQuery.append("WHEN MATCHED THEN UPDATE SET ");
        boolean first = true;
        for (String column : columns) {
            if (!column.equals(keyColumn)) {  // Não atualizar a chave
                if (!first) mergeQuery.append(", ");
                mergeQuery.append(column).append(" = source.").append(column);
                first = false;
            }
        }
        
        // WHEN NOT MATCHED (INSERT)
        mergeQuery.append(" WHEN NOT MATCHED THEN INSERT (");
        for (int i = 0; i < columns.length; i++) {
            if (i > 0) mergeQuery.append(", ");
            mergeQuery.append(columns[i]);
        }
        mergeQuery.append(") VALUES (");
        for (int i = 0; i < columns.length; i++) {
            if (i > 0) mergeQuery.append(", ");
            mergeQuery.append("source.").append(columns[i]);
        }
        mergeQuery.append(");");
        
        return executeUpdate(mergeQuery.toString(), values);
    }
    
    /**
     * Fecha o pool de conexões
     */
    public void shutdown() {
        if (dataSource != null && !dataSource.isClosed()) {
            dataSource.close();
            logger.info("SQL Server connection pool closed");
        }
    }
    
    public DataSource getDataSource() {
        return dataSource;
    }
}
