package io.github.blankbro.springbootkafka.kafka;

import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.clients.consumer.OffsetAndMetadata;
import org.apache.kafka.common.PartitionInfo;
import org.apache.kafka.common.TopicPartition;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.kafka.KafkaProperties;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.function.Function;

@Slf4j
@Component
public class KafkaOffsetTool implements InitializingBean {

    @Resource
    private KafkaProperties kafkaProperties;

    @Value("${spring.kafka.consumer.fetch-max-bytes:0}")
    private Integer consumerFetchMaxBytes;

    @Value("${spring.kafka.consumer.session-timeout-ms}")
    private int consumerSessionTimeoutMs;

    private KafkaConsumer<String, String> kafkaConsumer;

    @Override
    public void afterPropertiesSet() throws Exception {
        // 基于配置文件的内容（KafkaProperties 就是基于配置文件创建的对象），生成消费者配置。
        Map<String, Object> consumerProperties = kafkaProperties.buildConsumerProperties();

        // 由于 KafkaProperties 涵盖的配置并不全，下面这些配置手动添加进来
        consumerProperties.put(ConsumerConfig.SESSION_TIMEOUT_MS_CONFIG, consumerSessionTimeoutMs);
        if (consumerFetchMaxBytes != null && consumerFetchMaxBytes > 0) {
            consumerProperties.put(ConsumerConfig.FETCH_MAX_BYTES_CONFIG, consumerFetchMaxBytes);
        }

        consumerProperties.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, "false");

        kafkaConsumer = new KafkaConsumer<>(consumerProperties);
    }

    private void _setOffset(String topic, Function<Long, Long> newOffsetFunction) {
        List<PartitionInfo> partitionInfos = kafkaConsumer.partitionsFor(topic);
        for (PartitionInfo partitionInfo : partitionInfos) {
            TopicPartition topicPartition = new TopicPartition(partitionInfo.topic(), partitionInfo.partition());
            kafkaConsumer.assign(Collections.singletonList(topicPartition));
            long position = kafkaConsumer.position(topicPartition);
            log.info("{}-{}: {}", topic, partitionInfo.partition(), position);

            Long newPosition = newOffsetFunction.apply(position);
            if (newPosition != null && newPosition > 0 && newPosition != position) {
                OffsetAndMetadata offsetAndMetadata = new OffsetAndMetadata(newPosition);
                kafkaConsumer.commitSync(Collections.singletonMap(topicPartition, offsetAndMetadata));
            } else {
                log.info("无法设置 newPosition:{}, currPosition:{}", newPosition, position);
            }
        }

        log.info("incrementOffset over.");
    }

    public void incrementOffset(String topic, long incrementValue) {
        _setOffset(topic, new Function<Long, Long>() {
            @Override
            public Long apply(Long position) {
                return position + incrementValue;
            }
        });
    }

    public void setOffset(String topic, long setValue) {
        _setOffset(topic, new Function<Long, Long>() {
            @Override
            public Long apply(Long position) {
                return setValue;
            }
        });
    }
}
