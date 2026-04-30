/*
 * This module is designed to align point lights to fire FX slots on "complex" candles.
 * 
 * As we cannot get CFXDefinitions from code, this is brittle, and works based on several assumptions.
 * If any mods alter the FX templates in a way that changes slot names, this may cause strange behaviour.
 * 
 * Unless very specific changes are made, it will simply stop working, rather than cause issues.
 */

// Stores the names of the active fire FX slots found on this entity.
@addField(CGameplayEntity)
public var lr_fireFxSlotNames : array<name>;

// Aligns a point light to the fire FX slots on this entity.
// At time of writing, only testing / working on complex candles.
@addMethod(CGameplayEntity)
public function AlignLightRewriteCandleLight(i : int, pointLight : CPointLightComponent) {
    var slotPos : Vector;
    var slotMatrix : Matrix;

    var worldToLocal : Matrix;
    var slotWorldPos : Vector;
    var scale : Vector;

    if (lr_fireFxSlotNames.Size()) {
        CalcEntitySlotMatrix(lr_fireFxSlotNames[i], slotMatrix);
        slotWorldPos = MatrixGetTranslation(slotMatrix);

        worldToLocal = MatrixGetInverted(GetLocalToWorld());
        scale = GetLocalScale();
        slotPos = VecTransform(worldToLocal, slotWorldPos) / scale / scale;

        // Arbitrary fire FX offset: centre of candle flame (ish)
        slotPos.Z += 0.075 * scale.Z;

        pointLight.SetPosition(slotPos);
    }
}

// Identify the slot names that might be used as active fire FX slots.
// This information was gathered from inside REDkit's entity template editor by hand.
// Has not been validated against anything but candles in the complex dir.
@addMethod(CGameplayEntity)
function FindLightRewriteFireFxSlotNames() {
    var hasFire4 : bool = HasSlot('fire4');
    var hasFire3 : bool = HasSlot('fire3');
    var hasFire2 : bool = HasSlot('fire2');
    var hasFire1 : bool = HasSlot('fire1');
    var hasFire : bool = HasSlot('fire');
    var hasFx : bool = HasSlot('fx');

    lr_fireFxSlotNames.Clear();

    if (hasFire4) {
        // 3+ candles, with 4, 3 and 2 being lit.  Matches a few configurations of complex candles.
        if (hasFire3 && hasFire2 && hasFire) {
            lr_fireFxSlotNames.PushBack('fire4');
            lr_fireFxSlotNames.PushBack('fire2');
            lr_fireFxSlotNames.PushBack('fire3');
        }
    }
    else if (hasFire3) {
        // 3 candles, 2 lit
        if (hasFire2 && hasFire) {
            lr_fireFxSlotNames.PushBack('fire2');
            lr_fireFxSlotNames.PushBack('fire3');
        }
    }
    else if (hasFire2) {
        // 3 candles, 2 lit
        if (hasFire1 && hasFire) {
            lr_fireFxSlotNames.PushBack('fire1');
            lr_fireFxSlotNames.PushBack('fire2');
        }
    }
    // Single candles - slot name varies
    else if (hasFire) {
        lr_fireFxSlotNames.PushBack('fire');
    }
    else if (hasFx) {
        lr_fireFxSlotNames.PushBack('fx');
    }
}

// Checks if the entity has all the specified slots.
@addMethod(CGameplayEntity)
function LR_HasSlots(slot1 : name, optional slot2 : name, optional slot3 : name, optional slot4 : name) : bool {
    if (!HasSlot(slot1)) return false;
    if (IsNameValid(slot2) && !HasSlot(slot2)) return false;
    if (IsNameValid(slot3) && !HasSlot(slot3)) return false;
    if (IsNameValid(slot4) && !HasSlot(slot4)) return false;

    return true;
}
