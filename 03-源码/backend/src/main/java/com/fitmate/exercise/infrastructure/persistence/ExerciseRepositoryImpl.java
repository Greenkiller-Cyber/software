package com.fitmate.exercise.infrastructure.persistence;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.fitmate.exercise.domain.Equipment;
import com.fitmate.exercise.domain.Exercise;
import com.fitmate.exercise.domain.ExerciseRepository;
import com.fitmate.exercise.domain.MuscleGroup;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * 动作仓储实现。负责 DO ↔ 领域对象的转换，并把「启用状态」这类持久化细节挡在领域层之外。
 */
@Repository
public class ExerciseRepositoryImpl implements ExerciseRepository {

    private final ExerciseMapper exerciseMapper;

    public ExerciseRepositoryImpl(ExerciseMapper exerciseMapper) {
        this.exerciseMapper = exerciseMapper;
    }

    @Override
    public List<Exercise> findEnabled(MuscleGroup muscleGroup, Equipment equipment) {
        LambdaQueryWrapper<ExerciseDO> query = Wrappers.lambdaQuery(ExerciseDO.class)
                .eq(ExerciseDO::getStatus, 1)
                .eq(muscleGroup != null, ExerciseDO::getMuscleGroup, muscleGroup == null ? null : muscleGroup.name())
                .eq(equipment != null, ExerciseDO::getEquipment, equipment == null ? null : equipment.name())
                .orderByAsc(ExerciseDO::getMuscleGroup)
                .orderByAsc(ExerciseDO::getId);
        return exerciseMapper.selectList(query).stream().map(this::toDomain).toList();
    }

    @Override
    public Optional<Exercise> findById(Long id) {
        return Optional.ofNullable(exerciseMapper.selectById(id)).map(this::toDomain);
    }

    private Exercise toDomain(ExerciseDO d) {
        return new Exercise(
                d.getId(),
                d.getName(),
                d.getMuscleGroup() == null ? null : MuscleGroup.valueOf(d.getMuscleGroup()),
                d.getEquipment() == null ? null : Equipment.valueOf(d.getEquipment()),
                d.getDifficulty() == null ? 0 : d.getDifficulty(),
                d.getDemoUrl(),
                d.getTips()
        );
    }
}