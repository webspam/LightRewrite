/*
 * Abstract base class for all light rewriters.
 */
abstract class ILightSourceRewriter {
    // The type of light source this rewriter is for. Implementors must set.
    public var type: ELightRewriteType;

    // The entity that this rewriter is owned by
    public var parentEntity: CGameplayEntity;

    // The parameters for this light source
    protected var params: CLightRewriteSourceParams;

    // When set, RewriteLight uses these instead of params.
    protected var menuOverrideParams: CLightRewriteSourceParams;

    // Spotlight spawned for a spawn="true" override
    protected var spawnedSpotlight: CEntity;

    // Virtual; Lazy constructor.  If reimplementing, ensure super.Init(parentEntity) is called.
    public function Init(
        parentEntity: CGameplayEntity,
        params: CLightRewriteSourceParams,
        globalOverrides: CLightRewriteSourceParams
    ) {
        this.parentEntity = parentEntity;
        this.params = params;

        parentEntity.AddTag(params.tag);
        if (globalOverrides) {
            parentEntity.AddTag(globalOverrides.tag);
            SetGlobalOverride(globalOverrides);
        }
    }

    // If the params passed in (global params) are enabled, set the menu override params to them.
    public function SetGlobalOverride(params: CLightRewriteSourceParams) {
        if (params.enabled.value) menuOverrideParams = params;
        else menuOverrideParams = NULL;
    }

    protected function GetEffectiveParams(): CLightRewriteSourceParams {
        if (menuOverrideParams) return menuOverrideParams;
        return params;
    }

    // If this rewriter is enabled (params group is enabled)
    public function IsEnabled(): bool {
        return !params.enabled.has || params.enabled.value;
    }

    // Virtual; Called after game has started and components may be disabled.
    public function ProcessDeferredActions() {}

    // Rewrites the light source with the configured parameters.
    public function RewriteLight();

    // Restores the entity's lights to their original state.
    public function RestoreOriginalState() {
        var spotLight: CSpotLightComponent;
        var pointLight: CPointLightComponent;
        var drawable: CDrawableComponent;
        var i: int;
        var interactionComponent: CGameplayLightComponent;
        var useEntityState, entityLightState: bool;

        var components: array<CComponent> = parentEntity.GetComponentsByClassName('CPointLightComponent');
        var count: int = components.Size();

        interactionComponent = (CGameplayLightComponent)parentEntity.GetComponentByClassName('CGameplayLightComponent');
        if (interactionComponent) {
            useEntityState = true;
            entityLightState = interactionComponent.IsLightOn();
        }

        for (i = 0; i < count; i += 1) {
            pointLight = (CPointLightComponent)components[i];

            if (pointLight) {
                pointLight.RestoreLightRewriteOriginalValues(useEntityState, entityLightState);
            }
        }

        // Restore the original state of any spotlights.
        if (count > 0) {
            components = parentEntity.GetComponentsByClassName('CSpotLightComponent');
            count = components.Size();

            for (i = 0; i < count; i += 1) {
                spotLight = (CSpotLightComponent)components[i];

                if (spotLight) {
                    spotLight.RestoreLightRewriteOriginalValues(useEntityState, entityLightState);
                }
            }
        }

        if (spawnedSpotlight) {
            spotLight = (CSpotLightComponent)spawnedSpotlight.GetComponentByClassName('CSpotLightComponent');
            if (spotLight) spotLight.SetEnabled(false);
        }

        components.Clear();
        components = parentEntity.GetComponentsByClassName('CDrawableComponent');
        count = components.Size();
        for (i = 0; i < count; i += 1) {
            drawable = (CDrawableComponent)components[i];
            if (drawable) drawable.RestoreDrawableRewriteOriginalValues();
        }
    }

    // Disables all spotlight components on the entity.
    public function DisableAllSpotlightComponents() {
        var lightComponent: CSpotLightComponent;
        var i: int;

        var components: array<CComponent> = parentEntity.GetComponentsByClassName('CSpotLightComponent');
        var count: int = components.Size();

        for (i = 0; i < count; i += 1) {
            lightComponent = (CSpotLightComponent)components[i];

            if (lightComponent) {
                lightComponent.SaveLightRewriteOriginalValues();
                lightComponent.SetEnabled(false);
            }
        }
    }

    // Shared application of ILightRewriteParams onto any light component - avoids duplicating
    // the same property block for both CPointLightComponent and CSpotLightComponent.
    protected function ApplyLightParams(light: CLightComponent, pamparams: ILightRewriteParams) {
        if (pamparams.brightness.has) light.brightness = pamparams.brightness.value;
        if (pamparams.radius.has) light.radius = pamparams.radius.value;
        if (pamparams.attenuation.has) light.attenuation = pamparams.attenuation.value;
        if (pamparams.shadowFadeDistance.has) {
            light.shadowFadeDistance = pamparams.shadowFadeDistance.value;
        }
        if (pamparams.shadowFadeRange.has) light.shadowFadeRange = pamparams.shadowFadeRange.value;
        if (pamparams.shadowBlendFactor.has) {
            light.shadowBlendFactor = pamparams.shadowBlendFactor.value;
        }
        if (pamparams.castShadows.has) light.shadowCastingMode = pamparams.castShadows.value;
        if (pamparams.color.has) light.color = pamparams.color.value;
    }

