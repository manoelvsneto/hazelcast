package com.hazelcast.example.messaging;

import com.azure.messaging.servicebus.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Duration;
import java.time.LocalDateTime;

/**
 * Gerenciador para Azure Service Bus
 */
public class ServiceBusManager {
    private static final Logger logger = LoggerFactory.getLogger(ServiceBusManager.class);
    
    private final ServiceBusSenderClient senderClient;
    private final ServiceBusReceiverClient receiverClient;
    private final ObjectMapper objectMapper;
    private final String queueName;
    
    public ServiceBusManager(String connectionString, String queueName) {
        this.queueName = queueName;
        
        // Configurar ObjectMapper para JSON
        this.objectMapper = new ObjectMapper();
        this.objectMapper.registerModule(new JavaTimeModule());
        
        // Criar cliente de envio
        this.senderClient = new ServiceBusClientBuilder()
            .connectionString(connectionString)
            .sender()
            .queueName(queueName)
            .buildClient();
        
        // Criar cliente de recebimento
        this.receiverClient = new ServiceBusClientBuilder()
            .connectionString(connectionString)
            .receiver()
            .queueName(queueName)
            .buildClient();
        
        logger.info("Service Bus clients initialized for queue: {}", queueName);
    }
    
    /**
     * Envia uma mensagem para o Service Bus
     */
    public void sendMessage(Object messageData, String messageType) {
        try {
            // Criar objeto de evento
            EventMessage event = new EventMessage();
            event.setEventType(messageType);
            event.setTimestamp(LocalDateTime.now());
            event.setData(messageData);
            
            // Converter para JSON
            String jsonMessage = objectMapper.writeValueAsString(event);
            
            // Criar mensagem do Service Bus
            ServiceBusMessage message = new ServiceBusMessage(jsonMessage);
            message.setContentType("application/json");
            message.getApplicationProperties().put("eventType", messageType);
            message.getApplicationProperties().put("timestamp", event.getTimestamp().toString());
            
            // Enviar mensagem
            senderClient.sendMessage(message);
            
            logger.info("Message sent to Service Bus queue '{}': {}", queueName, messageType);
            
        } catch (Exception e) {
            logger.error("Failed to send message to Service Bus", e);
        }
    }
    
    /**
     * Envia evento de usuário
     */
    public void sendUserEvent(String userId, String username, String action, String details) {
        UserEventData eventData = new UserEventData();
        eventData.setUserId(userId);
        eventData.setUsername(username);
        eventData.setAction(action);
        eventData.setDetails(details);
        
        sendMessage(eventData, "USER_EVENT");
    }
    
    /**
     * Envia evento de sistema
     */
    public void sendSystemEvent(String component, String level, String message) {
        SystemEventData eventData = new SystemEventData();
        eventData.setComponent(component);
        eventData.setLevel(level);
        eventData.setMessage(message);
        
        sendMessage(eventData, "SYSTEM_EVENT");
    }
    
    /**
     * Recebe mensagens do Service Bus (para teste)
     */
    public void receiveMessages(int maxMessages, int timeoutSeconds) {
        logger.info("Starting to receive messages from queue: {}", queueName);
        
        try {
            // Configurar processamento de mensagens
            receiverClient.receiveMessages(maxMessages, Duration.ofSeconds(timeoutSeconds))
                .forEach(message -> {
                    try {
                        logger.info("Received message: {}", message.getBody().toString());
                        logger.info("Properties: {}", message.getApplicationProperties());
                        
                        // Completar a mensagem (remover da fila)
                        receiverClient.complete(message);
                        
                    } catch (Exception e) {
                        logger.error("Error processing message", e);
                        // Em caso de erro, abandonar a mensagem para reprocessamento
                        receiverClient.abandon(message);
                    }
                });
                
        } catch (Exception e) {
            logger.error("Error receiving messages from Service Bus", e);
        }
    }
    
    /**
     * Testa a conexão enviando uma mensagem de teste
     */
    public boolean testConnection() {
        try {
            sendSystemEvent("ServiceBusManager", "INFO", "Connection test");
            logger.info("Service Bus connection test successful");
            return true;
        } catch (Exception e) {
            logger.error("Service Bus connection test failed", e);
            return false;
        }
    }
    
    /**
     * Fecha as conexões
     */
    public void shutdown() {
        try {
            if (senderClient != null) {
                senderClient.close();
            }
            if (receiverClient != null) {
                receiverClient.close();
            }
            logger.info("Service Bus clients closed");
        } catch (Exception e) {
            logger.error("Error closing Service Bus clients", e);
        }
    }
    
    // Classes internas para estruturar os eventos
    public static class EventMessage {
        private String eventType;
        private LocalDateTime timestamp;
        private Object data;
        
        // Getters e Setters
        public String getEventType() { return eventType; }
        public void setEventType(String eventType) { this.eventType = eventType; }
        
        public LocalDateTime getTimestamp() { return timestamp; }
        public void setTimestamp(LocalDateTime timestamp) { this.timestamp = timestamp; }
        
        public Object getData() { return data; }
        public void setData(Object data) { this.data = data; }
    }
    
    public static class UserEventData {
        private String userId;
        private String username;
        private String action;
        private String details;
        
        // Getters e Setters
        public String getUserId() { return userId; }
        public void setUserId(String userId) { this.userId = userId; }
        
        public String getUsername() { return username; }
        public void setUsername(String username) { this.username = username; }
        
        public String getAction() { return action; }
        public void setAction(String action) { this.action = action; }
        
        public String getDetails() { return details; }
        public void setDetails(String details) { this.details = details; }
    }
    
    public static class SystemEventData {
        private String component;
        private String level;
        private String message;
        
        // Getters e Setters
        public String getComponent() { return component; }
        public void setComponent(String component) { this.component = component; }
        
        public String getLevel() { return level; }
        public void setLevel(String level) { this.level = level; }
        
        public String getMessage() { return message; }
        public void setMessage(String message) { this.message = message; }
    }
}
