/*
 * This module is designed to align point lights to fire FX slots on "complex" candles.
 * 
 * As we cannot get CFXDefinitions from code, this is brittle, and works based on several assumptions.
 * If any mods alter the FX templates in a way that changes slot names, this may cause strange behaviour.
 * 
 * Unless very specific changes are made, it will simply stop working, rather than cause issues.
 */
class CGenericLightRewriter extends ILightSourceRewriter {
    public function RewriteLight() {
        var p : CLightRewriteSourceParams = GetEffectiveParams();
        var spotLight : CSpotLightComponent;
        var pointLight : CPointLightComponent;
        var i : int;

        var components : array<CComponent> = parentEntity.GetComponentsByClassName('CPointLightComponent');
        var count : int = components.Size();

        if (p.hasUseSpotlightColor && p.useSpotlightColor) {
            spotLight = (CSpotLightComponent)parentEntity.GetComponent('CSpotLightComponent0');
        }

        for (i = 0; i < count; i += 1) {
            pointLight = (CPointLightComponent)components[i];
            if (pointLight) RewritePointLight(pointLight, spotLight);
        }
    }
}
