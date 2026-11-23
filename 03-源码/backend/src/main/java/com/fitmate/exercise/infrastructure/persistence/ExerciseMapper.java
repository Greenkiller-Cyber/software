package com.fitmate.exercise.infrastructure.persistence;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;

/**
 * 动作表 Mapper。仅做单表 CRUD，复杂查询写在 Repository 实现中，避免 SQL 散落到应用层。
 */
@Mapper
public interface ExerciseMapper extends BaseMapper<ExerciseDO> {
}