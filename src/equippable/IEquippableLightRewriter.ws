abstract class IEquippableLightRewriter {
    protected var parentEntity    : W3LightSource;
    protected var wieldedByPlayer : bool;
    protected var hasModifiedLight: bool;
    protected var temporaryLight  : CEntity;
    protected var temporaryElapsed: float;

    public function Init(parentEntity: W3LightSource, wieldedByPlayer: bool) {
        this.parentEntity = parentEntity;
        this.wieldedByPlayer = wieldedByPlayer;
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

        if (wasEnabled) light.SetEnabled(true);

        hasModifiedLight = true;
    }

    public function SyncTemporaryLight(dt: float) {
        var light: CLightComponent;

        temporaryElapsed += dt;

        if (temporaryElapsed >= 1.0) {
            ItemWielded();
            DestroyTemporaryLight();
            return;
        }

        light = GetLight();
        if (!light || !temporaryLight) return;

        temporaryLight.TeleportWithRotation(light.GetWorldPosition(), light.GetWorldRotation());
    }

    protected function Restore() {
        var light: CLightComponent;

        DestroyTemporaryLight();

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

        template = (CEntityTemplate)LoadResource(templatePath, true);
        if (!template) {
            LogLightRewrite("Temporary equippable light: failed to load template for " + parentEntity);
            return NULL;
        }

        temporaryLight = theGame.CreateEntity(
            template,
            source.GetWorldPosition(),
            source.GetWorldRotation()
        );
        if (!temporaryLight) {
            LogLightRewrite("Temporary equippable light: failed to spawn entity for " + parentEntity);
        }

        return temporaryLight;
    }

    private function StartTemporaryLight() {
        var temporary: CLightComponent;

        DestroyTemporaryLight();

        temporary = SpawnTemporaryLight();
        if (!temporary) {
            LogLightRewrite("Temporary equippable light: no light component for " + parentEntity);
            DestroyTemporaryLight();
            return;
        }

        ConfigureTemporaryLight(temporary);

        temporaryElapsed = 0;
        parentEntity.AddTimer('SyncLightRewriteEquippable', 0, true);
    }

    private function ConfigureTemporaryLight(temporary: CLightComponent) {
        var identityRotation: EulerAngles;

        temporary.SetEnabled(false);

        temporary.SetRotation(identityRotation);
        temporary.envColorGroup = ECG_FX_FireLight;
        ApplySettings(temporary);

        temporary.SetEnabled(true);
    }

    private function DestroyTemporaryLight() {
        parentEntity.RemoveTimer('SyncLightRewriteEquippable');

        if (temporaryLight) {
            temporaryLight.Destroy();
            temporaryLight = NULL;
        }
    }
}
