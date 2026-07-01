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
    private var fireFxSlotNames: array<name>;

    public function Init(parentEntity: CGameplayEntity, params: CLightRewriteSourceParams) {
        super.Init(parentEntity, params);

        FindLightRewriteFireFxSlotNames();
    }

    public function ProcessDeferredActions() {
        var p: CLightRewriteSourceParams = GetEffectiveParams();

        super.ProcessDeferredActions();

        if (p.spotlight) {
            RewriteSpotlight(p.spotlight);
        }
        else {
            DisableAllSpotlightComponents();
        }
    }

    public function RewriteLight() {
        var p: CLightRewriteSourceParams = GetEffectiveParams();
        var spotLight: CSpotLightComponent;
        var pointLight, mainLight: CPointLightComponent;
        var centralSlot: name;
        var i: int;
        var wasEnabled, forceSingle: bool;

        var components: array<CComponent> = parentEntity.GetComponentsByClassName('CPointLightComponent');
        var count: int = components.Size();

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

            wasEnabled = pointLight.IsEnabled();
            if (wasEnabled) pointLight.SetEnabled(false);

            SetPointLightSettings(pointLight);
            SetPointLightColour(pointLight, spotLight);

            if (p.alignPointLights.has && p.alignPointLights.value) {
                if (forceSingle) {
                    if (centralSlot != '') AlignLightToSlot(centralSlot, pointLight);
                }
                else {
                    AlignPointLight(i, pointLight);
                }
            }

            if (wasEnabled) pointLight.SetEnabled(true);
        }

        // Remove spotlights from candles that have point lights (should be all candles),
        // unless a spotlight override is configured - in that case, apply it instead.
        if (count > 0) {
            if (p.spotlight) {
                RewriteSpotlight(p.spotlight);
            }
            else {
                DisableAllSpotlightComponents();
            }
        }

        ApplyForceCastShadows();
    }

    /*
     * Aligns a point light to the fire FX slots on this entity.
     * At time of writing, only testing / working on complex candles.
     */
    private function AlignPointLight(i: int, pointLight: CPointLightComponent) {
        if (i < fireFxSlotNames.Size()) AlignLightToSlot(fireFxSlotNames[i], pointLight);
    }

    private function AlignLightToSlot(slotName: name, light: CLightComponent) {
        var slotPos: Vector;
        var slotMatrix: Matrix;

        var worldToLocal: Matrix;
        var slotWorldPos: Vector;
        var scale: Vector;

        parentEntity.CalcEntitySlotMatrix(slotName, slotMatrix);
        slotWorldPos = MatrixGetTranslation(slotMatrix);

        worldToLocal = MatrixGetInverted(parentEntity.GetLocalToWorld());
        scale = parentEntity.GetLocalScale();
        slotPos = VecTransform(worldToLocal, slotWorldPos) / scale / scale;

        // Arbitrary fire FX offset: centre of candle flame (ish)
        slotPos += GetEffectiveParams().pointLightOffset;

        light.SetPosition(slotPos);
    }

    private function CentralFireFxSlot(): name {
        var slotMatrix: Matrix;
        var centroid, pos: Vector;
        var positions: array<Vector>;
        var bestDist, dist: float;
        var bestIdx, i, count: int;

        count = fireFxSlotNames.Size();
        if (count == 0) return '';
        if (count == 1) return fireFxSlotNames[0];

        for (i = 0; i < count; i += 1) {
            parentEntity.CalcEntitySlotMatrix(fireFxSlotNames[i], slotMatrix);
            pos = MatrixGetTranslation(slotMatrix);
            positions.PushBack(pos);
            centroid.X += pos.X;
            centroid.Y += pos.Y;
            centroid.Z += pos.Z;
        }
        centroid.X /= count;
        centroid.Y /= count;
        centroid.Z /= count;

        bestIdx = 0;
        bestDist = VecDistanceSquared(positions[0], centroid);
        for (i = 1; i < count; i += 1) {
            dist = VecDistanceSquared(positions[i], centroid);
            if (dist < bestDist) {
                bestDist = dist;
                bestIdx = i;
            }
        }
        return fireFxSlotNames[bestIdx];
    }

    /*
     * Identify the slot names that might be used as active fire FX slots.
     * This information was gathered from inside REDkit's entity template editor by hand.
     * Has not been validated against anything but candles in the complex dir.
     */
    private function FindLightRewriteFireFxSlotNames() {
        var hasFire4: bool = parentEntity.HasSlot('fire4');
        var hasFire3: bool = parentEntity.HasSlot('fire3');
        var hasFire2: bool = parentEntity.HasSlot('fire2');
        var hasFire1: bool = parentEntity.HasSlot('fire1');
        var hasFire: bool = parentEntity.HasSlot('fire');
        var hasFx: bool = parentEntity.HasSlot('fx');

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
        else if (hasFire) {
            // Single candles - slot name varies
            fireFxSlotNames.PushBack('fire');
        }
        else if (hasFx) {
            fireFxSlotNames.PushBack('fx');
        }
    }
}
