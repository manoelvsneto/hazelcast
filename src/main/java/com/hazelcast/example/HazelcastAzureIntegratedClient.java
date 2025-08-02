package com.hazelcast.example;

import com.hazelcast.client.HazelcastClient;
import com.hazelcast.client.config.ClientConfig;
import com.hazelcast.core.HazelcastInstance;
import com.hazelcast.map.IMap;
import com.hazelcast.example.database.SqlServerManager;
import com.hazelcast.example.messaging.ServiceBusManager;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.LocalDateTime;
import java.util.List;
import java.util.concurrent.TimeUnit;

/**
 * Hazelcast Client com integração Azure SQL Server e Service Bus
 */
public class HazelcastAzureIntegratedClient {
    
    private static final Logger logger = LoggerFactory.getLogger(HazelcastAzureIntegratedClient.class);
    
    private HazelcastInstance hazelcastClient;
    private SqlServerManager sqlServerManager;
    private ServiceBusManager serviceBusManager;
    
    public static void main(String[] args) {
        logger.info("Starting Hazelcast Azure Integrated Client...");
        
        HazelcastAzureIntegratedClient client = new HazelcastAzureIntegratedClient();
        
        try {
            client.initialize();
            client.runDemonstrations();
        } catch (Exception e) {
            logger.error("Error during client operations", e);
        } finally {
            client.shutdown();
        }
    }
    
    private void initialize() {
        // Configurar Hazelcast Client
        initializeHazelcast();
        
        // Configurar SQL Server
        initializeSqlServer();
        
        // Configurar Service Bus
        initializeServiceBus();
        
        logger.info("All Azure services initialized successfully");
    }
    
    private void initializeHazelcast() {
        try {
            // Verificar se deve usar modo embedded (standalone)
            boolean useEmbedded = Boolean.parseBoolean(getEnvVar("HAZELCAST_EMBEDDED_MODE", "true"));
            
            if (useEmbedded) {
                logger.info("Initializing Hazelcast in embedded mode (local instance)...");
                initializeEmbeddedHazelcast();
            } else {
                logger.info("Initializing Hazelcast in client mode (connecting to external server)...");
                initializeClientMode();
            }
            
            logger.info("Connected to Hazelcast cluster: {}", hazelcastClient.getName());
            
            // Enviar evento de conexão
            if (serviceBusManager != null) {
                serviceBusManager.sendSystemEvent("Hazelcast", "INFO", "Client connected to cluster");
            }
            
        } catch (Exception e) {
            logger.error("Failed to initialize Hazelcast, falling back to embedded mode", e);
            try {
                initializeEmbeddedHazelcast();
                logger.info("Successfully initialized Hazelcast in embedded fallback mode");
                
                // Enviar evento de fallback
                if (serviceBusManager != null) {
                    serviceBusManager.sendSystemEvent("Hazelcast", "WARN", "Fallback to embedded mode");
                }
            } catch (Exception fallbackException) {
                logger.error("Failed to initialize embedded Hazelcast", fallbackException);
                throw new RuntimeException("Unable to initialize Hazelcast in any mode", fallbackException);
            }
        }
    }
    
    private void initializeEmbeddedHazelcast() {
        logger.info("Creating embedded Hazelcast instance...");
        
        com.hazelcast.config.Config config = new com.hazelcast.config.Config();
        String clusterName = getEnvVar("HAZELCAST_CLUSTER_NAME", "dev");
        config.setClusterName(clusterName);
        
        // Configurações para ambiente embarcado
        config.getNetworkConfig().getJoin().getMulticastConfig().setEnabled(false);
        config.getNetworkConfig().getJoin().getTcpIpConfig().setEnabled(true);
        config.getNetworkConfig().getJoin().getTcpIpConfig().addMember("127.0.0.1");
        
        // Configurar para desenvolvimento
        config.setProperty("hazelcast.logging.type", "slf4j");
        config.setProperty("hazelcast.operation.call.timeout.millis", "30000");
        
        hazelcastClient = com.hazelcast.core.Hazelcast.newHazelcastInstance(config);
        logger.info("Embedded Hazelcast instance created successfully for cluster '{}'", clusterName);
    }
    
