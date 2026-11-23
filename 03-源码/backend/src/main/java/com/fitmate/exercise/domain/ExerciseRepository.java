package com.fitmate.exercise.domain;

import java.util.List;
import java.util.Optional;

/**
 * 动作库仓储接口（领域层定义的端口）。实现位于 infrastructure 层，
 * 依赖方向为 infrastructure → domain，符合 §3.3 的规则 R-04 反向约束。
 */
public interface ExerciseRepository {

    /**
     * 查询启用状态的动作，条件为空表示不过滤。
     *
     * @param muscleGroup 主肌群，可为 null
     * @param equipment   所需器械，可为 null
     */
    List<Exercise> findEnabled(MuscleGroup muscleGroup, Equipment equipment);

    Optional<Exercise> findById(Long id);
}