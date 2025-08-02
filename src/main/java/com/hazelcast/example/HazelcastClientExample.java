package com.hazelcast.example;

import com.hazelcast.client.HazelcastClient;
import com.hazelcast.client.config.ClientConfig;
import com.hazelcast.core.HazelcastInstance;
import com.hazelcast.map.IMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.LocalDateTime;
import java.util.Set;
import java.util.concurrent.TimeUnit;

/**
 * Hazelcast Client Example
 * 
 * This class demonstrates how to connect to a Hazelcast cluster as a client
 * and perform distributed operations on maps and other data structures.
 */
public class HazelcastClientExample {
    
    private static final Logger logger = LoggerFactory.getLogger(HazelcastClientExample.class);
    
    public static void main(String[] args) {
        logger.info("Starting Hazelcast Client Example...");
        
        // Create client configuration
        ClientConfig clientConfig = createClientConfig();
        
        // Connect to Hazelcast cluster
        HazelcastInstance client = HazelcastClient.newHazelcastClient(clientConfig);
        
        try {
            logger.info("Connected to Hazelcast cluster: {}", client.getName());
            
            // Demonstrate distributed map operations
            demonstrateDistributedMap(client);
            
            // Demonstrate user session management
            demonstrateUserSessions(client);
            
            // Demonstrate cache operations
            demonstrateCacheOperations(client);
            
        } catch (Exception e) {
            logger.error("Error during client operations", e);
        } finally {
            // Shutdown client
            client.shutdown();
            logger.info("Hazelcast client disconnected");
        }
    }
    
    /**
     * Creates client configuration for connecting to Hazelcast cluster
     * 
     * @return configured ClientConfig instance
     */
    private static ClientConfig createClientConfig() {
        ClientConfig clientConfig = new ClientConfig();
        
        // Set cluster name (must match server configuration)
        clientConfig.setClusterName("hazelcast-example-cluster");
        
        // Configure connection addresses
        clientConfig.getNetworkConfig().addAddress("127.0.0.1:5701");
        
        // Configure connection retry
        clientConfig.getConnectionStrategyConfig().getConnectionRetryConfig()
            .setInitialBackoffMillis(1000)
            .setMaxBackoffMillis(30000)
            .setMultiplier(2.0)
            .setClusterConnectTimeoutMillis(20000);
        
        return clientConfig;
    }
    
    /**
     * Demonstrates basic distributed map operations
     * 
     * @param client the Hazelcast client instance
     */
    private static void demonstrateDistributedMap(HazelcastInstance client) {
        logger.info("=== Distributed Map Operations ===");
        
        IMap<String, String> map = client.getMap("example-map");
        
        // Put operations
        map.put("key1", "Hello");
        map.put("key2", "Hazelcast");
        map.put("key3", "5.5");
        
        logger.info("Added {} entries to distributed map", map.size());
        
        // Get operations
        String value1 = map.get("key1");
        String value2 = map.get("key2");
        logger.info("Retrieved values: {} {}", value1, value2);
        
        // Check if key exists
        boolean containsKey = map.containsKey("key3");
        logger.info("Map contains key3: {}", containsKey);
        
        // Get all keys
        Set<String> keys = map.keySet();
        logger.info("All keys in map: {}", keys);
        
        // Conditional operations
        String replaced = map.replace("key1", "Hi");
        logger.info("Replaced value: {}", replaced);
        
        // Time-to-live operations
        map.put("temp-key", "temporary value", 10, TimeUnit.SECONDS);
        logger.info("Added temporary entry with 10 seconds TTL");
    }
    
    /**
     * Demonstrates user session management using distributed maps
     * 
     * @param client the Hazelcast client instance
     */
    private static void demonstrateUserSessions(HazelcastInstance client) {
        logger.info("=== User Session Management ===");
        
        IMap<String, UserSession> userSessions = client.getMap("user-sessions");
        
        // Create and store user sessions
        UserSession session1 = new UserSession("user123", "John Doe", LocalDateTime.now());
        UserSession session2 = new UserSession("user456", "Jane Smith", LocalDateTime.now());
        
        userSessions.put(session1.getUserId(), session1);
        userSessions.put(session2.getUserId(), session2);
        
        logger.info("Stored {} user sessions", userSessions.size());
        
        // Retrieve user session
        UserSession retrievedSession = userSessions.get("user123");
        if (retrievedSession != null) {
            logger.info("Retrieved session for user: {}", retrievedSession.getUsername());
        }
        
        // Check active sessions
        logger.info("Total active sessions: {}", userSessions.size());
    }
    
    /**
     * Demonstrates cache operations with expiration
     * 
     * @param client the Hazelcast client instance
     */
    private static void demonstrateCacheOperations(HazelcastInstance client) {
        logger.info("=== Cache Operations ===");
        
        IMap<String, Object> cache = client.getMap("cache-data");
        
        // Cache database query results
        cache.put("user:123:profile", new UserProfile("John Doe", "john@example.com"));
        cache.put("product:456:details", new ProductInfo("Laptop", 999.99));
        
        // Cache with custom TTL
        cache.put("api:weather:current", "Sunny, 25°C", 5, TimeUnit.MINUTES);
        
        logger.info("Cached {} items", cache.size());
        
        // Retrieve from cache
        UserProfile userProfile = (UserProfile) cache.get("user:123:profile");
        if (userProfile != null) {
            logger.info("Retrieved cached user profile: {}", userProfile.getName());
        }
        
        ProductInfo productInfo = (ProductInfo) cache.get("product:456:details");
        if (productInfo != null) {
            logger.info("Retrieved cached product: {} - ${}", 
                productInfo.getName(), productInfo.getPrice());
        }
    }
    
    // Helper classes for examples
    public static class UserSession {
        private String userId;
        private String username;
        private LocalDateTime loginTime;
        
        public UserSession(String userId, String username, LocalDateTime loginTime) {
            this.userId = userId;
            this.username = username;
            this.loginTime = loginTime;
        }
        
        // Getters
        public String getUserId() { return userId; }
        public String getUsername() { return username; }
        public LocalDateTime getLoginTime() { return loginTime; }
    }
    
    public static class UserProfile {
        private String name;
        private String email;
        
        public UserProfile(String name, String email) {
            this.name = name;
            this.email = email;
        }
        
        // Getters
        public String getName() { return name; }
        public String getEmail() { return email; }
    }
    
    public static class ProductInfo {
        private String name;
        private double price;
        
        public ProductInfo(String name, double price) {
            this.name = name;
            this.price = price;
        }
        
        // Getters
        public String getName() { return name; }
        public double getPrice() { return price; }
    }
}
