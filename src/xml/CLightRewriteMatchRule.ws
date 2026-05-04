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
    public var matchType : ELightRewriteMatchType;
    public var matchMode : ELightRewriteMatchMode;
    public var matchValue : name;

    default matchType = LR_Match_Entity;
    default matchMode = LR_Match_StartsWith;

    public function Matches(entity : CGameplayEntity) : bool {
        var subject : string;
        var value : string = NameToString(matchValue);

        if (matchType == LR_Match_Layer) {
            subject = StrBeforeFirst(StrAfterFirst(entity.ToString(), "\""), "\"");
        } else {
            subject = StrAfterLast(entity.ToString(), StrChar(92));
        }

        switch (matchMode) {
            case LR_Match_Contains: return StrFindFirst(subject, value) != -1;
            case LR_Match_EndsWith: return StrEndsWith(subject, value);
            case LR_Match_Exact:    return subject == value;
            default:                return StrBeginsWith(subject, value);
        }
    }
}
