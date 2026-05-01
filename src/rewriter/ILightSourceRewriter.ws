/*
 * Interface for light rewriters.
 */
abstract class ILightSourceRewriter {
    // The type of light source this rewriter is for. Implementors must set.
    public var type : ELightRewriteType;

    public var parentEntity : CGameplayEntity;

    // Virtual; Lazy constructor.  If reimplementing, ensure super.Init(parentEntity) is called.
    public function Init(parentEntity : CGameplayEntity) {
        this.parentEntity = parentEntity;

        AddEntityTag();
    }

    // Returns a valid params object for this light source
    public function GetParams() : CLightRewriteSourceParams;

    // Virtual; adds the tag for this light source type to the parent entity.
    public function AddEntityTag() {
        parentEntity.AddTag(GetParams().tag);
    }

    // TODO: Code that supports refactor.  Not for production.
    public function AlignPointLight(i : int, pointLight : CPointLightComponent) {}
}
