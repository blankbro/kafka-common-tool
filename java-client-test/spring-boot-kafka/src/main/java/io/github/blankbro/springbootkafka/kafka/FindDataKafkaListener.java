package io.github.blankbro.springbootkafka.kafka;

import com.alibaba.fastjson2.JSON;
import com.alibaba.fastjson2.JSONObject;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.time.DateFormatUtils;
import org.springframework.boot.autoconfigure.condition.ConditionalOnExpression;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

import java.util.Date;
import java.util.List;
import java.util.concurrent.TimeUnit;

@Slf4j
@ConditionalOnExpression("'${FindDataKafkaListener}' == 'true'")
@Component
public class FindDataKafkaListener {

    private static long last_timestamp = 0;

    private String formatTimestamp(long timestamp) {
        return DateFormatUtils.format(new Date(timestamp), "yyyy-MM-dd HH:mm:ss");
    }

    @KafkaListener(topics = "findData")
    public void findData(List<String> messages) {
        for (String message : messages) {
            JSONObject obj = JSON.parseObject(message);
            String clientId = obj.getString("client_id");
            long timestamp = obj.getLong("timestamp");
            if (timestamp > last_timestamp && timestamp - last_timestamp >= TimeUnit.HOURS.toMillis(1)) {
                last_timestamp = timestamp;
                log.info("{}", formatTimestamp(timestamp));
            }
            if (clientId == null) {
                log.info("{}, clientId is null, message: {}", formatTimestamp(timestamp), message);
            } else if (clientId.contains("111")) {
                log.info("{}, contains message: {}", formatTimestamp(timestamp), message);
            }
        }
    }
}
