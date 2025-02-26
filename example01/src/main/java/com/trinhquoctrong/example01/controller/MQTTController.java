package com.trinhquoctrong.example01.controller;  

import com.trinhquoctrong.example01.service.MessageService;  
import org.eclipse.paho.client.mqttv3.*;  

import java.io.IOException;  

public class MQTTController {  
    private final String broker;  
    private final String topic;  
    private final String username;  
    private final String password;  
    private final MessageService messageService;  

    public MQTTController(String broker, String topic, String username, String password, MessageService messageService) {  
        this.broker = broker;  
        this.topic = topic;  
        this.username = username;  
        this.password = password;  
        this.messageService = messageService;  
    }  

    public void start() {  
        try {  
            MqttClient mqttClient = new MqttClient(broker, MqttClient.generateClientId());  
            MqttConnectOptions options = new MqttConnectOptions();  
            options.setUserName(username);  
            options.setPassword(password.toCharArray());  
            mqttClient.connect(options);  

            System.out.println("Kết nối MQTT thành công!");  

            mqttClient.setCallback(new MqttCallback() {  
                @Override  
                public void messageArrived(String topic, MqttMessage message) throws Exception {  
                    String content = new String(message.getPayload());  
                    System.out.println("Nhận tin nhắn từ topic [" + topic + "]: " + content);  
                    // Lưu tin nhắn vào cơ sở dữ liệu qua service  
                    messageService.processAndSaveMessage(topic, content);  
                }  

                @Override  
                public void connectionLost(Throwable cause) {  
                    System.out.println("Kết nối bị mất: " + cause.getMessage());  
                }  

                @Override  
                public void deliveryComplete(IMqttDeliveryToken token) {  
                    System.out.println("Gửi tin nhắn hoàn tất.");  
                }  
            });  

            // Subscribe to topic  
            mqttClient.subscribe(topic, 1);  

            // Gửi thử một tin nhắn  
            String testMessage = "Hi from IoT application!";  
            mqttClient.publish(topic, new MqttMessage(testMessage.getBytes()));  

            System.out.println("Nhấn Enter để dừng ứng dụng...");  
            System.in.read();  

            mqttClient.disconnect();  
            mqttClient.close();  
        } catch (MqttException | IOException e) {  
            e.printStackTrace();  
        }  
    }  
}