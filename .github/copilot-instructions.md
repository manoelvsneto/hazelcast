# Copilot Instructions for Hazelcast 5.5 Project

<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

## Project Overview
This is a Hazelcast 5.5 example project demonstrating distributed data structures and in-memory computing capabilities.

## Key Technologies
- **Hazelcast 5.5**: In-Memory Data Grid (IMDG) and distributed computing platform
- **Java 11+**: Programming language
- **Maven**: Build and dependency management
- **JUnit 5**: Testing framework
- **SLF4J + Logback**: Logging framework

## Code Style Guidelines

### General Java Conventions
- Use Java 11+ features appropriately
- Follow standard Java naming conventions
- Add comprehensive JavaDoc for public methods
- Use meaningful variable and method names
- Prefer composition over inheritance

### Hazelcast-Specific Guidelines
- Always configure cluster names to avoid accidental joining
- Use try-with-resources or proper shutdown for Hazelcast instances
- Configure backup counts appropriately for data safety
- Use appropriate in-memory formats (BINARY, OBJECT) based on use case
- Consider TTL and eviction policies for memory management

### Configuration Best Practices
- Prefer programmatic configuration over XML when possible
- Use meaningful names for distributed data structures
- Configure appropriate backup counts (1-2 for most use cases)
- Set reasonable TTL values to prevent memory leaks
- Use eviction policies (LRU, LFU) for cache-like scenarios

### Testing Guidelines
- Create isolated test instances with unique cluster names
- Always shutdown Hazelcast instances in @AfterEach methods
- Test both success and failure scenarios
- Use meaningful test data that reflects real-world usage

## Common Patterns

### Server Instance Creation
```java
Config config = new Config();
config.setClusterName("unique-cluster-name");
HazelcastInstance instance = Hazelcast.newHazelcastInstance(config);
```

### Client Connection
```java
ClientConfig clientConfig = new ClientConfig();
clientConfig.setClusterName("cluster-name");
clientConfig.getNetworkConfig().addAddress("127.0.0.1:5701");
HazelcastInstance client = HazelcastClient.newHazelcastClient(clientConfig);
```

### Distributed Map Operations
```java
IMap<String, Object> map = instance.getMap("map-name");
map.put("key", value, ttl, TimeUnit.SECONDS);
Object value = map.get("key");
```

## Project Structure
- `com.hazelcast.example.HazelcastServer`: Main server application
- `com.hazelcast.example.HazelcastClientExample`: Client example with various operations
- `src/main/resources/hazelcast.xml`: XML configuration file
- `src/main/resources/logback.xml`: Logging configuration
- `src/test/java/`: Unit tests for Hazelcast functionality

## When suggesting code improvements:
1. Always consider thread safety in distributed environments
2. Suggest appropriate configuration for the use case
3. Include proper error handling and logging
4. Consider scalability and performance implications
5. Ensure proper resource cleanup (shutdown hooks, try-with-resources)
