/*
 * Abstract base class for all light rewriters.
 */
abstract class ILightSourceRewriter {
    // The type of light source this rewriter is for. Implementors must set.
    public var type : ELightRewriteType;

    // The entity that this rewriter is owned by
    public var parentEntity : CGameplayEntity;

    // The parameters for this light source
    protected var params : CLightRewriteSourceParams;

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

    // Adds the tag for this light source type to the parent entity.
    public function AddEntityTag() {
        parentEntity.AddTag(params.tag);
    }

    // Rewrites the light source with the configured parameters.
    public function RewriteLight();

    // Restores the entity's lights to their original state.
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
                    // This is a cheap hack and is likely imperfect; we're not tracking enabled state after the initial rewrite.
                    // Will only affect users playing in settings.
                    if (parentEntity.HasTag(theGame.params.TAG_OPEN_FIRE)) spotLight.SetEnabled(true);
                }
            }
        }
    }

    // Disables all spotlight components on the entity.
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

    // Rewrites the specified point light with the rewriter's params.
    protected function RewritePointLight(
        pointLight : CPointLightComponent,
        optional spotLight : CSpotLightComponent
    ) {
        var wasEnabled : bool;

        pointLight.SaveLightRewriteOriginalValues();

        wasEnabled = pointLight.IsEnabled();
        if (wasEnabled) pointLight.SetEnabled(false);

        SetPointLightSettings(pointLight);
        SetPointLightColour(pointLight, spotLight);

        if (wasEnabled) pointLight.SetEnabled(true);
    }

    // Sets basic point light settings
    protected function SetPointLightSettings(pointLight : CPointLightComponent) {
        pointLight.brightness = params.brightness;
        pointLight.radius = params.radius;
        pointLight.attenuation = params.attenuation;
        pointLight.shadowFadeDistance = params.shadowFadeDistance;
        pointLight.shadowFadeRange = params.shadowFadeRange;
        pointLight.shadowBlendFactor = params.shadowBlendFactor;
    }

    // Sets point light colour to the specified override, spotlight, or original colour
    protected function SetPointLightColour(
        pointLight : CPointLightComponent,
        optional spotLight : CSpotLightComponent
    ) {
        if (params.shouldOverrideColour) {
            pointLight.color = params.color;
        }
        else if (spotLight) {
            pointLight.color = spotLight.color;
        }
        else {
            // No spotlight, and we're not overriding the colour, so use the original colour.
            pointLight.color = pointLight.lightRewriteOriginalValues.color;
        }
    }
}
