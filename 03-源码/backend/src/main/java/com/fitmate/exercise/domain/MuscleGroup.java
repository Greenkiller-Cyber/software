package com.fitmate.exercise.domain;

/**
 * 主肌群。与 {@code t_exercise.muscle_group} 的枚举值一一对应。
 */
public enum MuscleGroup {

    CHEST("胸部"),
    BACK("背部"),
    LEGS("腿部"),
    SHOULDER("肩部"),
    ARMS("手臂"),
    CORE("核心");

    private final String label;

    MuscleGroup(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }
}