package com.fitmate.exercise.application;

import com.fitmate.common.BizException;
import com.fitmate.common.ErrorCode;
import com.fitmate.exercise.application.dto.ExerciseVO;
import com.fitmate.exercise.domain.Equipment;
import com.fitmate.exercise.domain.Exercise;
import com.fitmate.exercise.domain.ExerciseRepository;
import com.fitmate.exercise.domain.MuscleGroup;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 动作查询服务（应用层）。职责是编排与转换，业务规则放在领域对象里。
 *
 * <p>只读服务，事务标注为 readOnly。
 */
@Service
public class ExerciseQueryService {

    private final ExerciseRepository exerciseRepository;

    public ExerciseQueryService(ExerciseRepository exerciseRepository) {
        this.exerciseRepository = exerciseRepository;
    }

    @Transactional(readOnly = true)
    public List<ExerciseVO> list(MuscleGroup muscleGroup, Equipment equipment) {
        return exerciseRepository.findEnabled(muscleGroup, equipment).stream()
                .map(this::toVO)
                .toList();
    }

    @Transactional(readOnly = true)
    public ExerciseVO getById(Long id) {
        Exercise exercise = exerciseRepository.findById(id)
                .orElseThrow(() -> new BizException(ErrorCode.NOT_FOUND, "动作不存在：" + id));
        return toVO(exercise);
    }

    private ExerciseVO toVO(Exercise e) {
        return new ExerciseVO(
                e.id(),
                e.name(),
                e.muscleGroup() == null ? null : e.muscleGroup().name(),
                e.muscleGroup() == null ? null : e.muscleGroup().getLabel(),
                e.equipment() == null ? null : e.equipment().name(),
                e.equipment() == null ? null : e.equipment().getLabel(),
                e.difficulty(),
                e.tips()
        );
    }
}