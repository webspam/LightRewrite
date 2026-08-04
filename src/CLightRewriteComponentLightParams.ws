/** Overrides one light component; index is its position in the entity's component order */
class CLightRewriteComponentLightParams extends ILightRewriteParams {
    public var index: int;

    public function ApplyTo(target: CLightRewriteComponentLightParams) {
        ApplyBaseTo(target);
    }
}
