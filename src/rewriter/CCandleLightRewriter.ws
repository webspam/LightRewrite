/*
 * This module is designed to align point lights to fire FX slots on "complex" candles.
 */
class CCandleLightRewriter extends IFireFxLightRewriter {
    public function ProcessDeferredActions() {
        var p: CLightRewriteSourceParams = GetEffectiveParams();

        super.ProcessDeferredActions();

        if (!LR_HasPointLight(parentEntity)) {
            RewriteSpotlight(p);
            return;
        }

        ApplySpotOverrides(!p.spotlight);
    }

    public function RewriteLight() {
        var p: CLightRewriteSourceParams = GetEffectiveParams();
        var spotLight: CSpotLightComponent;
        var pointLight, mainLight: CPointLightComponent;
        var pointParams: CLightRewriteComponentLightParams;
        var effective: ILightRewriteParams;
        var centralSlot: name;
        var i: int;
        var forceSingle: bool;

        var components: array<CComponent> = parentEntity.GetComponentsByClassName(
            'CPointLightComponent'
        );
        var count: int = components.Size();

        // Candles that have no point lights
        if (count == 0) {
            RewriteSpotlight(p);
            ApplyForceCastShadows();
            ApplyDefaultState();
            return;
        }

        // Clusters of candles emit most of their light via a single spotlight.
        // The point lights are used to balance the pre-RT fake scene lighting (blue), so they end up being extremely red with RT on.
        if (p.useSpotlightColor.has && p.useSpotlightColor.value) {
            spotLight = (CSpotLightComponent)parentEntity.GetComponent('CSpotLightComponent0');
        }

        forceSingle = p.forceSingleLight.has && p.forceSingleLight.value && count > 1;
        if (forceSingle) {
            mainLight = LR_MainPointLight(parentEntity);
            centralSlot = CentralFireFxSlot();
        }

        for (i = 0; i < count; i += 1) {
            pointLight = (CPointLightComponent)components[i];
            if (!pointLight) continue;

            pointLight.SaveLightRewriteOriginalValues();

            if (forceSingle && pointLight != mainLight) {
                pointLight.radius = 0;
                continue;
            }

            pointParams = p.GetPointLightParams(i);
            effective = p.MergePointLightParams(pointParams);
            if (!ApplyPointLightRewrite(pointLight, pointParams, effective, spotLight)) continue;

            if (p.alignPointLights.has && p.alignPointLights.value) {
                if (forceSingle) {
                    if (centralSlot != '') AlignLightToSlot(centralSlot, pointLight);
                }
                else {
                    AlignLightToFireFxSlot(i, pointLight);
                }
            }
            // Per-index offset wins over flame alignment; the entity-wide offset stays ignored on candles
            if (pointParams && pointParams.offset.has) {
                pointLight.SetPosition(pointParams.offset.value);
            }
        }

        // Remove spotlights from candles that have point lights, unless a spotlight override is
        // configured - in that case, apply it instead.
        ApplySpotOverrides(!p.spotlight);

        ApplyForceCastShadows();
        ApplyDefaultState();
    }

    // Base game candles with no point lights only ever have one spotlight
    private function RewriteSpotlight(p: CLightRewriteSourceParams) {
        var spotLight: CSpotLightComponent;
        var wasEnabled: bool;

        spotLight = (CSpotLightComponent)parentEntity.GetComponentByClassName(
            'CSpotLightComponent'
        );
        if (spotLight) {
            spotLight.SaveLightRewriteOriginalValues();

            wasEnabled = spotLight.IsEnabled();
            if (wasEnabled) spotLight.SetEnabled(false);

            ApplyLightParams(spotLight, p);

            if (p.alignPointLights.has && p.alignPointLights.value) {
                AlignLightToFireFxSlot(0, spotLight);
            }

            if (wasEnabled) spotLight.SetEnabled(true);
        }

        ApplySpotOverrides();
    }
}
