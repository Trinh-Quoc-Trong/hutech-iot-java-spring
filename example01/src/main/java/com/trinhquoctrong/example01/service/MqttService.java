package com.trinhquoctrong.example01.service;  

    import com.trinhquoctrong.example01.model.MqttMessageEntity;  
    import com.trinhquoctrong.example01.repository.MqttMessageRepository;  
    import org.eclipse.paho.client.mqttv3.*;  
    import org.springframework.beans.factory.annotation.Autowired;  
    import org.springframework.stereotype.Service;  

    @Service  
    public class MqttService {  
        private static final String BROKER_URL = "tcp://localhost:1883";  
        private static final String TOPIC = "/test/topic";  
        private static final String CLIENT_ID = "mqttClient";  
        private static final int QOS = 1;  

        private final MqttMessageRepository mqttMessageRepository;  

        @Autowired  
        public MqttService(MqttMessageRepository mqttMessageRepository) {  
            this.mqttMessageRepository = mqttMessageRepository;  
        }  

        public void startClient() {  
            try {  
                MqttClient client = new MqttClient(BROKER_URL, CLIENT_ID);  
                MqttConnectOptions options = new MqttConnectOptions();  
                options.setUserName("IoTClient");  
                options.setPassword("IoTPass".toCharArray());  
                client.setCallback(new MqttCallback() {  
                    @Override  
                    public void connectionLost(Throwable cause) {  
                        System.out.println("Connection lost: " + cause.getMessage());  
                    }  

                    @Override  
                    public void messageArrived(String topic, MqttMessage message) {  
                        String msg = new String(message.getPayload());  
                        System.out.println("Message arrived: " + msg);  
                        saveMessageToDb(topic, msg); // Save message to database  
                    }  

                    @Override  
                    public void deliveryComplete(IMqttDeliveryToken token) {  
                        System.out.println("Delivery complete!");  
                    }  
                });  

                client.connect(options);  
                client.subscribe(TOPIC, QOS);  

                System.out.println("MQTT Client connected and subscribed to topic: " + TOPIC);  

            } catch (MqttException e) {  
                e.printStackTrace();  
            }  
        }  

        private void saveMessageToDb(String topic, String message) {  
            MqttMessageEntity entity = new MqttMessageEntity();  
            entity.setTopic(topic);  
            entity.setMessage(message);  
            mqttMessageRepository.save(entity); // Invoking Repository here  
        }  
    }