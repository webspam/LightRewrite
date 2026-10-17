abstract class IEquippableLightRewriter {
    protected var parentEntity    : W3LightSource;
    protected var wieldedByPlayer : bool;
    protected var hasModifiedLight: bool;
    protected var temporaryLight  : CLightComponent;
    protected var isBob           : bool;

    public function Init(parentEntity: W3LightSource, wieldedByPlayer: bool) {
        this.parentEntity = parentEntity;
        this.wieldedByPlayer = wieldedByPlayer;
        isBob = StrFindFirst(theGame.GetWorld().GetDepotPath(), "bob") >= 0;
    }

    public function ItemWielded() {
        parentEntity.AddTag(theGame.lightRewrite.TAG_IS_WIELDED);

        Refresh();
    }

    public function OnUsed() {
        var light: CLightComponent;

        if (!wieldedByPlayer) return;
        if (!IsActive()) return;

        light = GetLight();
        if (!light) return;

        light.SaveLightRewriteOriginalValues();
        light.radius = 0;
        hasModifiedLight = true;
        StartTemporaryLight();
    }

    public function OnHidden() {
        DestroyTemporaryLight();
    }

    public function Refresh() {
        var light: CLightComponent;
        var wasEnabled: bool;

        if (!IsActive()) {
            Restore();
            return;
        }

        light = GetLight();
        if (!light) return;

        light.SaveLightRewriteOriginalValues();

        wasEnabled = light.IsEnabled();
        if (wasEnabled) light.SetEnabled(false);

        ApplySettings(light);
        if (temporaryLight) {
            light.radius = 0;
            ConfigureTemporaryLight(temporaryLight);
        }

        if (wasEnabled) light.SetEnabled(true);

        hasModifiedLight = true;
    }

    protected function Restore() {
        var light: CLightComponent;

        if (temporaryLight) temporaryLight.SetEnabled(false);

        if (!hasModifiedLight) return;

        hasModifiedLight = false;

        light = GetLight();
        if (light) light.RestoreLightRewriteOriginalValues(false);

        if (parentEntity.IsEffectActive('light_on')) {
            parentEntity.DestroyEffect('light_on');
            parentEntity.PlayEffect('light_on');
        }
        if (parentEntity.IsEffectActive('light_on_bob')) {
            parentEntity.DestroyEffect('light_on_bob');
            parentEntity.PlayEffect('light_on_bob');
        }
    }

    protected function IsActive(): bool {
        var settings: SLightRewriteTorchLight = GetSettings();

        return theGame.GetLightRewriteSettings().isEnabled && settings.enabled;
    }

    protected function GetSettings(): SLightRewriteTorchLight {
        if (wieldedByPlayer) return theGame.GetLightRewriteSettings().playerTorch;

        return theGame.GetLightRewriteSettings().npcTorch;
    }

    protected function ApplySettings(light: CLightComponent) {
        var settings: SLightRewriteTorchLight = GetSettings();

        light.brightness = settings.brightness;
        light.radius = settings.radius;
        light.attenuation = settings.attenuation;
        if (settings.colour.has) light.color = settings.colour.value;
    }

    protected function GetLight(): CLightComponent;

    protected function SpawnTemporaryLight(): CLightComponent;

    protected function SpawnTemporaryLightEntity(templatePath: string): CEntity {
        var source: CLightComponent = GetLight();
        var template: CEntityTemplate;
        var entity: CEntity;

        template = (CEntityTemplate)LoadResource(templatePath, true);
        if (!template) {
            LogLightRewrite(
                "Temporary equippable light: failed to load template for " + parentEntity
            );
            return NULL;
        }

        entity = theGame.CreateEntity(
            template,
            source.GetWorldPosition(),
            source.GetWorldRotation()
        );
        if (!entity) {
            LogLightRewrite(
                "Temporary equippable light: failed to spawn entity for " + parentEntity
            );
            return NULL;
        }

        entity.CreateAttachment(
            parentEntity,
            ,
            source.GetLocalPosition(),
            source.GetLocalRotation()
        );

        return entity;
    }

    private function StartTemporaryLight() {
        DestroyTemporaryLight();

        temporaryLight = SpawnTemporaryLight();
        if (!temporaryLight) {
            LogLightRewrite("Temporary equippable light: no light component for " + parentEntity);
            return;
        }

        ConfigureTemporaryLight(temporaryLight);

        if (!isBob) parentEntity.AddTimer('RemoveLightRewriteTemporaryLight', 1.0, false);
    }

    private function ConfigureTemporaryLight(temporary: CLightComponent) {
        var identityRotation: EulerAngles;
        var source: CLightComponent = GetLight();

        temporary.SetEnabled(false);

        temporary.SetRotation(identityRotation);
        temporary.envColorGroup = ECG_FX_FireLight;
        temporary.shadowCastingMode = source.shadowCastingMode;
        temporary.shadowBlendFactor = source.shadowBlendFactor;
        temporary.shadowFadeDistance = source.shadowFadeDistance;
        temporary.shadowFadeRange = source.shadowFadeRange;
        temporary.lightFlickering = source.lightFlickering;
        ApplySettings(temporary);

        temporary.SetEnabled(true);
    }

    public function DestroyTemporaryLight() {
        parentEntity.RemoveTimer('RemoveLightRewriteTemporaryLight');

        if (temporaryLight) {
            temporaryLight.GetEntity().BreakAttachment();
            temporaryLight.GetEntity().Destroy();
            temporaryLight = NULL;
        }
    }
}
