function ParseLightRewriteType(str: string): ELightRewriteType {
    switch (str) {
        case "LRT_Candle":     return LRT_Candle;
        case "LRT_Spotlight":  return LRT_Spotlight;
        default:               return LRT_None;
    }
}