    // Rewrites the spotlight component on the entity with the given params.
    protected function RewriteSpotlight(spotParams: CLightRewriteSpotlightParams) {
        var spotLight: CSpotLightComponent;
        var wasEnabled: bool;

        if (spotParams.spawn) {
            RewriteSpawnedSpotlight(spotParams);
            return;
        }

        spotLight = (CSpotLightComponent)parentEntity.GetComponentByClassName('CSpotLightComponent');
        if (!spotLight) return;

        spotLight.SaveLightRewriteOriginalValues();

        if (spotParams.enabled.has && !spotParams.enabled.value) {
            spotLight.SetEnabled(false);
            return;
        }

        wasEnabled = spotLight.IsEnabled();
        if (wasEnabled) spotLight.SetEnabled(false);

        ApplySpotlightParams(spotLight, spotParams);

        if (wasEnabled) spotLight.SetEnabled(true);
    }

    protected function ApplySpotlightParams(
        spotLight: CSpotLightComponent,
        spotParams: CLightRewriteSpotlightParams
    ) {
        ApplyLightParams(spotLight, spotParams);
        if (spotParams.innerAngle.has) spotLight.innerAngle = spotParams.innerAngle.value;
        if (spotParams.outerAngle.has) spotLight.outerAngle = spotParams.outerAngle.value;
        if (spotParams.softness.has) spotLight.softness = spotParams.softness.value;
        if (spotParams.offset.has) spotLight.SetPosition(spotParams.offset.value);
    }

    protected function RewriteSpawnedSpotlight(spotParams: CLightRewriteSpotlightParams) {
        var spotLight: CSpotLightComponent = GetOrSpawnSpotlight();
        if (!spotLight) return;

        spotLight.SetEnabled(false);

        if (spotParams.enabled.has && !spotParams.enabled.value) return;

        ApplySpotlightParams(spotLight, spotParams);
        spotLight.SetEnabled(true);
    }

    private function GetOrSpawnSpotlight(): CSpotLightComponent {
        var template: CEntityTemplate;

        if (!spawnedSpotlight) {
            template = (CEntityTemplate)LoadResource("dlc\lightrewrite\lights\spotlight.w2ent", true);
            if (!template) {
                LogLightRewrite("Spawn spotlight: failed to load template for " + parentEntity);
                return NULL;
            }

            spawnedSpotlight = theGame.CreateEntity(
                template,
                parentEntity.GetWorldPosition(),
                parentEntity.GetWorldRotation()
            );
            if (!spawnedSpotlight) {
                LogLightRewrite("Spawn spotlight: failed to spawn entity for " + parentEntity);
                return NULL;
            }
        }

        return (CSpotLightComponent)spawnedSpotlight.GetComponentByClassName('CSpotLightComponent');
    }

    // Destroy the spawned spotlight entity when this rewriter is discarded, rather than orphan it
    public function DestroySpawnedSpotlight() {
        if (spawnedSpotlight) {
            spawnedSpotlight.Destroy();
            spawnedSpotlight = NULL;
        }
    }

    // Rewrites the specified point light with the rewriter's params.
    protected function RewritePointLight(
        pointLight: CPointLightComponent,
        optional spotLight: CSpotLightComponent
    ) {
        var wasEnabled: bool;

        pointLight.SaveLightRewriteOriginalValues();

        wasEnabled = pointLight.IsEnabled();
        if (wasEnabled) pointLight.SetEnabled(false);

        SetPointLightSettings(pointLight);
        SetPointLightColour(pointLight, spotLight);

        if (wasEnabled) pointLight.SetEnabled(true);
    }

    // Sets basic point light settings
    protected function SetPointLightSettings(pointLight: CPointLightComponent) {
        ApplyLightParams(pointLight, GetEffectiveParams());
    }

    // Sets point light colour to the specified override, spotlight, or original colour
    protected function SetPointLightColour(
        pointLight: CPointLightComponent,
        optional spotLight: CSpotLightComponent
    ) {
        var pamparams: CLightRewriteSourceParams = GetEffectiveParams();

        if (pamparams.color.has) {
            pointLight.color = pamparams.color.value;
        }
        else if (spotLight) {
            pointLight.color = spotLight.color;
        }
        else {
            // No spotlight, and we're not overriding the colour, so use the original colour.
            pointLight.color = pointLight.lightRewriteOriginalValues.color;
        }
    }

    // Enables shadow casting on all drawable (mesh) components - for noshadow entities.
    protected function EnableDrawableShadows() {
        var drawable: CDrawableComponent;
        var components: array<CComponent>;
        var i, count: int;

        var p: CLightRewriteSourceParams = GetEffectiveParams();

        if (!p.forceCastShadows.has || !p.forceCastShadows.value) return;

        components = parentEntity.GetComponentsByClassName('CDrawableComponent');
        count = components.Size();
        for (i = 0; i < count; i += 1) {
            drawable = (CDrawableComponent)components[i];
            if (drawable) {
                drawable.SaveDrawableRewriteOriginalValues();
                drawable.SetCastingShadows(true);
            }
        }
    }
}
