/*
 * This module is designed to align point lights to fire FX slots on "complex" candles.
 * 
 * As we cannot get CFXDefinitions from code, this is brittle, and works based on several assumptions.
 * If any mods alter the FX templates in a way that changes slot names, this may cause strange behaviour.
 * 
 * Unless very specific changes are made, it will simply stop working, rather than cause issues.
 */
class CGenericLightRewriter extends ILightSourceRewriter {
    private var params : CLightRewriteSourceParams;
    
    public function GetParams() : CLightRewriteSourceParams {
        return params;
    }

    public function SetParams(params : CLightRewriteSourceParams) {
        this.params = params;
    }

    public function CandleLightRewrite() {
        var spotLight : CSpotLightComponent;
        var pointLight : CPointLightComponent;
        var i : int;
        var sourceParams : CLightRewriteSourceParams;
        var wasEnabled : bool;

        var components : array<CComponent> = parentEntity.GetComponentsByClassName('CPointLightComponent');
        var count : int = components.Size();

        sourceParams = GetParams();

        if (!sourceParams.enabled) {
            DisableLightRewrite();
            return;
        }

        // Clusters of candles emit most of their light via a single spotlight.
        // The point lights are used to balance the pre-RT fake scene lighting (blue), so they end up being extremely red with RT on.
        spotLight = (CSpotLightComponent)parentEntity.GetComponent('CSpotLightComponent0');

        for (i = 0; i < count; i += 1) {
            pointLight = (CPointLightComponent)components[i];

            if (pointLight) {
                pointLight.SaveLightRewriteOriginalValues();

                wasEnabled = pointLight.IsEnabled();
                if (wasEnabled) pointLight.SetEnabled(false);

                pointLight.brightness = sourceParams.brightness;
                pointLight.radius = sourceParams.radius;
                pointLight.attenuation = sourceParams.attenuation;

                pointLight.shadowFadeDistance = sourceParams.shadowFadeDistance;
                pointLight.shadowFadeRange = sourceParams.shadowFadeRange;
                pointLight.shadowBlendFactor = sourceParams.shadowBlendFactor;

                if (sourceParams.shouldOverrideColour) {
                    pointLight.color = sourceParams.color;
                }
                else if (spotLight && sourceParams.useSpotlightColor) {
                    pointLight.color = spotLight.color;
                }
                else {
                    // No spotlight, and we're not overriding the colour, so use the original colour.
                    pointLight.color = pointLight.lightRewriteOriginalValues.color;
                }

                if (wasEnabled) pointLight.SetEnabled(true);
            }
        }

        // Remove spotlights from candles that have point lights (should be all candles).
        if (count > 0) DisableAllSpotlightComponents();
    }
}
