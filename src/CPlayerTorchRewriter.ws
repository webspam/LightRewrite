class CPlayerTorchRewriter extends ITorchRewriter {
    private var placeholderLight: CEntity;
    private var temporaryElapsed: float;

    public function OnUsed() {
        var light: CPointLightComponent;

        if (!IsActive()) return;

        light = GetLight();
        if (!light) return;

        light.SaveLightRewriteOriginalValues();
        light.radius = 0;
        hasModifiedLight = true;
        SpawnTemporaryLight();
    }

    public function OnHidden() {
        DestroyTemporaryLight();
    }

    protected function Restore() {
        DestroyTemporaryLight();
        super.Restore();
    }

    public function SyncTemporaryLight(dt: float) {
        temporaryElapsed += dt;

        if (temporaryElapsed >= 1.0) {
            Wield();
            DestroyTemporaryLight();
            return;
        }

        if (placeholderLight) placeholderLight.Teleport(GetLight().GetWorldPosition());
    }

    protected function GetTorchSettings(): SLightRewriteTorchLight {
        return theGame.GetLightRewriteSettings().playerTorch;
    }

    private function SpawnTemporaryLight() {
        var template: CEntityTemplate;
        var tempComponent: CPointLightComponent;
        var torch: SLightRewriteTorchLight;

        DestroyTemporaryLight();

        template = (CEntityTemplate)LoadResource("dlc\lightrewrite\lights\pointlight_all_uses.w2ent", true);
        if (!template) {
            LogLightRewrite("Temporary torch light: failed to load template for " + parentEntity);
            return;
        }

        placeholderLight = theGame.CreateEntity(template, GetLight().GetWorldPosition());
        if (!placeholderLight) {
            LogLightRewrite("Temporary torch light: failed to spawn entity for " + parentEntity);
            return;
        }

        tempComponent = (CPointLightComponent)placeholderLight.GetComponent('CPointLightComponent0');
        if (!tempComponent) {
            LogLightRewrite("Temporary torch light: missing point light component for " + parentEntity);
        }
        else {
            torch = GetTorchSettings();
            tempComponent.SetEnabled(false);

            tempComponent.brightness = torch.brightness;
            tempComponent.radius = torch.radius;
            tempComponent.attenuation = torch.attenuation;
            if (torch.colour.has) tempComponent.color = torch.colour.value;

            tempComponent.SetEnabled(true);
        }

        temporaryElapsed = 0;
        parentEntity.AddTimer('SyncLightRewriteTorch', 0, true);
    }

    private function DestroyTemporaryLight() {
        parentEntity.RemoveTimer('SyncLightRewriteTorch');

        if (placeholderLight) {
            placeholderLight.Destroy();
            placeholderLight = NULL;
        }
    }
}
