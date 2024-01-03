package io.github.blankbro.springbootkafka.util;

import org.slf4j.MDC;

import java.util.UUID;

/**
 * TraceIdUtil
 *
 * @author Zexin Li
 * @date 2023-06-06 14:34
 */
public class TraceIdUtil {
    public static final String TRACE_ID_KEY = "trace_id";

    public static void setupTraceId() {
        setupTraceId((String) null);
    }

    public static void setupTraceId(String traceId) {
        if (traceId == null || traceId.isEmpty()) {
            traceId = UUID.randomUUID().toString().replaceAll("-", "");
        }

        MDC.put("trace_id", traceId);
    }

    public static String getTraceId() {
        return MDC.get("trace_id");
    }

    public static void clearTraceId() {
        MDC.remove("trace_id");
    }

    private TraceIdUtil() {
    }
}
