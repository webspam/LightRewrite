class CLanternRewriter extends IEquippableLightRewriter {
    protected function GetLight(): CLightComponent {
        return GetSpotLight();
    }

    protected function ApplySettings(light: CLightComponent) {
        super.ApplySettings(light);

        light.envColorGroup = ECG_FX_FireLight;
    }

    protected function SpawnTemporaryLight(): CLightComponent {
        var source: CSpotLightComponent = GetSpotLight();
        var entity: CEntity = SpawnTemporaryLightEntity("dlc\lightrewrite\lights\spotlight_all_uses.w2ent");
        var temporary: CSpotLightComponent;

        if (!entity) return NULL;

        temporary = (CSpotLightComponent)entity.GetComponent('CSpotLightComponent0');
        if (!temporary) return NULL;

        temporary.innerAngle = source.innerAngle;
        temporary.outerAngle = source.outerAngle;
        temporary.softness = source.softness;

        return temporary;
    }

    private function GetSpotLight(): CSpotLightComponent {
        return (CSpotLightComponent)parentEntity.GetComponent('CSpotLightComponent0');
    }
}
