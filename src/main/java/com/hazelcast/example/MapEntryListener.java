package com.hazelcast.example;

import com.hazelcast.core.EntryEvent;
import com.hazelcast.map.listener.EntryAddedListener;
import com.hazelcast.map.listener.EntryRemovedListener;
import com.hazelcast.map.listener.EntryUpdatedListener;
import com.hazelcast.example.database.SqlServerManager;
import com.hazelcast.example.messaging.ServiceBusManager;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Listener para eventos do mapa que sincroniza com SQL Server e envia eventos para Service Bus
 */
public class MapEntryListener implements EntryAddedListener<String, String>, 
                                       EntryUpdatedListener<String, String>, 
                                       EntryRemovedListener<String, String> {
    
    private static final Logger logger = LoggerFactory.getLogger(MapEntryListener.class);
    
    private final SqlServerManager sqlServerManager;
    private final ServiceBusManager serviceBusManager;
    
    public MapEntryListener(SqlServerManager sqlServerManager, ServiceBusManager serviceBusManager) {
        this.sqlServerManager = sqlServerManager;
        this.serviceBusManager = serviceBusManager;
    }
    
    @Override
    public void entryAdded(EntryEvent<String, String> event) {
        logger.info("Entry ADDED: {} = {}", event.getKey(), event.getValue());
        
        // Persistir no SQL Server
        if (sqlServerManager != null) {
            sqlServerManager.executeUpdate(
                "INSERT INTO user_events (user_id, event_type, event_data) VALUES (?, ?, ?)",
                "system", "MAP_ENTRY_ADDED", "Key: " + event.getKey() + ", Value: " + event.getValue()
            );
        }
        
        // Enviar evento para Service Bus
        if (serviceBusManager != null) {
            serviceBusManager.sendSystemEvent("HazelcastMap", "INFO", 
                "Entry added - Key: " + event.getKey());
        }
    }
    
    @Override
    public void entryUpdated(EntryEvent<String, String> event) {
        logger.info("Entry UPDATED: {} = {} (old: {})", 
            event.getKey(), event.getValue(), event.getOldValue());
        
        // Persistir no SQL Server
        if (sqlServerManager != null) {
            sqlServerManager.executeUpdate(
                "INSERT INTO user_events (user_id, event_type, event_data) VALUES (?, ?, ?)",
                "system", "MAP_ENTRY_UPDATED", 
                "Key: " + event.getKey() + ", New: " + event.getValue() + ", Old: " + event.getOldValue()
            );
        }
        
        // Enviar evento para Service Bus
        if (serviceBusManager != null) {
            serviceBusManager.sendSystemEvent("HazelcastMap", "INFO", 
                "Entry updated - Key: " + event.getKey());
        }
    }
    
    @Override
    public void entryRemoved(EntryEvent<String, String> event) {
        logger.info("Entry REMOVED: {} (was: {})", event.getKey(), event.getOldValue());
        
        // Persistir no SQL Server
        if (sqlServerManager != null) {
            sqlServerManager.executeUpdate(
                "INSERT INTO user_events (user_id, event_type, event_data) VALUES (?, ?, ?)",
                "system", "MAP_ENTRY_REMOVED", "Key: " + event.getKey() + ", Value: " + event.getOldValue()
            );
        }
        
        // Enviar evento para Service Bus
        if (serviceBusManager != null) {
            serviceBusManager.sendSystemEvent("HazelcastMap", "INFO", 
                "Entry removed - Key: " + event.getKey());
        }
    }
}
