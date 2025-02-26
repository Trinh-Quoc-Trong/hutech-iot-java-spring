package com.trinhquoctrong.example01.entity;  

import java.sql.Timestamp;  

public class Message {  
    private int id;  
    private String topic;  
    private String content;  
    private Timestamp timestamp;  

    // Constructor không tham số  
    public Message() {  
    }  

    // Constructor có tham số  
    public Message(String topic, String content, Timestamp timestamp) {  
        this.topic = topic;  
        this.content = content;  
        this.timestamp = timestamp;  
    }  

    // Getter và Setter  
    public int getId() {  
        return id;  
    }  

    public void setId(int id) {  
        this.id = id;  
    }  

    public String getTopic() {  
        return topic;  
    }  

    public void setTopic(String topic) {  
        this.topic = topic;  
    }  

    public String getContent() {  
        return content;  
    }  

    public void setContent(String content) {  
        this.content = content;  
    }  

    public Timestamp getTimestamp() {  
        return timestamp;  
    }  

    public void setTimestamp(Timestamp timestamp) {  
        this.timestamp = timestamp;  
    }  

    @Override  
    public String toString() {  
        return "Message{" +  
                "id=" + id +  
                ", topic='" + topic + '\'' +  
                ", content='" + content + '\'' +  
                ", timestamp=" + timestamp +  
                '}';  
    }  
}