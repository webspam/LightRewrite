class CLightRewriteMatchTarget {
    public var entity    : CGameplayEntity;
    public var entityFile: string;
    public var layerPath : string;

    public function Init(entity: CGameplayEntity) {
        var descriptor: string = entity.ToString();

        this.entity = entity;
        entityFile = StrAfterLast(descriptor, StrChar(92));
        layerPath = StrBeforeFirst(StrAfterFirst(descriptor, "\""), "\"");
    }
}
