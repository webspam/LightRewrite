/*
 * Base class for per-light-source runtime data.
 */
class CLightRewriteSourceParams {
    // The tag that will identify this source in the game
    public const var tag : name;

    // Whether this light source type should be rewritten
    public var enabled : bool;

    // The type of rewriter that will be used to rewrite this light source
    public var rewriterType : ELightRewriteType;

    // Light source brightness
    public var brightness : float;
    // The cutoff radius (sphere)
    public var radius : float;
    // Light attenuation - how quickly the light fades out with distance
    public var attenuation : float;
    // The distance the player is from a light source before the shadow starts to fade
    public var shadowFadeDistance : float;
    // The range of the shadow fade - how quickly the shadow fades out from shadowFadeDistance
    public var shadowFadeRange : float;
    public var shadowBlendFactor : float;

    // If we should override the light source colour
    public var shouldOverrideColour : bool;
    public var color : Color;

    // Whether to align point lights to the light source - *many* point lights have been moved manually
    public var alignPointLights : bool;
    // Offset to add when aligning point lights
    public var pointLightOffset : Vector;

    // Whether to copy the spotlight colour to point lights
    // By default, many candles use low-radius, very red point lights for a close-up glow offset from
    // the bluish scene lighting, and a spotlight for normal mid-range lighting.
    public var useSpotlightColor : bool;

    // The name of this light source type, for logging purposes
    public var displayName : string;
    default displayName = "generic";

    // Virtual constructor
    public function Init() {}
}
