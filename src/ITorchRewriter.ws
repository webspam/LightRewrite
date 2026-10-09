abstract class ITorchRewriter {
    protected var parentEntity    : W3LightSource;
    protected var hasModifiedLight: bool;

    public function Init(parentEntity: W3LightSource) {
        this.parentEntity = parentEntity;
    }

    public function Wield() {
        parentEntity.AddTag(theGame.lightRewrite.TAG_IS_WIELDED);

        Refresh();
    }

    public function OnUsed() {}

    public function OnHidden() {}

    public function Refresh() {
        var torch: SLightRewriteTorchLight;
        var light: CPointLightComponent;
        var wasEnabled: bool;

        if (!IsActive()) {
            Restore();
            return;
        }

        light = GetLight();
        if (!light) return;

        light.SaveLightRewriteOriginalValues();

        torch = GetTorchSettings();

        wasEnabled = light.IsEnabled();
        if (wasEnabled) light.SetEnabled(false);

        light.brightness = torch.brightness;
        light.radius = torch.radius;
        light.attenuation = torch.attenuation;
        if (torch.colour.has) light.color = torch.colour.value;

        if (wasEnabled) light.SetEnabled(true);

        hasModifiedLight = true;
    }

    protected function Restore() {
        var light: CPointLightComponent;

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
        var torch: SLightRewriteTorchLight = GetTorchSettings();

        return theGame.GetLightRewriteSettings().isEnabled && torch.enabled;
    }

    protected function GetTorchSettings(): SLightRewriteTorchLight;

    protected function GetLight(): CPointLightComponent {
        return (CPointLightComponent)parentEntity.GetComponent('CPointLightComponent0');
    }
}
