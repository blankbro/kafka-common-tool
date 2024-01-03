package io.github.blankbro.springbootkafka.kafka.config;

import io.github.blankbro.springbootkafka.util.TraceIdUtil;
import org.aspectj.lang.annotation.After;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.aspectj.lang.annotation.Pointcut;
import org.springframework.stereotype.Component;

/**
 * KafkaListenerAop
 *
 * @author Zexin Li
 * @date 2023-10-17 14:57
 */
@Aspect
@Component
public class KafkaListenerAop {

    @Pointcut("@annotation(org.springframework.kafka.annotation.KafkaListener)")
    public void pointcut() {

    }

    @Before("pointcut()")
    public void before() {
        TraceIdUtil.setupTraceId();
    }

    @After("pointcut()")
    public void after() {
        TraceIdUtil.clearTraceId();
    }
}
