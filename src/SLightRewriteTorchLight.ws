struct SLightRewriteTorchLight {
    var brightness : float;
    var radius     : float;
    var attenuation: float;
    var colour     : SLightRewriteOptionalColour;
    var enabled: bool;  default enabled = true;
}
