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

    // Refreshes Light Rewrite on all light sources.
    public function RewriteAllLightSources() {
        var i, count : int;
        var entities : array<CGameplayEntity>;

        GetAllLightSourceEntities(entities);
        count = entities.Size();

        LogLightRewrite("Refreshing Light Rewrite for " + count + " entities");

        for (i = 0; i < count; i += 1) {
            if (entities[i].IsLightRewritable()) {
                entities[i].lightSourceRewriter.CandleLightRewrite();
            }
            else {
                entities[i].lightSourceRewriter.DisableLightRewrite();
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
            entities[i].lightSourceRewriter.DisableLightRewrite();
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
}
