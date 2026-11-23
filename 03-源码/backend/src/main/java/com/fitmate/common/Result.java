package com.fitmate.common;

/**
 * 统一响应体。所有接口返回 {@code Result<T>}，便于前端统一拦截。
 *
 * @param code    业务码，0 表示成功
 * @param message 提示信息
 * @param data    业务数据
 */
public record Result<T>(int code, String message, T data) {

    public static <T> Result<T> ok(T data) {
        return new Result<>(ErrorCode.OK.getCode(), ErrorCode.OK.getMessage(), data);
    }

    public static Result<Void> ok() {
        return new Result<>(ErrorCode.OK.getCode(), ErrorCode.OK.getMessage(), null);
    }

    public static <T> Result<T> fail(ErrorCode errorCode) {
        return new Result<>(errorCode.getCode(), errorCode.getMessage(), null);
    }

    public static <T> Result<T> fail(ErrorCode errorCode, String detail) {
        return new Result<>(errorCode.getCode(), detail, null);
    }
}