/*
 * This module is designed to align point lights to fire FX slots on "complex" candles.
 * 
 * As we cannot get CFXDefinitions from code, this is brittle, and works based on several assumptions.
 * If any mods alter the FX templates in a way that changes slot names, this may cause strange behaviour.
 * 
 * Unless very specific changes are made, it will simply stop working, rather than cause issues.
 */
class CCandleLightRewriter extends ILightSourceRewriter {
    // Stores the names of the active fire FX slots found on this entity.
    private var fireFxSlotNames : array<name>;

    public function Init(parentEntity : CGameplayEntity, params : CLightRewriteSourceParams) {
        super.Init(parentEntity, params);

        FindLightRewriteFireFxSlotNames();
    }

    /*
     * Aligns a point light to the fire FX slots on this entity.
     * At time of writing, only testing / working on complex candles.
     */
    public function AlignPointLight(i : int, pointLight : CPointLightComponent) {
        var slotPos : Vector;
        var slotMatrix : Matrix;

        var worldToLocal : Matrix;
        var slotWorldPos : Vector;
        var scale : Vector;

        if (fireFxSlotNames.Size()) {
            parentEntity.CalcEntitySlotMatrix(fireFxSlotNames[i], slotMatrix);
            slotWorldPos = MatrixGetTranslation(slotMatrix);

            worldToLocal = MatrixGetInverted(parentEntity.GetLocalToWorld());
            scale = parentEntity.GetLocalScale();
            slotPos = VecTransform(worldToLocal, slotWorldPos) / scale / scale;

            // Arbitrary fire FX offset: centre of candle flame (ish)
            slotPos += params.pointLightOffset * scale;

            pointLight.SetPosition(slotPos);
        }
    }

    /*
     * Identify the slot names that might be used as active fire FX slots.
     * This information was gathered from inside REDkit's entity template editor by hand.
     * Has not been validated against anything but candles in the complex dir.
     */
    private function FindLightRewriteFireFxSlotNames() {
        var hasFire4 : bool = parentEntity.HasSlot('fire4');
        var hasFire3 : bool = parentEntity.HasSlot('fire3');
        var hasFire2 : bool = parentEntity.HasSlot('fire2');
        var hasFire1 : bool = parentEntity.HasSlot('fire1');
        var hasFire : bool = parentEntity.HasSlot('fire');
        var hasFx : bool = parentEntity.HasSlot('fx');

        fireFxSlotNames.Clear();

        if (hasFire4) {
            // 3+ candles, with 4, 3 and 2 being lit.  Matches a few configurations of complex candles.
            if (hasFire3 && hasFire2 && hasFire) {
                fireFxSlotNames.PushBack('fire4');
                fireFxSlotNames.PushBack('fire2');
                fireFxSlotNames.PushBack('fire3');
            }
        }
        else if (hasFire3) {
            // 3 candles, 2 lit
            if (hasFire2 && hasFire) {
                fireFxSlotNames.PushBack('fire2');
                fireFxSlotNames.PushBack('fire3');
            }
        }
        else if (hasFire2) {
            // 3 candles, 2 lit
            if (hasFire1 && hasFire) {
                fireFxSlotNames.PushBack('fire1');
                fireFxSlotNames.PushBack('fire2');
            }
        }
        // Single candles - slot name varies
        else if (hasFire) {
            fireFxSlotNames.PushBack('fire');
        }
        else if (hasFx) {
            fireFxSlotNames.PushBack('fx');
        }
    }

    // TODO: Code that supports refactor.  Not for production.
    public function RewriteLight() {
        var spotLight : CSpotLightComponent;
        var pointLight : CPointLightComponent;
        var i : int;
        var wasEnabled : bool;

        var components : array<CComponent> = parentEntity.GetComponentsByClassName('CPointLightComponent');
        var count : int = components.Size();

        if (!params.enabled) {
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

                pointLight.brightness = params.brightness;
                pointLight.radius = params.radius;
                pointLight.attenuation = params.attenuation;

                pointLight.shadowFadeDistance = params.shadowFadeDistance;
                pointLight.shadowFadeRange = params.shadowFadeRange;
                pointLight.shadowBlendFactor = params.shadowBlendFactor;

                if (params.alignPointLights) {
                    AlignPointLight(i, pointLight);
                }

                if (params.shouldOverrideColour) {
                    pointLight.color = params.color;
                }
                else if (spotLight && params.useSpotlightColor) {
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
