// Backing field for a fancy rsblob trick to bypass ELightUsageMask restriction
@addField(CLightComponent) var lrLightUsageMaskProxy: int;

@addMethod(CLightComponent)
public function LR_GetLightUsageMask(): int {
    return lrLightUsageMaskProxy;
}

@addMethod(CLightComponent)
public function LR_SetLightUsageMask(mask: int) {
    lrLightUsageMaskProxy = mask;
}

enum ELightRewriteUsageMask {
    LRLUM_RenderToEnvProbe = 0x100,
    LRLUM_ExcludeFromSceneRender = 0x200,
    LRLUM_InteriorOnly = 0x400,
    LRLUM_ExteriorOnly = 0x800
}

function LR_ClearBits(value: int, bits: int): int {
    return value - (value & bits);
}

function LR_HasUsageMaskEdit(edit: SLightRewriteUsageMaskEdit): bool {
    return edit.setBits != 0 || edit.clearBits != 0;
}

function LR_ApplyUsageMaskEdit(mask: int, edit: SLightRewriteUsageMaskEdit): int {
    return LR_ClearBits(mask, edit.clearBits) | edit.setBits;
}

function LR_MergeUsageMaskEdit(
    lowerWeight: SLightRewriteUsageMaskEdit,
    higherWeight: SLightRewriteUsageMaskEdit
): SLightRewriteUsageMaskEdit {
    var merged: SLightRewriteUsageMaskEdit;

    merged.setBits = LR_ClearBits(
        lowerWeight.setBits,
        higherWeight.clearBits
    ) | higherWeight.setBits;
    merged.clearBits = LR_ClearBits(
        lowerWeight.clearBits,
        higherWeight.setBits
    ) | higherWeight.clearBits;
    return merged;
}
