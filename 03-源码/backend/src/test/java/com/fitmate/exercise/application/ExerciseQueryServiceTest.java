package com.fitmate.exercise.application;

import com.fitmate.common.BizException;
import com.fitmate.common.ErrorCode;
import com.fitmate.exercise.application.dto.ExerciseVO;
import com.fitmate.exercise.domain.Equipment;
import com.fitmate.exercise.domain.Exercise;
import com.fitmate.exercise.domain.ExerciseRepository;
import com.fitmate.exercise.domain.MuscleGroup;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * 应用层单元测试：不启动 Spring 容器、不连数据库。
 *
 * <p>用内存伪实现代替 Mockito —— 一方面避免 JDK 21 下 inline mock maker 的 agent 依赖，
 * 另一方面测试更接近真实调用语义（过滤条件真的被执行）。
 */
class ExerciseQueryServiceTest {

    private FakeExerciseRepository repository;
    private ExerciseQueryService service;

    @BeforeEach
    void setUp() {
        repository = new FakeExerciseRepository(List.of(
                new Exercise(1L, "杠铃卧推", MuscleGroup.CHEST, Equipment.BARBELL, 2, null, "肩胛收紧"),
                new Exercise(2L, "哑铃卧推", MuscleGroup.CHEST, Equipment.DUMBBELL, 1, null, "肘部 45 度"),
                new Exercise(3L, "引体向上", MuscleGroup.BACK, Equipment.BODYWEIGHT, 3, null, "避免借力")
        ));
        service = new ExerciseQueryService(repository);
    }

    @Test
    @DisplayName("列表查询应把领域对象转换为带中文标签的 VO")
    void list_mapsDomainToVO() {
        List<ExerciseVO> result = service.list(MuscleGroup.CHEST, Equipment.BARBELL);

        assertEquals(1, result.size());
        ExerciseVO vo = result.get(0);
        assertEquals("杠铃卧推", vo.name());
        assertEquals("CHEST", vo.muscleGroup());
        assertEquals("胸部", vo.muscleGroupLabel());
        assertEquals("BARBELL", vo.equipment());
        assertEquals("杠铃", vo.equipmentLabel());
    }

    @Test
    @DisplayName("只传肌群过滤时应返回该肌群全部动作")
    void list_filtersByMuscleGroupOnly() {
        List<ExerciseVO> chest = service.list(MuscleGroup.CHEST, null);

        assertEquals(2, chest.size());
        assertTrue(chest.stream().allMatch(v -> "CHEST".equals(v.muscleGroup())));
    }

    @Test
    @DisplayName("查询不存在的动作应抛出 NOT_FOUND 业务异常")
    void getById_throwsNotFound() {
        BizException ex = assertThrows(BizException.class, () -> service.getById(99L));

        assertEquals(ErrorCode.NOT_FOUND, ex.getErrorCode());
    }

    @Test
    @DisplayName("器械位掩码应能判断用户是否具备该器械")
    void equipmentMask_works() {
        // 用户只有哑铃(2) + 徒手(16)
        int mask = Equipment.DUMBBELL.getMask() | Equipment.BODYWEIGHT.getMask();

        assertTrue(Equipment.DUMBBELL.availableFor(mask));
        assertTrue(Equipment.BODYWEIGHT.availableFor(mask));
        assertFalse(Equipment.BARBELL.availableFor(mask));
    }

    /**
     * 内存版仓储：只实现被测试用到的过滤语义，不涉及框架。
     */
    private static final class FakeExerciseRepository implements ExerciseRepository {

        private final List<Exercise> data = new ArrayList<>();

        FakeExerciseRepository(List<Exercise> seed) {
            data.addAll(seed);
        }

        @Override
        public List<Exercise> findEnabled(MuscleGroup muscleGroup, Equipment equipment) {
            return data.stream()
                    .filter(e -> muscleGroup == null || e.muscleGroup() == muscleGroup)
                    .filter(e -> equipment == null || e.equipment() == equipment)
                    .collect(Collectors.toList());
        }

        @Override
        public Optional<Exercise> findById(Long id) {
            return data.stream().filter(e -> e.id().equals(id)).findFirst();
        }
    }
}