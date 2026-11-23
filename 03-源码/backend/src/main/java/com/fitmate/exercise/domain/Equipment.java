package com.fitmate.exercise.domain;

/**
 * 动作所需器械。{@code mask} 与档案中的 {@code equipment_mask} 位掩码对应，
 * 用于「按用户可用器械过滤动作」。
 */
public enum Equipment {

    BARBELL("杠铃", 1),
    DUMBBELL("哑铃", 2),
    MACHINE("固定器械", 4),
    BAND("弹力带", 8),
    BODYWEIGHT("徒手", 16);

    private final String label;
    private final int mask;

    Equipment(String label, int mask) {
        this.label = label;
        this.mask = mask;
    }

    public String getLabel() {
        return label;
    }

    public int getMask() {
        return mask;
    }

    /**
     * 判断某器械是否包含在用户器械位掩码中。
     */
    public boolean availableFor(int equipmentMask) {
        return (equipmentMask & mask) != 0;
    }
}