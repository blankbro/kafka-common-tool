package io.github.blankbro.springbootkafka;

import io.github.blankbro.springbootkafka.kafka.KafkaOffsetTool;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;

@RunWith(SpringRunner.class)
@SpringBootTest
public class KafkaOffsetToolTest {

    @Autowired
    private KafkaOffsetTool kafkaOffsetTool;

    @Test
    public void testSetOffset() {
        kafkaOffsetTool.setOffset("aaa", 222);
    }
}
