package com.fitmate.exercise.domain;

/**
 * 动作（领域对象）。刻意不依赖任何框架注解：MyBatis-Plus 的映射对象 {@code ExerciseDO}
 * 只存在于 infrastructure 层，由 Repository 实现负责转换。
 *
 * <p>对应《架构设计说明书》§3.3 规则 R-02（领域层禁止依赖 Web / ORM 框架）。
 */
public record Exercise(
        Long id,
        String name,
        MuscleGroup muscleGroup,
        Equipment equipment,
        int difficulty,
        String demoUrl,
        String tips
) {

    /**
     * 是否适合新手：难度 ≤ 2 视为入门动作。
     */
    public boolean beginnerFriendly() {
        return difficulty <= 2;
    }
}