    private void initializeClientMode() {
        logger.info("Connecting to external Hazelcast server...");
        ClientConfig clientConfig = createClientConfig();
        this.hazelcastClient = HazelcastClient.newHazelcastClient(clientConfig);
        logger.info("Connected to external Hazelcast cluster successfully");
    }
    
    private void initializeSqlServer() {
        try {
            // Obter configurações do ambiente
            String connectionString = getEnvVar("SQL_SERVER_CONNECTION_STRING", 
                "jdbc:sqlserver://localhost:1433;databaseName=hazelcast_db");
            String username = getEnvVar("SQL_SERVER_USERNAME", "sa");
            String password = getEnvVar("SQL_SERVER_PASSWORD", "YourPassword123");
            
            this.sqlServerManager = new SqlServerManager(connectionString, username, password);
            
            // Testar conexão
            if (sqlServerManager.testConnection()) {
                logger.info("SQL Server connection established");
                sqlServerManager.createTablesIfNotExists();
            } else {
                logger.warn("SQL Server connection failed - continuing without database");
            }
            
        } catch (Exception e) {
            logger.error("Failed to initialize SQL Server connection", e);
        }
    }
    
    private void initializeServiceBus() {
        try {
            String connectionString = getEnvVar("SERVICE_BUS_CONNECTION_STRING", "");
            String queueName = getEnvVar("SERVICE_BUS_QUEUE_NAME", "hazelcast-events");
            
            if (!connectionString.isEmpty()) {
                this.serviceBusManager = new ServiceBusManager(connectionString, queueName);
                
                // Testar conexão
                if (serviceBusManager.testConnection()) {
                    logger.info("Service Bus connection established");
                } else {
                    logger.warn("Service Bus connection failed");
                }
            } else {
                logger.warn("Service Bus connection string not provided - continuing without messaging");
            }
            
        } catch (Exception e) {
            logger.error("Failed to initialize Service Bus connection", e);
        }
    }
    
    private void runDemonstrations() {
        logger.info("Running integrated demonstrations...");
        
        // Demonstração 1: Operações de usuário com persistência
        demonstrateUserOperationsWithPersistence();
        
        // Demonstração 2: Cache com eventos
        demonstrateCacheWithEvents();
        
        // Demonstração 3: Sincronização entre Hazelcast e SQL Server
        demonstrateDataSynchronization();
    }
    
    private void demonstrateUserOperationsWithPersistence() {
        logger.info("=== Demonstrating User Operations with Persistence ===" );
        
        IMap<String, UserData> userMap = hazelcastClient.getMap("users");
        
        // Criar usuários
        for (int i = 1; i <= 5; i++) {
            String userId = "user" + i;
            UserData user = new UserData(userId, "User " + i, "user" + i + "@example.com");
            
            // Armazenar no Hazelcast
            userMap.put(userId, user);
            
            // Persistir no SQL Server usando método helper UPSERT
            if (sqlServerManager != null) {
                String[] columns = {"user_id", "username", "email", "last_login"};
                Object[] values = {userId, user.getUsername(), user.getEmail(), LocalDateTime.now()};
                sqlServerManager.executeUpsert("users", "user_id", columns, values);
            }
            
            // Enviar evento
            if (serviceBusManager != null) {
                serviceBusManager.sendUserEvent(userId, user.getUsername(), "USER_CREATED", 
                    "User created and stored in cache and database");
            }
            
            logger.info("Created user: {}", user.getUsername());
        }
        
        logger.info("Total users in Hazelcast cache: {}", userMap.size());
        
        // Verificar dados no SQL Server
        if (sqlServerManager != null) {
            List<String> dbUsers = sqlServerManager.executeQuery("SELECT user_id, username, email FROM users");
            logger.info("Users in SQL Server: {}", dbUsers.size());
            dbUsers.forEach(user -> logger.info("DB User: {}", user));
        }
    }
    
