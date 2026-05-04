@wrapMethod(CLightRewriteSettings)
function FindParamsForEntity(entity : CGameplayEntity) : CLightRewriteSourceParams {
    var params : CLightRewriteSourceParams;
    var components : array<CComponent>;
    var pointLights, spotLights : int;

    params = wrappedMethod(entity);

    if (params) {
        LogLightRewrite("Found " + params.displayName + ": " + entity.ToString());
    }
    else {
        components = entity.GetComponentsByClassName('CPointLightComponent');
        pointLights = components.Size();

        components.Clear();
        components = entity.GetComponentsByClassName('CSpotLightComponent');
        spotLights = components.Size();

        // Ignore entities that have no lights
        if (pointLights > 0 || spotLights > 0) {
            LogLightRewrite("Unknown light source entity: " + entity.ToString());
        }
    }

    return params;
}
