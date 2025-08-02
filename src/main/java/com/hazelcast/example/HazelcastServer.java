package com.hazelcast.example;

import com.hazelcast.config.Config;
import com.hazelcast.config.MapConfig;
import com.hazelcast.config.NetworkConfig;
import com.hazelcast.core.Hazelcast;
import com.hazelcast.core.HazelcastInstance;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Hazelcast Server Example
 * 
 * This class demonstrates how to start a Hazelcast member (server) instance
 * with custom configuration for distributed data structures.
 */
public class HazelcastServer {
    
    private static final Logger logger = LoggerFactory.getLogger(HazelcastServer.class);
    
    public static void main(String[] args) {
        logger.info("Starting Hazelcast Server...");
        
        // Create and configure Hazelcast instance
        Config config = createConfig();
        HazelcastInstance hazelcastInstance = Hazelcast.newHazelcastInstance(config);
        
        logger.info("Hazelcast Server started successfully!");
        logger.info("Cluster Name: {}", config.getClusterName());
        logger.info("Instance Name: {}", hazelcastInstance.getName());
        logger.info("Cluster Size: {}", hazelcastInstance.getCluster().getMembers().size());
        
        // Add shutdown hook
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            logger.info("Shutting down Hazelcast Server...");
            hazelcastInstance.shutdown();
        }));
        
        // Keep the server running
        try {
            Thread.currentThread().join();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            logger.warn("Server interrupted", e);
        }
    }
    
    /**
     * Creates and configures Hazelcast Config
     * 
     * @return configured Config instance
     */
    private static Config createConfig() {
        Config config = new Config();
        
        // Set cluster name
        config.setClusterName("hazelcast-example-cluster");
        
        // Configure instance name
        config.setInstanceName("hazelcast-server-1");
        
        // Network configuration
        NetworkConfig networkConfig = config.getNetworkConfig();
        networkConfig.setPort(5701);
        networkConfig.setPortAutoIncrement(true);
        
        // Configure distributed maps
        configureDistributedMaps(config);
        
        // Enable metrics and management center (if needed)
        config.getMetricsConfig().setEnabled(true);
        
        return config;
    }
    
    /**
     * Configures distributed maps with specific settings
     * 
     * @param config the Hazelcast config to modify
     */
    private static void configureDistributedMaps(Config config) {
        // Example Map: User Sessions
        MapConfig userSessionsConfig = new MapConfig();
        userSessionsConfig.setName("user-sessions");
        userSessionsConfig.setBackupCount(1);
        userSessionsConfig.setAsyncBackupCount(1);
        userSessionsConfig.setTimeToLiveSeconds(3600); // 1 hour TTL
        config.addMapConfig(userSessionsConfig);
        
        // Example Map: Cache Data
        MapConfig cacheConfig = new MapConfig();
        cacheConfig.setName("cache-data");
        cacheConfig.setBackupCount(2);
        cacheConfig.setMaxIdleSeconds(1800); // 30 minutes idle timeout
        config.addMapConfig(cacheConfig);
        
        logger.info("Configured distributed maps: user-sessions, cache-data");
    }
}
