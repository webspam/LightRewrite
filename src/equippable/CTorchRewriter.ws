class CTorchRewriter extends IEquippableLightRewriter {
    protected function GetLight(): CLightComponent {
        return (CLightComponent)parentEntity.GetComponent('CPointLightComponent0');
    }

    protected function SpawnTemporaryLight(): CLightComponent {
        var entity: CEntity = SpawnTemporaryLightEntity("dlc\lightrewrite\lights\pointlight_all_uses.w2ent");

        if (!entity) return NULL;

        return (CLightComponent)entity.GetComponent('CPointLightComponent0');
    }
}
