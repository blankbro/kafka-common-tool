package io.github.blankbro.springbootkafka.controller;

import io.github.blankbro.springbootkafka.kafka.KafkaProducer;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.text.SimpleDateFormat;
import java.util.Date;

@Slf4j
@RestController
public class TestController {

    @Autowired
    private KafkaProducer kafkaProducer;

    /**
     * 从容器中创建 topic
     * cd /opt/bitnami/kafka/bin
     * ./kafka-topics.sh --create --topic topic_test_string --bootstrap-server localhost:9092
     * ./kafka-topics.sh --create --topic topic_test_bytes --bootstrap-server localhost:9092
     * 测试该接口
     * curl "http://localhost:8088/send?topic=topic_test_string&data=lalala"
     *
     * @param topic
     * @param data
     * @return
     */
    @GetMapping("/send")
    public Object send(String topic, String data) {
        log.info("topic = {}, data = {}", topic, data);
        kafkaProducer.send(topic, data);
        return new SimpleDateFormat("yyyy-MM-dd hh:mm:ss").format(new Date()) + " ok";
    }

}
