package io.github.blankbro.springbootkafka.kafka.config;

import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.kafka.KafkaProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.config.ConcurrentKafkaListenerContainerFactory;
import org.springframework.kafka.config.KafkaListenerContainerFactory;
import org.springframework.kafka.core.DefaultKafkaConsumerFactory;
import org.springframework.kafka.core.DefaultKafkaProducerFactory;
import org.springframework.kafka.core.ProducerFactory;
import org.springframework.kafka.listener.ConcurrentMessageListenerContainer;

import javax.annotation.Resource;
import java.util.Map;

@Configuration
@EnableKafka
@Slf4j
public class KafkaConfig {

    @Resource
    private KafkaProperties kafkaProperties;

    // region producer

    @Value("${spring.kafka.producer.linger-ms:0}")
    private int producerLingerMs;

    @Value("${spring.kafka.producer.max-in-flight-requests-per-connection:0}")
    private int producerMaxInFlightRequestsPerConnection;

    @Value("${spring.kafka.producer.send-buffer-bytes:0}")
    private int producerSendBufferBytes;

    @Value("${spring.kafka.producer.max-request-size:0}")
    private int producerMaxRequestSize;

    @Bean
    public ProducerFactory producerFactory() throws Exception {
        Map<String, Object> producerProperties = kafkaProperties.buildProducerProperties();
        if (producerLingerMs > 0) {
            producerProperties.put(ProducerConfig.LINGER_MS_CONFIG, producerLingerMs);
        }
        if (producerMaxInFlightRequestsPerConnection > 0) {
            producerProperties.put(ProducerConfig.MAX_IN_FLIGHT_REQUESTS_PER_CONNECTION, producerMaxInFlightRequestsPerConnection);
        }
        if (producerSendBufferBytes > 0) {
            producerProperties.put(ProducerConfig.SEND_BUFFER_CONFIG, producerSendBufferBytes);
        }
        if (producerMaxRequestSize > 0) {
            producerProperties.put(ProducerConfig.MAX_REQUEST_SIZE_CONFIG, producerMaxRequestSize);
        }
        return new DefaultKafkaProducerFactory<>(producerProperties);
    }

    // endregion

    // region consumer

    @Value("${spring.kafka.consumer.fetch-max-bytes:0}")
    private Integer consumerFetchMaxBytes;

    @Value("${spring.kafka.consumer.session-timeout-ms}")
    private int consumerSessionTimeoutMs;

    /**
     * 如果你在 @KafkaListener 中没有强制指定 containerFactory，则必须设置为 @Bean("kafkaListenerContainerFactory")
     * 这样的话，我们就可以把默认的 kafkaListenerContainerFactory 顶替掉，从而使用我们自己的配置
     * 默认的在这里创建 ==> org.springframework.boot.autoconfigure.kafka.KafkaAnnotationDrivenConfiguration#kafkaListenerContainerFactory
     */
    @Bean("kafkaListenerContainerFactory")
    public KafkaListenerContainerFactory<ConcurrentMessageListenerContainer<String, String>> kafkaListenerContainerFactory() {
        // 基于配置文件的内容（KafkaProperties 就是基于配置文件创建的对象），生成消费者配置。
        Map<String, Object> consumerProperties = kafkaProperties.buildConsumerProperties();

        // 由于 KafkaProperties 涵盖的配置并不全，下面这些配置手动添加进来
        consumerProperties.put(ConsumerConfig.SESSION_TIMEOUT_MS_CONFIG, consumerSessionTimeoutMs);
        if (consumerFetchMaxBytes != null && consumerFetchMaxBytes > 0) {
            consumerProperties.put(ConsumerConfig.FETCH_MAX_BYTES_CONFIG, consumerFetchMaxBytes);
        }

        ConcurrentKafkaListenerContainerFactory<String, String> containerFactory = new ConcurrentKafkaListenerContainerFactory<>();
        containerFactory.setConsumerFactory(new DefaultKafkaConsumerFactory<>(consumerProperties));

        // 设置为批量监听
        containerFactory.setBatchListener(true);
        return containerFactory;
    }

    // endregion

}
