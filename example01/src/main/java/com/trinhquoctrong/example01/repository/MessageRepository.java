package com.trinhquoctrong.example01.repository;  

import com.trinhquoctrong.example01.entity.Message;  

import java.sql.Connection;  
import java.sql.PreparedStatement;  
import java.sql.SQLException;  

public class MessageRepository {  
    private final Connection connection;  

    // Constructor nhận Connection  
    public MessageRepository(Connection connection) {  
        this.connection = connection;  
    }  

    // Lưu tin nhắn vào cơ sở dữ liệu  
    public void saveMessage(Message message) {  
        String sql = "INSERT INTO Messages (Topic, Message, Timestamp) VALUES (?, ?, ?)";  
        try (PreparedStatement preparedStatement = connection.prepareStatement(sql)) {  
            preparedStatement.setString(1, message.getTopic());  
            preparedStatement.setString(2, message.getContent());  
            preparedStatement.setTimestamp(3, message.getTimestamp());  
            preparedStatement.executeUpdate();  
            System.out.println("Tin nhắn đã được lưu vào cơ sở dữ liệu: " + message);  
        } catch (SQLException e) {  
            System.err.println("Lỗi khi lưu tin nhắn: " + e.getMessage());  
        }  
    }  
}