package com.trinhquoctrong.example01;  

import com.trinhquoctrong.example01.controller.MQTTController;  
import com.trinhquoctrong.example01.repository.MessageRepository;  
import com.trinhquoctrong.example01.service.MessageService;  

import java.sql.Connection;  
import java.sql.DriverManager;  

public class Main {  
    public static void main(String[] args) {  
        // Kết nối cơ sở dữ liệu  
        String dbUrl = "jdbc:sqlserver://localhost:1433;databaseName=MQTTTestDB";  
        String dbUsername = "sa";  
        String dbPassword = "your_sql_server_password";  

        try {  
            Connection sqlConnection = DriverManager.getConnection(dbUrl, dbUsername, dbPassword);  
            System.out.println("Kết nối SQL Server thành công!");  

            // Tạo các lớp trong mô hình  
            MessageRepository messageRepository = new MessageRepository(sqlConnection);  
            MessageService messageService = new MessageService(messageRepository);  

            // Cấu hình MQTT  
            String mqttBroker = "tcp://localhost:1883";  
            String mqttTopic = "/test/topic";  
            String mqttUsername = "IoTClient";  
            String mqttPassword = "IoTPass";  

            // Khởi chạy MQTT controller  
            MQTTController mqttController = new MQTTController(mqttBroker, mqttTopic, mqttUsername, mqttPassword, messageService);  
            mqttController.start();  

        } catch (Exception e) {  
            e.printStackTrace();  
        }  
    }  
}