/*
 * Abstract base class for all light rewriters.
 */
abstract class ILightSourceRewriter {
    // The entity that this rewriter is owned by
    protected var parentEntity: CGameplayEntity;

    // The parameters for this light source
    protected var params: CLightRewriteSourceParams;

    // Extensible API; not used by main code
    protected var overrideParams: CLightRewriteSourceParams;

    // Spotlight spawned for a spawn="true" override
    protected var spawnedSpotlight: CEntity;

    // Upper bound on point-light radius from the spacing pass; 0 means unbounded
    protected var maxSafeRadius: float;

    // Virtual; Lazy constructor.  If reimplementing, ensure super.Init(parentEntity) is called.
    public function Init(parentEntity: CGameplayEntity, params: CLightRewriteSourceParams) {
        this.parentEntity = parentEntity;
        this.params = params;

        parentEntity.AddTag(params.tag);
    }

    // Set the spacing pass's radius bound; re-applied on every RewriteLight
    public function SetMaxSafeRadius(r: float) {
        maxSafeRadius = r;
    }

    public function HasSpacingCap(): bool {
        return maxSafeRadius > 0.0;
    }

    // The radius this light would have with no spacing cap: the profile's, else the saved vanilla
    public function GetUncappedRadius(pointLight: CPointLightComponent): float {
        var p: CLightRewriteSourceParams = GetEffectiveParams();

        if (p.radius.has) return p.radius.value;
        if (pointLight.lightRewriteOriginalValues.hasBeenSaved) {
            return pointLight.lightRewriteOriginalValues.radius;
        }
        return pointLight.radius;
    }

    protected function GetEffectiveParams(): CLightRewriteSourceParams {
        if (overrideParams) return overrideParams;
        return params;
    }

    // If this rewriter is enabled (params group is enabled)
    public function IsEnabled(): bool {
        return !params.enabled.has || params.enabled.value;
    }

    // Virtual; Called after game has started and components may be disabled.
    public function ProcessDeferredActions() {
        parentEntity.AddTimer('ProcessLightRewriteActions', 0.01f, false);
    }

    /** Process actions that must occur after drawable components have loaded */
    public function ProcessFirstFrameActions() {
        ApplyForceCastShadows();
    }

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

        var components: array<CComponent>;
        var count: int;

        interactionComponent = (CGameplayLightComponent)parentEntity.GetComponentByClassName('CGameplayLightComponent');
        if (interactionComponent) {
            useEntityState = true;
            entityLightState = interactionComponent.IsLightOn();
        }

        components = parentEntity.GetComponentsByClassName('CPointLightComponent');
        count = components.Size();
        for (i = 0; i < count; i += 1) {
            pointLight = (CPointLightComponent)components[i];

            if (pointLight) {
                pointLight.RestoreLightRewriteOriginalValues(useEntityState, entityLightState);
            }
        }

        // Restore the original state of any spotlights
        components.Clear();
        components = parentEntity.GetComponentsByClassName('CSpotLightComponent');
        count = components.Size();
        for (i = 0; i < count; i += 1) {
            spotLight = (CSpotLightComponent)components[i];

            if (spotLight) {
                spotLight.RestoreLightRewriteOriginalValues(useEntityState, entityLightState);
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
            if (drawable) drawable.RestoreLightRewriteOriginalValues();
        }
    }

    /** disableUnconfigured switches off spotlights without an override, so candles emit only via point lights */
    protected function ApplyPerLightSpotOverrides(optional disableUnconfigured: bool) {
        var spotLight: CSpotLightComponent;
        var spotParams: CLightRewriteSpotlightParams;
        var i, count: int;
        var components: array<CComponent>;

        var p: CLightRewriteSourceParams = GetEffectiveParams();

        // A spawn override creates its own spotlight entity rather than editing a component
        if (p.spotlight && p.spotlight.spawn) RewriteSpawnedSpotlight(p.spotlight);

        if (!disableUnconfigured && p.spotLights.Size() == 0 && (!p.spotlight || p.spotlight.spawn)) {
            return;
        }

        components = parentEntity.GetComponentsByClassName('CSpotLightComponent');
        count = components.Size();
        for (i = 0; i < count; i += 1) {
            spotLight = (CSpotLightComponent)components[i];
            if (!spotLight) continue;

            spotParams = ResolveSpotParams(p, i);
            if (spotParams) {
                ApplySpotOverride(spotLight, spotParams);
            }
            else if (disableUnconfigured) {
                spotLight.SaveLightRewriteOriginalValues();
                spotLight.SetEnabled(false);
            }
        }
    }

