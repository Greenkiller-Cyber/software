package com.fitmate;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * FitMate 后端启动类。
 *
 * <p>分层约定见《架构设计说明书》§3.3：controller → application → domain ← infrastructure。
 * 领域层不依赖任何框架注解，持久化对象（DO）只存在于 infrastructure 层。
 */
@SpringBootApplication
@MapperScan("com.fitmate.**.infrastructure.persistence")
public class FitMateApplication {

    public static void main(String[] args) {
        SpringApplication.run(FitMateApplication.class, args);
    }
}