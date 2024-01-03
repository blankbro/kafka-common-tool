package io.github.blankbro.springbootkafka.controller;

import io.github.blankbro.springbootkafka.kafka.CustomKafkaProducer;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.text.SimpleDateFormat;
import java.util.Date;

@RestController
public class TestController {

    @Autowired
    private CustomKafkaProducer customKafkaProducer;

    @GetMapping("/send")
    public Object send(String topic, String data) {
        customKafkaProducer.send(topic, data);
        return new SimpleDateFormat("yyyy-MM-dd hh:mm:ss").format(new Date()) + " ok";
    }

}
