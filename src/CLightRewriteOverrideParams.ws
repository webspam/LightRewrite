/** The match should apply to the entity name or layer path */
enum ELightRewriteMatchType {
    LR_Match_Entity,
    LR_Match_Layer,
}

/** String matching mode */
enum ELightRewriteMatchMode {
    LR_Match_StartsWith,
    LR_Match_EndsWith,
    LR_Match_Contains,
    LR_Match_Exact,
}

/** A single match rule */
class CLightRewriteMatchRule {
    public var matchType  : ELightRewriteMatchType;
    public var matchMode  : ELightRewriteMatchMode;
    public var matchValue : name;

    default matchType = LR_Match_Entity;
    default matchMode = LR_Match_StartsWith;

    public function Matches(entity : CGameplayEntity) : bool {
        var subject : string;
        var value   : string = NameToString(matchValue);

        if (matchType == LR_Match_Layer) {
            subject = StrBeforeFirst(StrAfterFirst(entity.ToString(), "\""), "\"");
        } else {
            subject = StrAfterLast(entity.ToString(), StrChar(92));
        }

        if (matchMode == LR_Match_Contains) {
            return StrFindFirst(subject, value) != -1;
        }
        else if (matchMode == LR_Match_EndsWith) {
            return StrEndsWith(subject, value);
        }
        else if (matchMode == LR_Match_Exact) {
            return subject == value;
        }
        else {
            return StrBeginsWith(subject, value);
        }
    }
}

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
