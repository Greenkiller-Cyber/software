package com.fitmate.exercise.application.dto;

/**
 * 动作视图对象。对外只暴露展示所需字段，不直接返回领域对象，
 * 避免后续领域模型演进时污染 API 契约。
 */
public record ExerciseVO(
        Long id,
        String name,
        String muscleGroup,
        String muscleGroupLabel,
        String equipment,
        String equipmentLabel,
        int difficulty,
        String tips
) {
}