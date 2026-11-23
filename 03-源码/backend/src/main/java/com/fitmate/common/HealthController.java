package com.fitmate.common;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 健康检查接口。用于部署验证与演示环境自检（不依赖数据库，可单独判断应用是否存活）。
 */
@RestController
@RequestMapping("/api/v1")
public class HealthController {

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    @GetMapping("/health")
    public Result<Map<String, Object>> health() {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("status", "UP");
        body.put("app", "fitmate-backend");
        body.put("version", "0.1.0");
        body.put("time", LocalDateTime.now().format(FMT));
        return Result.ok(body);
    }
}