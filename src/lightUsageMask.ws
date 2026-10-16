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
