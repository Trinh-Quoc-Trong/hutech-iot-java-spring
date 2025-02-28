package com.trinhquoctrong.example01.model;  

    import jakarta.persistence.Entity;  
    import jakarta.persistence.GeneratedValue;  
    import jakarta.persistence.GenerationType;  
    import jakarta.persistence.Id;  

    @Entity  
    public class MqttMessageEntity {  
        @Id  
        @GeneratedValue(strategy = GenerationType.IDENTITY)  
        private Long id;  

        private String topic;  
        private String message;  

        // Getters and Setters  
        public Long getId() {  
            return id;  
        }  

        public void setId(Long id) {  
            this.id = id;  
        }  

        public String getTopic() {  
            return topic;  
        }  

        public void setTopic(String topic) {  
            this.topic = topic;  
        }  

        public String getMessage() {  
            return message;  
        }  

        public void setMessage(String message) {  
            this.message = message;  
        }  
    }  
