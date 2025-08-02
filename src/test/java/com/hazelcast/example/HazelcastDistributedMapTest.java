package com.hazelcast.example;

import com.hazelcast.config.Config;
import com.hazelcast.core.Hazelcast;
import com.hazelcast.core.HazelcastInstance;
import com.hazelcast.map.IMap;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for Hazelcast distributed map operations
 */
public class HazelcastDistributedMapTest {
    
    private HazelcastInstance hazelcastInstance;
    
    @BeforeEach
    void setUp() {
        // Create test configuration
        Config config = new Config();
        config.setClusterName("test-cluster");
        config.setInstanceName("test-instance");
        
        // Create Hazelcast instance for testing
        hazelcastInstance = Hazelcast.newHazelcastInstance(config);
    }
    
    @AfterEach
    void tearDown() {
        // Shutdown Hazelcast instance after each test
        if (hazelcastInstance != null) {
            hazelcastInstance.shutdown();
        }
    }
    
    @Test
    void testBasicMapOperations() {
        // Get distributed map
        IMap<String, String> map = hazelcastInstance.getMap("test-map");
        
        // Test put operation
        map.put("key1", "value1");
        assertEquals("value1", map.get("key1"));
        
        // Test map size
        assertEquals(1, map.size());
        
        // Test containsKey
        assertTrue(map.containsKey("key1"));
        assertFalse(map.containsKey("nonexistent"));
        
        // Test remove operation
        String removed = map.remove("key1");
        assertEquals("value1", removed);
        assertEquals(0, map.size());
    }
    
    @Test
    void testMapWithObjects() {
        IMap<String, HazelcastClientExample.UserSession> sessionMap = hazelcastInstance.getMap("session-test");
        
        // Create test user session
        HazelcastClientExample.UserSession session = 
            new HazelcastClientExample.UserSession("user123", "John Doe", 
                java.time.LocalDateTime.now());
        
        // Store in map
        sessionMap.put(session.getUserId(), session);
        
        // Retrieve and verify
        HazelcastClientExample.UserSession retrieved = sessionMap.get("user123");
        assertNotNull(retrieved);
        assertEquals("John Doe", retrieved.getUsername());
        assertEquals("user123", retrieved.getUserId());
    }
    
    @Test
    void testConditionalOperations() {
        IMap<String, String> map = hazelcastInstance.getMap("conditional-test");
        
        // Test putIfAbsent
        String result1 = map.putIfAbsent("key1", "value1");
        assertNull(result1); // Should return null as key didn't exist
        
        String result2 = map.putIfAbsent("key1", "value2");
        assertEquals("value1", result2); // Should return existing value
        
        // Test replace
        String replaced = map.replace("key1", "newValue");
        assertEquals("value1", replaced);
        assertEquals("newValue", map.get("key1"));
        
        // Test conditional replace
        boolean success = map.replace("key1", "newValue", "finalValue");
        assertTrue(success);
        assertEquals("finalValue", map.get("key1"));
    }
    
    @Test
    void testMapStatistics() {
        IMap<String, String> map = hazelcastInstance.getMap("stats-test");
        
        // Add some data
        for (int i = 0; i < 10; i++) {
            map.put("key" + i, "value" + i);
        }
        
        // Verify size
        assertEquals(10, map.size());
        
        // Test isEmpty
        assertFalse(map.isEmpty());
        
        // Clear and test
        map.clear();
        assertTrue(map.isEmpty());
        assertEquals(0, map.size());
    }
}
