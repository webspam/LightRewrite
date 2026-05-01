/*
 * Interface for light rewriters.
 */
abstract class ILightSourceRewriter {
    // The type of light source this rewriter is for. Implementors must set.
    public var type : ELightRewriteType;

    public var parentEntity : CGameplayEntity;

    private var params : CLightRewriteSourceParams;

    // Virtual; Lazy constructor.  If reimplementing, ensure super.Init(parentEntity) is called.
    public function Init(parentEntity : CGameplayEntity, params : CLightRewriteSourceParams) {
        this.parentEntity = parentEntity;
        this.params = params;

        AddEntityTag();
    }

    // If this rewriter is enabled (params group is enabled)
    public function IsEnabled() : bool {
        return params.enabled;
    }

    // Virtual; adds the tag for this light source type to the parent entity.
    public function AddEntityTag() {
        parentEntity.AddTag(params.tag);
    }

    // TODO: Code that supports refactor.  Not for production.
    public function RewriteLight();

    public function RestoreOriginalState() {
        var spotLight : CSpotLightComponent;
        var pointLight : CPointLightComponent;
        var i : int;

        var components : array<CComponent> = parentEntity.GetComponentsByClassName('CPointLightComponent');
        var count : int = components.Size();

        for (i = 0; i < count; i += 1) {
            pointLight = (CPointLightComponent)components[i];

            if (pointLight) {
                pointLight.RestoreLightRewriteOriginalValues();
            }
        }

        // Restore the original state of any spotlights.
        if (count > 0) {
            components = parentEntity.GetComponentsByClassName('CSpotLightComponent');
            count = components.Size();

            for (i = 0; i < count; i += 1) {
                spotLight = (CSpotLightComponent)components[i];

                if (spotLight) {
                    spotLight.RestoreLightRewriteOriginalValues();
                    if (parentEntity.HasTag(theGame.params.TAG_OPEN_FIRE)) spotLight.SetEnabled(true);
                }
            }
        }
    }

    protected function DisableAllSpotlightComponents() {
        var lightComponent : CSpotLightComponent;
        var i : int;

        var components : array<CComponent> = parentEntity.GetComponentsByClassName('CSpotLightComponent');
        var count : int = components.Size();

        for (i = 0; i < count; i += 1) {
            lightComponent = (CSpotLightComponent)components[i];

            if (lightComponent) {
                lightComponent.SaveLightRewriteOriginalValues();
                lightComponent.SetEnabled(false);
            }
        }
    }

    public function AlignPointLight(i : int, pointLight : CPointLightComponent) {}
}
