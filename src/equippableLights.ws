@addField(W3LightSource) public var lrEquippableRewriter: IEquippableLightRewriter;

@addMethod(W3LightSource)
public function GetEquippableLightRewriter(owner: CEntity): IEquippableLightRewriter {
    if (lrEquippableRewriter) return lrEquippableRewriter;

    if (StrEndsWith(ToString(), "items\usable\oillamp\oillamp.w2ent")) {
        lrEquippableRewriter = new CLanternRewriter in this;
    }
    else {
        lrEquippableRewriter = new CTorchRewriter in this;
    }

    lrEquippableRewriter.Init(this, owner == thePlayer);
    return lrEquippableRewriter;
}

@addMethod(W3LightSource)
timer function SyncLightRewriteEquippable(dt: float, id: int) {
    if (lrEquippableRewriter) lrEquippableRewriter.SyncTemporaryLight(dt);
}

@wrapMethod(W3LightSource)
function OnUsed(usedBy: CEntity) {
    var wrappedReturnValue: bool;

    wrappedReturnValue = wrappedMethod(usedBy);
    GetEquippableLightRewriter(usedBy).OnUsed();

    return wrappedReturnValue;
}

@wrapMethod(W3LightSource)
function OnHidden(usedBy: CEntity) {
    var wrappedReturnValue: bool;

    if (lrEquippableRewriter) lrEquippableRewriter.OnHidden();
    wrappedReturnValue = wrappedMethod(usedBy);

    return wrappedReturnValue;
}

@wrapMethod(CNewNPC)
function OnEquippedItem(category: name, slotName: name) {
    var wrappedReturnValue: bool;
    var inventory: CInventoryComponent;
    var light: W3LightSource;

    wrappedReturnValue = wrappedMethod(category, slotName);
    if (slotName != 'l_weapon' || category != 'usable') {
        return wrappedReturnValue;
    }

    inventory = GetInventory();
    light = (W3LightSource)inventory.GetItemEntityUnsafe(inventory.GetItemFromSlot(slotName));
    if (light) light.GetEquippableLightRewriter(this).ItemWielded();

    return wrappedReturnValue;
}

@wrapMethod(CItemEntity)
function OnAttachmentUpdate(parentEntity: CEntity, itemName: name) {
    var wrappedReturnValue: bool;
    var light: W3LightSource;

    wrappedReturnValue = wrappedMethod(parentEntity, itemName);

    light = (W3LightSource)this;
    if (light) light.GetEquippableLightRewriter(parentEntity).ItemWielded();

    return wrappedReturnValue;
}
