package com.fitmate.exercise.infrastructure.persistence;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * 动作持久化对象（DO）。字段与 {@code t_exercise} 一一对应。
 *
 * <p>只在本层使用：领域层不接触该类型，应用层也不接触（通过 {@code ExerciseRepository} 转换）。
 */
@Data
@TableName("t_exercise")
public class ExerciseDO {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String name;

    private String muscleGroup;

    private String equipment;

    private Integer difficulty;

    private String demoUrl;

    private String tips;

    private Integer status;

    @TableLogic
    private Integer deleted;
}