package io.github.blankbro.springbootkafka.kafka;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

@Component
public class KafkaProducer {

    @Autowired
    private KafkaTemplate<String, String> stringKafkaTemplate;

    public void send(String topic, String data) {
        stringKafkaTemplate.send(topic, data);
    }
}
