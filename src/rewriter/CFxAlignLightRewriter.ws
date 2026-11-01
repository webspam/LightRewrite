/*
 * Aligns every light rendered in the scene to the fire FX slots: point lights first, then spotlights.
 *
 * Entity instances using different LUM combinations are sacred in Toussaint.
 */
class CFxAlignLightRewriter extends IFireFxLightRewriter {
    public function ProcessDeferredActions() {
        super.ProcessDeferredActions();
        ApplySpotOverrides();
    }

    public function RewriteLight() {
        var spotLight: CSpotLightComponent;
        var pointLight: CPointLightComponent;
        var light: CLightComponent;
        var pointParams: CLightRewriteComponentLightParams;
        var spotParams: CLightRewriteSpotlightParams;
        var slotIndex, i: int;

        var p: CLightRewriteSourceParams = GetEffectiveParams();
        var alignToFireFx: bool = p.alignPointLights.has && p.alignPointLights.value;

        var components: array<CComponent> = parentEntity.GetComponentsByClassName(
            'CPointLightComponent'
        );
        var count: int = components.Size();

        ApplyDefaultState();

        if (p.useSpotlightColor.has && p.useSpotlightColor.value) {
            spotLight = (CSpotLightComponent)parentEntity.GetComponent('CSpotLightComponent0');
        }

        for (i = 0; i < count; i += 1) {
            pointLight = (CPointLightComponent)components[i];
            if (!pointLight) continue;

            RewritePointLight(pointLight, i, spotLight);

            if (!alignToFireFx) continue;
            if (!IsRenderedInScene(pointLight)) continue;

            pointParams = p.GetPointLightParams(i);
            if (!pointParams || !pointParams.offset.has) {
                AlignLightToFireFxSlot(slotIndex, pointLight);
            }
            slotIndex += 1;
        }

        ApplySpotOverrides();

        if (alignToFireFx) {
            components.Clear();
            components = parentEntity.GetComponentsByClassName('CSpotLightComponent');
            count = components.Size();
            for (i = 0; i < count; i += 1) {
                light = (CLightComponent)components[i];
                if (!light || !IsRenderedInScene(light)) continue;

                spotParams = p.GetEffectiveSpotLightParams(i);
                if (!spotParams || !spotParams.offset.has) {
                    AlignLightToFireFxSlot(slotIndex, light);
                }
                slotIndex += 1;
            }
        }

        ApplyForceCastShadows();
    }

    private function IsRenderedInScene(light: CLightComponent): bool {
        return (light.LR_GetLightUsageMask() & LRLUM_ExcludeFromSceneRender) == 0;
    }
}
