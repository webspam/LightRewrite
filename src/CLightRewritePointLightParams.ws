/* Overrides one point light; index is its position in the entity's component order */
class CLightRewritePointLightParams extends ILightRewriteParams {
    public var index: int;

    public function ApplyTo(target: CLightRewritePointLightParams) {
        ApplyBaseTo(target);
    }
}
