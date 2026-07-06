/* Overrides one light component; index is its position in the entity's component order */
class CLightRewriteComponentLightParams extends ILightRewriteParams {
    public var index: int;

    // Local-space position override for this component
    public var offset: SLightRewriteOptionalVector;

    public function ApplyTo(target: CLightRewriteComponentLightParams) {
        ApplyBaseTo(target);
        if (offset.has) target.offset = offset;
    }
}
