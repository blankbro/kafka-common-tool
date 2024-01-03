package io.github.blankbro.springbootkafka.kafka;

import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

import java.util.List;

@Slf4j
@Component
public class CustomKafkaConsumer {

    @KafkaListener(
            topics = "topic_test_bytes",
            concurrency = "${kafka-consumer.concurrency.topic_test_bytes:2}",
            properties = {
                    "value.deserializer:org.apache.kafka.common.serialization.ByteArrayDeserializer"
            }
    )
    public void topic_test_bytes(List<byte[]> messages) {
        log.info("poll byte[] message size: {}", messages.size());
        for (byte[] message : messages) {
            log.info("byte[] message: {}", new String(message));
        }
    }

    @KafkaListener(
            topics = "topic_test_string",
            concurrency = "${kafka-consumer.concurrency.topic_test_string:2}"
    )
    public void topic_test_string(List<String> messages) {
        log.info("poll string message size: {}", messages.size());
        for (String message : messages) {
            log.info("string message: {}", message);
        }
    }
}
