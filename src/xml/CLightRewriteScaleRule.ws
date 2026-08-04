enum ELightRewriteScaleMatch {
    LR_Scale_Unscaled,
    LR_Scale_Larger,
    LR_Scale_Smaller
}

/** Matches an entity on its own scale, ignoring the scale of its components */
class CLightRewriteScaleRule extends ILightRewriteMatchRule {
    private const var AXIS_TOLERANCE: float;  default AXIS_TOLERANCE = 0.01;

    public var matchValue: ELightRewriteScaleMatch;
    public var scale     : float;

    default matchValue = LR_Scale_Unscaled;
    default scale = 1.0;

    public function Matches(entity: CGameplayEntity): bool {
        var entityScale: Vector = entity.GetLocalScale();
        var sum: float = entityScale.X + entityScale.Y + entityScale.Z;
        var target: float = scale * 3.0;

        if (AbsF(sum - target) <= AXIS_TOLERANCE * 3.0) return matchValue == LR_Scale_Unscaled;
        if (sum > target) return matchValue == LR_Scale_Larger;
        return matchValue == LR_Scale_Smaller;
    }
}