    private void demonstrateCacheWithEvents() {
        logger.info("=== Demonstrating Cache Operations with Events ===");
        
        IMap<String, String> productCache = hazelcastClient.getMap("product-cache");
        
        // Simular operações de cache com eventos
        String[] products = {"laptop", "mouse", "keyboard", "monitor", "headset"};
        
        for (String product : products) {
            // Cache miss - buscar "dados externos"
            String productData = "Product data for " + product + " - " + LocalDateTime.now();
            productCache.put(product, productData, 30, TimeUnit.SECONDS); // TTL de 30 segundos
            
            // Registrar evento no banco
            if (sqlServerManager != null) {
                sqlServerManager.executeUpdate(
                    "INSERT INTO user_events (user_id, event_type, event_data) VALUES (?, ?, ?)",
                    "system", "CACHE_MISS", "Product: " + product
                );
            }
            
            // Enviar evento para Service Bus
            if (serviceBusManager != null) {
                serviceBusManager.sendSystemEvent("ProductCache", "INFO", 
                    "Cache miss for product: " + product);
            }
            
            logger.info("Cached product: {}", product);
        }
        
        // Demonstrar cache hit
        for (String product : products) {
            String cachedData = productCache.get(product);
            if (cachedData != null) {
                logger.info("Cache HIT for {}: {}", product, cachedData.substring(0, 30) + "...");
                
                if (serviceBusManager != null) {
                    serviceBusManager.sendSystemEvent("ProductCache", "INFO", 
                        "Cache hit for product: " + product);
                }
            } else {
                logger.info("Cache MISS for {} (expired)", product);
            }
        }
    }
    
    private void demonstrateDataSynchronization() {
        logger.info("=== Demonstrating Data Synchronization ===");
        
        IMap<String, String> syncMap = hazelcastClient.getMap("sync-data");
        
        // Adicionar listener para sincronizar com banco
        syncMap.addEntryListener(new MapEntryListener(sqlServerManager, serviceBusManager), true);
        
        // Realizar operações que irão disparar eventos
        for (int i = 1; i <= 3; i++) {
            String key = "sync-key-" + i;
            String value = "Synchronized data " + i + " at " + LocalDateTime.now();
            
            syncMap.put(key, value);
            logger.info("Added synchronized data: {}", key);
            
            // Aguardar um pouco para ver os eventos
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }
        
        // Remover algumas entradas
        syncMap.remove("sync-key-2");
        logger.info("Removed sync-key-2");
    }
    
    private ClientConfig createClientConfig() {
        ClientConfig config = new ClientConfig();
        
        // Configurar nome do cluster
        String clusterName = getEnvVar("HAZELCAST_CLUSTER_NAME", "dev");
        config.setClusterName(clusterName);
        
        // Configurar endereços dos servidores
        String serverAddress = getEnvVar("HAZELCAST_SERVER_ADDRESS", "127.0.0.1:5701");
        config.getNetworkConfig().addAddress(serverAddress);
        
        // Configurações de conexão
        config.getNetworkConfig().setRedoOperation(true);
        config.getConnectionStrategyConfig().setAsyncStart(false);
        
        // Configurar retry
        config.getConnectionStrategyConfig().getConnectionRetryConfig()
            .setClusterConnectTimeoutMillis(30000)
            .setMaxBackoffMillis(5000)
            .setInitialBackoffMillis(1000)
            .setMultiplier(1.5);
        
        logger.info("Hazelcast client configured for cluster '{}' at '{}'", clusterName, serverAddress);
        return config;
    }
    
    private String getEnvVar(String name, String defaultValue) {
        String value = System.getenv(name);
        return value != null ? value : defaultValue;
    }
    
    private void shutdown() {
        logger.info("Shutting down integrated client...");
        
        if (hazelcastClient != null) {
            hazelcastClient.shutdown();
            logger.info("Hazelcast client disconnected");
        }
        
        if (sqlServerManager != null) {
            sqlServerManager.shutdown();
        }
        
        if (serviceBusManager != null) {
            serviceBusManager.shutdown();
        }
        
        logger.info("All services shut down successfully");
    }
    
    // Classe para dados do usuário
    public static class UserData {
        private String userId;
        private String username;
        private String email;
        private LocalDateTime createdAt;
        
        public UserData() {}
        
        public UserData(String userId, String username, String email) {
            this.userId = userId;
            this.username = username;
            this.email = email;
            this.createdAt = LocalDateTime.now();
        }
        
        // Getters e Setters
        public String getUserId() { return userId; }
        public void setUserId(String userId) { this.userId = userId; }
        
        public String getUsername() { return username; }
        public void setUsername(String username) { this.username = username; }
        
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        
        public LocalDateTime getCreatedAt() { return createdAt; }
        public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    }
}
