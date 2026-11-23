package com.fitmate.exercise.controller;

import com.fitmate.common.Result;
import com.fitmate.exercise.application.ExerciseQueryService;
import com.fitmate.exercise.application.dto.ExerciseVO;
import com.fitmate.exercise.domain.Equipment;
import com.fitmate.exercise.domain.MuscleGroup;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 动作库接口。控制器只做参数接收与响应包装，不含业务逻辑（规则 R-01：禁止直接调 Repository）。
 */
@RestController
@RequestMapping("/api/v1/exercises")
public class ExerciseController {

    private final ExerciseQueryService exerciseQueryService;

    public ExerciseController(ExerciseQueryService exerciseQueryService) {
        this.exerciseQueryService = exerciseQueryService;
    }

    /**
     * 动作列表，可按肌群与器械过滤。
     *
     * @param muscleGroup 可选，取值如 CHEST / BACK
     * @param equipment   可选，取值如 BARBELL / BODYWEIGHT
     */
    @GetMapping
    public Result<List<ExerciseVO>> list(
            @RequestParam(required = false) MuscleGroup muscleGroup,
            @RequestParam(required = false) Equipment equipment) {
        return Result.ok(exerciseQueryService.list(muscleGroup, equipment));
    }

    @GetMapping("/{id}")
    public Result<ExerciseVO> detail(@PathVariable Long id) {
        return Result.ok(exerciseQueryService.getById(id));
    }
}