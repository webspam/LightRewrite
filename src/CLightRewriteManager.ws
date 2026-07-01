/*
 * Handles enabling and disabling Light Rewrite on entities, and other related tasks.
 */
class CLightRewriteManager {
    // Tag to identify entities that have a rewritable light.
    public const var TAG_HAS_LIGHT: name;  default TAG_HAS_LIGHT = "LR_HasLight";

    // Mod settings, which may be initialised prior to game load.
    public var settings: CLightRewriteSettings;

    // Whether the game has finished starting
    public var gameStarted: bool;

    // Lazy constructor
    public function Init(settings: CLightRewriteSettings) {
        this.settings = settings;
    }

    public function ProcessDeferredActions() {
        var i, count: int;
        var entities: array<CGameplayEntity>;

        if (gameStarted) return;
        gameStarted = true;

        if (!settings.isEnabled) return;

        GetAllLightSourceEntities(entities);
        count = entities.Size();

        for (i = 0; i < count; i += 1) {
            if (!entities[i].IsLightRewritable()) continue;

            entities[i].lightSourceRewriter.ProcessDeferredActions();
        }
    }

    // Creates a new rewriter for a given light source type.
    public function CreateRewriterFromParams(
        params: CLightRewriteSourceParams,
        entity: CGameplayEntity
    ): ILightSourceRewriter {
        var rewriter: ILightSourceRewriter;

        switch (params.rewriterType.value) {
            case LRT_Candle:     rewriter = new CCandleLightRewriter in entity;     break;
            case LRT_Spotlight:  rewriter = new CSpotlightLightRewriter in entity;  break;
            default:             rewriter = new CGenericLightRewriter in entity;    break;
        }

        rewriter.Init(entity, params);
        return rewriter;
    }

    public function ChangeProfile() {
        var i, count: int;
        var entities: array<CEntity>;
        var entity: CGameplayEntity;

        LogLightRewrite("Changing Light Rewrite profile");
        theGame.GetEntitiesByTag(TAG_HAS_LIGHT, entities);

        count = entities.Size();
        for (i = 0; i < count; i += 1) {
            entity = (CGameplayEntity)entities[i];
            if (entity) entity.LightRewriteProfileChanged();
        }

        ApplySpacing();
    }

    public function ApplySpacing() {
        var spacer: CLightRewriteSpacer;

        if (!settings.isEnabled) return;

        spacer = new CLightRewriteSpacer in this;
        spacer.Configure(settings.GetSpacingMode(), settings.GetSpacingAmount());
        spacer.Solve();
        delete spacer;
    }

    // Refreshes Light Rewrite on all light sources.
    public function RewriteAllLightSources() {
        var i, count: int;
        var entities: array<CGameplayEntity>;

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
        var i, count: int;
        var entities: array<CGameplayEntity>;

        GetAllLightSourceEntities(entities);
        count = entities.Size();

        LogLightRewrite("Disabling Light Rewrite for " + count + " entities");

        for (i = 0; i < count; i += 1) {
            entities[i].lightSourceRewriter.RestoreOriginalState();
        }
    }

    private function GetAllLightSourceEntities(out entities: array<CGameplayEntity>) {
        var nodes: array<CNode>;
        var entity: CGameplayEntity;
        var i: int;
        var count: int;

        var tags: array<name> = settings.GetAllLightSourceTags();

        theGame.GetNodesByTags(tags, nodes);
        count = nodes.Size();

        for (i = 0; i < count; i += 1) {
            entity = (CGameplayEntity)nodes[i];
            if (entity) entities.PushBack(entity);
        }
    }
}
