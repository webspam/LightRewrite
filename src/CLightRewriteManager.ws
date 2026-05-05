/*
 * Handles enabling and disabling Light Rewrite on entities, and other related tasks.
 */
class CLightRewriteManager {
    // Mod settings, which may be initialised prior to game load.
    public var settings : CLightRewriteSettings;

    // Lazy constructor
    public function Init(settings : CLightRewriteSettings) {
        this.settings = settings;
    }

    // Creates a new rewriter for a given light source type.
    public function CreateRewriterFromParams(
        params : CLightRewriteSourceParams,
        entity : CGameplayEntity
    ) : ILightSourceRewriter {
        var rewriter : ILightSourceRewriter;
        var globalOverrides : CLightRewriteSourceParams;

        switch (params.rewriterType) {
            case LRT_Candle:         rewriter = new CCandleLightRewriter in entity;     break;
            default:                 rewriter = new CGenericLightRewriter in entity;    break;
        }

        globalOverrides = settings.GetGlobalOverrideParams(GetGlobalOverrideType(entity));
        rewriter.Init(entity, params, globalOverrides);
        return rewriter;
    }

    // Refreshes Light Rewrite on all light sources.
    public function RewriteAllLightSources() {
        var i, count : int;
        var entities : array<CGameplayEntity>;

        GetAllLightSourceEntities(entities);
        count = entities.Size();

        LogLightRewrite("Refreshing Light Rewrite for " + count + " entities");

        for (i = 0; i < count; i += 1) {
            if (entities[i].IsLightRewritable()) {
                entities[i].lightSourceRewriter.RewriteLight();
            }
            else {
                entities[i].lightSourceRewriter.RestoreOriginalState();
            }
        }
    }

    // Restores all light sources to their original state.
    public function DisableLightRewrite() {
        var i, count : int;
        var entities : array<CGameplayEntity>;

        GetAllLightSourceEntities(entities);
        count = entities.Size();

        LogLightRewrite("Disabling Light Rewrite for " + count + " entities");

        for (i = 0; i < count; i += 1) {
            entities[i].lightSourceRewriter.RestoreOriginalState();
        }
    }

    public function SetGlobalOverride(params : CLightRewriteSourceParams) {
        var entities : array<CEntity>;
        var entity : CGameplayEntity;
        var i : int;
        var count : int;

        theGame.GetEntitiesByTag(params.tag, entities);
        count = entities.Size();

        for (i = 0; i < count; i += 1) {
            entity = (CGameplayEntity)entities[i];
            if (entity) entity.lightSourceRewriter.SetGlobalOverride(params);
        }
    }

    private function GetAllLightSourceEntities(out entities : array<CGameplayEntity>) {
        var nodes : array<CNode>;
        var entity : CGameplayEntity;
        var i : int;
        var count : int;

        var tags : array<name> = settings.GetAllLightSourceTags();

        theGame.GetNodesByTags(tags, nodes);
        count = nodes.Size();

        for (i = 0; i < count; i += 1) {
            entity = (CGameplayEntity)nodes[i];
            if (entity) entities.PushBack(entity);
        }
    }

    // Get the global override type for a given entity. Borderline legacy code at this point.
    private function GetGlobalOverrideType(entity : CGameplayEntity) : ELightRewriteType {
        var fileName : string = StrAfterLast(entity.ToString(), StrChar(92));

        if (StrFindFirst(fileName, "candelabra") != -1) return LRT_Candelabra;
        else if (StrFindFirst(fileName, "chandelier") != -1) return LRT_Chandelier;
        else if (StrFindFirst(fileName, "candle") != -1) return LRT_Candle;
        else if (StrFindFirst(fileName, "torch") != -1) return LRT_Torch;
        else if (StrFindFirst(fileName, "brazier") != -1) return LRT_Brazier;
        else if (StrFindFirst(fileName, "campfire") != -1) return LRT_Campfire;
        return LRT_None;
    }
}
