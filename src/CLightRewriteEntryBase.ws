/*
 * Base class for light entry params. Holds the light component properties that
 * are shared between point light overrides and spotlight overrides.
 */
class CLightRewriteEntryBase {
    public var hasEnabled : bool;
    public var enabled : bool;

    public var hasBrightness : bool;
    public var brightness : float;

    public var hasRadius : bool;
    public var radius : float;

    // Attenuation — how quickly the light fades out with distance
    public var hasAttenuation : bool;
    public var attenuation : float;

    // Distance at which the player shadow starts to fade
    public var hasShadowFadeDistance : bool;
    public var shadowFadeDistance : float;

    // Range over which the shadow fades from shadowFadeDistance
    public var hasShadowFadeRange : bool;
    public var shadowFadeRange : float;

    public var hasShadowBlendFactor : bool;
    public var shadowBlendFactor : float;

    public var hasColour : bool;
    public var color : Color;
}
