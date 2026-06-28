class CLightRewriteMatchAny extends ILightRewriteMatchRule {
    public var rules: array<ILightRewriteMatchRule>;

    public function Matches(entity: CGameplayEntity): bool {
        var i, count: int;

        count = rules.Size();
        for (i = 0; i < count; i += 1) {
            if (rules[i].Matches(entity)) {
                return true;
            }
        }

        return false;
    }
}
