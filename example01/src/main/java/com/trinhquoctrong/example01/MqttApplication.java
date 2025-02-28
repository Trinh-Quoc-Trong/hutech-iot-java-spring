package com.trinhquoctrong.example01;  

    import com.trinhquoctrong.example01.controller.MqttController;  
    import org.springframework.beans.factory.annotation.Autowired;  
    import org.springframework.boot.CommandLineRunner;  
    import org.springframework.boot.SpringApplication;  
    import org.springframework.boot.autoconfigure.SpringBootApplication;  

    @SpringBootApplication  
    public class MqttApplication implements CommandLineRunner {  
        private final MqttController mqttController;  

        @Autowired  
        public MqttApplication(MqttController mqttController) {  
            this.mqttController = mqttController;  
        }  

        public static void main(String[] args) {  
            SpringApplication.run(MqttApplication.class, args);  
        }  

        @Override  
        public void run(String... args) {  
            mqttController.startMqttClient();  
        }  
    }  