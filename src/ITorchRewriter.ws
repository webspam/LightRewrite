abstract class ITorchRewriter {
    protected var parentEntity: W3LightSource;

    public function Init(parentEntity: W3LightSource) {
        this.parentEntity = parentEntity;
    }

    public function Wield() {
        parentEntity.AddTag(theGame.lightRewrite.TAG_IS_WIELDED);

        Refresh();
    }

    public function OnUsed() {}

    public function Refresh() {
        var torch: SLightRewriteTorchLight;
        var light: CPointLightComponent;
        var wasEnabled: bool;

        var settings: CLightRewriteSettings = theGame.GetLightRewriteSettings();

        light = GetLight();
        if (!light) return;

        light.SaveLightRewriteOriginalValues();

        torch = GetTorchSettings();

        if (!settings.isEnabled || !torch.enabled) {
            light.RestoreLightRewriteOriginalValues(false);
            if (parentEntity.IsEffectActive('light_on')) {
                parentEntity.DestroyEffect('light_on');
                parentEntity.PlayEffect('light_on');
            }
            if (parentEntity.IsEffectActive('light_on_bob')) {
                parentEntity.DestroyEffect('light_on_bob');
                parentEntity.PlayEffect('light_on_bob');
            }
            return;
        }

        wasEnabled = light.IsEnabled();
        if (wasEnabled) light.SetEnabled(false);

        light.brightness = torch.brightness;
        light.radius = torch.radius;
        light.attenuation = torch.attenuation;
        if (torch.colour.has) light.color = torch.colour.value;

        if (wasEnabled) light.SetEnabled(true);
    }

    protected function GetTorchSettings(): SLightRewriteTorchLight;

    protected function GetLight(): CPointLightComponent {
        return (CPointLightComponent)parentEntity.GetComponent('CPointLightComponent0');
    }
}
