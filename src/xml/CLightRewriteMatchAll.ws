class CLightRewriteMatchAll extends CLightRewriteMatchGroup {
    public function Matches(target: CLightRewriteMatchTarget): bool {
        var i, count: int;

        count = rules.Size();
        for (i = 0; i < count; i += 1) {
            if (!rules[i].Matches(target)) {
                return false;
            }
        }

        return true;
    }
}
