package com.fitmate.common;

/**
 * 业务错误码。采用「HTTP 状态 + 业务码」双轨：HTTP 表达语义分类，业务码供前端精确分支。
 */
public enum ErrorCode {

    OK(0, "成功"),
    PARAM_INVALID(40001, "参数校验失败"),
    UNAUTHORIZED(40101, "未认证或登录已过期"),
    FORBIDDEN(40301, "无权限访问该资源"),
    NOT_FOUND(40401, "资源不存在"),
    CONFLICT(40901, "数据状态冲突，请刷新后重试"),
    INTERNAL(50001, "服务器内部错误");

    private final int code;
    private final String message;

    ErrorCode(int code, String message) {
        this.code = code;
        this.message = message;
    }

    public int getCode() {
        return code;
    }

    public String getMessage() {
        return message;
    }
}