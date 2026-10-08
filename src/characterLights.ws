@addField(W3LightSource) public var torchRewriter: ITorchRewriter;

@addMethod(W3LightSource)
public function GetTorchRewriter(owner: CEntity): ITorchRewriter {
    if (!torchRewriter) {
        if (owner == thePlayer) torchRewriter = new CPlayerTorchRewriter in this;
        else torchRewriter = new CNpcTorchRewriter in this;
        torchRewriter.Init(this);
    }

    return torchRewriter;
}

@addMethod(W3LightSource)
timer function SyncLightRewriteTorch(dt: float, id: int) {
    ((CPlayerTorchRewriter)torchRewriter).SyncTemporaryLight(dt);
}

@wrapMethod(W3LightSource)
function OnUsed(usedBy: CEntity) {
    var wrappedReturnValue: bool;

    wrappedReturnValue = wrappedMethod(usedBy);
    GetTorchRewriter(usedBy).OnUsed();

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
    if (torch) torch.GetTorchRewriter(this).Wield();

    return wrappedReturnValue;
}

@wrapMethod(CItemEntity)
function OnAttachmentUpdate(parentEntity: CEntity, itemName: name) {
    var wrappedReturnValue: bool;
    var torch: W3LightSource;

    wrappedReturnValue = wrappedMethod(parentEntity, itemName);

    torch = (W3LightSource)this;
    if (torch) torch.GetTorchRewriter(parentEntity).Wield();

    return wrappedReturnValue;
}
