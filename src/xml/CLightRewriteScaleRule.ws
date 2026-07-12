enum ELightRewriteScaleMatch {
    LR_Scale_Unscaled,
    LR_Scale_Larger,
    LR_Scale_Smaller
}

/** Matches an entity on its own scale, ignoring the scale of its components */
class CLightRewriteScaleRule extends ILightRewriteMatchRule {
    private const var AXIS_TOLERANCE: float;  default AXIS_TOLERANCE = 0.01;

    public var matchValue: ELightRewriteScaleMatch;

    default matchValue = LR_Scale_Unscaled;

    public function Matches(entity: CGameplayEntity): bool {
        var scale: Vector = entity.GetLocalScale();
        var sum: float = scale.X + scale.Y + scale.Z;

        if (AbsF(sum - 3.0) <= AXIS_TOLERANCE * 3.0) return matchValue == LR_Scale_Unscaled;
        if (sum > 3.0) return matchValue == LR_Scale_Larger;
        return matchValue == LR_Scale_Smaller;
    }
}
