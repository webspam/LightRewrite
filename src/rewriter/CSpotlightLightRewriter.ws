/*
 * Candles whose only light source is a spotlight - they carry no point lights.
 *
 * Where CCandleLightRewriter discards the spotlight in favour of the point lights,
 * here the spotlight is the light: the source params are applied to it directly.
 */
class CSpotlightLightRewriter extends ILightSourceRewriter {
    public function ProcessDeferredActions() {
        super.ProcessDeferredActions();
        RewriteSpotlights();
    }

    public function RewriteLight() {
        RewriteSpotlights();
        ApplyForceCastShadows();
    }

    private function RewriteSpotlights() {
        var p: CLightRewriteSourceParams = GetEffectiveParams();
        var spotLight: CSpotLightComponent;
        var wasEnabled: bool;
        var i, count: int;

        var components: array<CComponent> = parentEntity.GetComponentsByClassName('CSpotLightComponent');
        count = components.Size();

        for (i = 0; i < count; i += 1) {
            spotLight = (CSpotLightComponent)components[i];
            if (!spotLight) continue;

            spotLight.SaveLightRewriteOriginalValues();

            wasEnabled = spotLight.IsEnabled();
            if (wasEnabled) spotLight.SetEnabled(false);

            ApplyLightParams(spotLight, p);

            if (wasEnabled) spotLight.SetEnabled(true);
        }

        if (p.spotlight) RewriteSpotlight(p.spotlight);
    }
}
