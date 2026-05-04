class CLightRewriteOverrideParams {
    public var matchRules   : array<CLightRewriteMatchRule>;

    public var tag          : name;
    public var displayName  : string;

    public var hasBrightness        : bool;
    public var brightness           : float;

    public var hasRadius            : bool;
    public var radius               : float;

    public var hasAttenuation       : bool;
    public var attenuation          : float;

    public var hasShadowFadeDistance : bool;
    public var shadowFadeDistance    : float;

    public var hasShadowFadeRange   : bool;
    public var shadowFadeRange      : float;

    public var hasShadowBlendFactor : bool;
    public var shadowBlendFactor    : float;

    public var hasColour            : bool;
    public var shouldOverrideColour : bool;
    public var color                : Color;

    public function MatchesEntity(entity : CGameplayEntity) : bool {
        var i, count : int;

        count = matchRules.Size();
        for (i = 0; i < count; i += 1) {
            if (!matchRules[i].Matches(entity)) {
                return false;
            }
        }

        return true;
    }

    public function ApplyTo(params : CLightRewriteSourceParams) {
        if (hasBrightness)        { params.brightness        = brightness;        }
        if (hasRadius)            { params.radius            = radius;            }
        if (hasAttenuation)       { params.attenuation       = attenuation;       }
        if (hasShadowFadeDistance) { params.shadowFadeDistance = shadowFadeDistance; }
        if (hasShadowFadeRange)   { params.shadowFadeRange   = shadowFadeRange;   }
        if (hasShadowBlendFactor) { params.shadowBlendFactor = shadowBlendFactor; }
        if (hasColour) {
            params.shouldOverrideColour = shouldOverrideColour;
            params.color                = color;
        }
    }
}
