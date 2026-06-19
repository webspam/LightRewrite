// A rewriter-type selector that may be unset; value applies only when has is true.
struct SLightRewriteOptionalRewriterType {
    var has  : bool;
    var value: ELightRewriteType;
}
