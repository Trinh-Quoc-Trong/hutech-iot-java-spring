package com.trinhquoctrong.example01.service;  

import com.trinhquoctrong.example01.entity.Message;  
import com.trinhquoctrong.example01.repository.MessageRepository;  

import java.sql.Timestamp;  

public class MessageService {  
    private final MessageRepository messageRepository;  

    // Constructor nhận MessageRepository  
    public MessageService(MessageRepository messageRepository) {  
        this.messageRepository = messageRepository;  
    }  

    // Xử lý logic và lưu tin nhắn vào cơ sở dữ liệu  
    public void processAndSaveMessage(String topic, String content) {  
        // Thực hiện logic xử lý (nếu cần) - ở đây ta chỉ lưu nguyên tin nhắn  
        Message message = new Message(topic, content, new Timestamp(System.currentTimeMillis()));  
        messageRepository.saveMessage(message);  
    }  
}