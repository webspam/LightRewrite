@wrapMethod(W3LightSource)
function OnUsed(usedBy: CEntity) {
    var wrappedReturnValue: bool;

    wrappedReturnValue = wrappedMethod(usedBy);
    if (usedBy == thePlayer) InitialiseLightRewriteTorch();

    return wrappedReturnValue;
}

@wrapMethod(CNewNPC)
function OnEquippedItem(category: name, slotName: name) {
    var wrappedReturnValue: bool;
    var inventory: CInventoryComponent;
    var torch: W3LightSource;

    wrappedReturnValue = wrappedMethod(category, slotName);
    if (slotName != 'l_weapon' || category != 'usable') {
        return wrappedReturnValue;
    }

    inventory = GetInventory();
    torch = (W3LightSource)inventory.GetItemEntityUnsafe(inventory.GetItemFromSlot(slotName));
    if (torch) torch.InitialiseLightRewriteTorch();

    return wrappedReturnValue;
}

@wrapMethod(CItemEntity)
function OnAttachmentUpdate(parentEntity: CEntity, itemName: name) {
    var wrappedReturnValue: bool;
    var torch: W3LightSource;

    wrappedReturnValue = wrappedMethod(parentEntity, itemName);

    torch = (W3LightSource)this;
    if (torch) torch.InitialiseLightRewriteTorch();

    return wrappedReturnValue;
}

@addMethod(W3LightSource)
public function InitialiseLightRewriteTorch() {
    AddTag(theGame.lightRewrite.TAG_IS_WIELDED);

    RefreshLightRewriteTorch();
}

@addMethod(W3LightSource)
public function RefreshLightRewriteTorch() {
    var settings: CLightRewriteSettings = theGame.GetLightRewriteSettings();
    var torch: SLightRewriteTorchLight;
    var light: CPointLightComponent;
    var wasEnabled: bool;

    light = (CPointLightComponent)GetComponent('CPointLightComponent0');
    if (!light) return;

    light.SaveLightRewriteOriginalValues();

    if (GetParentEntity() == thePlayer) torch = settings.playerTorch;
    else torch = settings.npcTorch;

    if (!settings.isEnabled || !torch.enabled) {
        light.RestoreLightRewriteOriginalValues(false);
        if (IsEffectActive('light_on')) {
            DestroyEffect('light_on');
            PlayEffect('light_on');
        }
        if (IsEffectActive('light_on_bob')) {
            DestroyEffect('light_on_bob');
            PlayEffect('light_on_bob');
        }
        return;
    }

    wasEnabled = light.IsEnabled();
    if (wasEnabled) light.SetEnabled(false);

    light.brightness = torch.brightness;
    light.radius = torch.radius;
    light.attenuation = torch.attenuation;
    if (torch.colour.has) light.color = torch.colour.value;

    if (wasEnabled) light.SetEnabled(true);
}