    // The entity-wide spotlight applies to component 0 only; a per-index override layers on top of it
    private function ResolveSpotParams(
        p: CLightRewriteSourceParams,
        index: int
    ): CLightRewriteSpotlightParams {
        var entityWide, perIndex, merged: CLightRewriteSpotlightParams;

        if (index == 0 && p.spotlight && !p.spotlight.spawn) entityWide = p.spotlight;
        perIndex = p.GetSpotLightParams(index);

        if (!entityWide) return perIndex;
        if (!perIndex) return entityWide;

        merged = new CLightRewriteSpotlightParams in parentEntity;
        entityWide.ApplySpotlightTo(merged);
        perIndex.ApplySpotlightTo(merged);
        return merged;
    }

    protected function ApplySpotOverride(
        spotLight: CSpotLightComponent,
        spotParams: CLightRewriteSpotlightParams
    ) {
        var wasEnabled: bool;

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

    public function DestroySpawnedSpotlight() {
        if (spawnedSpotlight) {
            spawnedSpotlight.Destroy();
            spawnedSpotlight = NULL;
        }
    }

    protected function RewritePointLight(
        pointLight: CPointLightComponent,
        pointParams: CLightRewriteComponentLightParams,
        optional spotLight: CSpotLightComponent
    ) {
        var wasEnabled: bool;

        pointLight.SaveLightRewriteOriginalValues();

        if (IsPointLightForceDisabled(pointParams)) {
            pointLight.SetEnabled(false);
            return;
        }

        wasEnabled = pointLight.IsEnabled();
        if (wasEnabled) pointLight.SetEnabled(false);

        SetPointLightSettings(pointLight, pointParams);
        SetPointLightColour(pointLight, pointParams, spotLight);

        if (wasEnabled) pointLight.SetEnabled(true);
    }

    protected function ApplyPointLightParamsOffset(
        pointLight: CPointLightComponent,
        pointParams: CLightRewriteComponentLightParams
    ) {
        if (pointParams && pointParams.offset.has) pointLight.SetPosition(pointParams.offset.value);
    }

    protected function IsPointLightForceDisabled(
        pointParams: CLightRewriteComponentLightParams
    ): bool {
        if (pointParams) return pointParams.enabled.has && !pointParams.enabled.value;
        return false;
    }

    protected function SetPointLightSettings(
        pointLight: CPointLightComponent,
        pointParams: CLightRewriteComponentLightParams
    ) {
        var uncapped: float;

        ApplyLightParams(pointLight, GetEffectiveParams());
        if (pointParams) ApplyLightParams(pointLight, pointParams);

        // Re-establish from source; the spacing cap overwrites the live radius, so it cannot grow back on its own
        if (pointParams && pointParams.radius.has) uncapped = pointParams.radius.value;
        else uncapped = GetUncappedRadius(pointLight);
        pointLight.radius = uncapped;
        if (maxSafeRadius > 0.0 && uncapped > maxSafeRadius) pointLight.radius = maxSafeRadius;
    }

    // Sets point light colour to the specified override, spotlight, or original colour
    protected function SetPointLightColour(
        pointLight: CPointLightComponent,
        pointParams: CLightRewriteComponentLightParams,
        optional spotLight: CSpotLightComponent
    ) {
        var pamparams: CLightRewriteSourceParams = GetEffectiveParams();

        if (pointParams && pointParams.color.has) {
            pointLight.color = pointParams.color.value;
        }
        else if (pamparams.color.has) {
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

    /** Enables shadow casting on all drawable (mesh) components - for noshadow entities */
    protected function ApplyForceCastShadows() {
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
                drawable.SaveLightRewriteOriginalValues();
                drawable.SetCastingShadows(true);
            }
        }
    }
}
