package com.trinhquoctrong.example01.controller;  

import com.trinhquoctrong.example01.service.MqttService;  
import org.springframework.beans.factory.annotation.Autowired;  
import org.springframework.stereotype.Controller;  

@Controller  
public class MqttController {  
    private final MqttService mqttService;  

    @Autowired  
    public MqttController(MqttService mqttService) {  
        this.mqttService = mqttService;  
    }  

    public void startMqttClient() {  
        mqttService.startClient();  
    }  
}  