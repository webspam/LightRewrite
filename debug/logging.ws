@wrapMethod(CLightRewriteSettings)
function FindParamsForEntity(entity : CGameplayEntity) : CLightRewriteSourceParams {
    var params : CLightRewriteSourceParams;
    
    params = wrappedMethod(entity);

    if (params) {
        LogLightRewrite("Found " + params.displayName + ": " + entity.ToString());
    }
    else {
        LogLightRewrite("Unknown light source entity: " + entity.ToString());
    }

    return params;
}
