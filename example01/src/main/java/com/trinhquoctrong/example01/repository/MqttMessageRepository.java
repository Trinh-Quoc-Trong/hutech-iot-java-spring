package com.trinhquoctrong.example01.repository;  

import com.trinhquoctrong.example01.model.MqttMessageEntity;  
import org.springframework.data.jpa.repository.JpaRepository;  
import org.springframework.stereotype.Repository;  

@Repository  
public interface MqttMessageRepository extends JpaRepository<MqttMessageEntity, Long> {  
}  
