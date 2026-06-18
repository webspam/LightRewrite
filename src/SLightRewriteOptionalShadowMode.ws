// A shadow-casting-mode light property that may be unset; value applies only when has is true.
struct SLightRewriteOptionalShadowMode {
    var has  : bool;
    var value: ELightShadowCastingMode;
}
