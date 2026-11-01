class LRDebug_LookPointResolver {
    private const var SEARCH_RADIUS: float;  default SEARCH_RADIUS = 1.0;
    private const var SEARCH_LIMIT : int;    default SEARCH_LIMIT = 32;

    public function Resolve(base: Vector): Vector {
        var entity: CGameplayEntity = FindLightEntity(base);
        var lookPoint: Vector = base;

        if (entity) FindFirstEffectSlot(entity, lookPoint);
        return lookPoint;
    }

    private function FindLightEntity(base: Vector): CGameplayEntity {
        var entities: array<CGameplayEntity>;
        var closest: CGameplayEntity;
        var distanceSquared, closestDistanceSquared: float;
        var i, count: int;

        FindGameplayEntitiesInSphere(
            entities,
            base,
            SEARCH_RADIUS,
            SEARCH_LIMIT,
            ,
            FLAG_ExcludePlayer
        );

        count = entities.Size();
        for (i = 0; i < count; i += 1) {
            if (!entities[i] || !entities[i].HasRewritableLight()) continue;

            distanceSquared = VecDistanceSquared(entities[i].GetWorldPosition(), base);
            if (closest && distanceSquared >= closestDistanceSquared) continue;

            closest = entities[i];
            closestDistanceSquared = distanceSquared;
        }
        return closest;
    }

    private function FindFirstEffectSlot(entity: CEntity, out position: Vector): bool {
        var slots: array<name> = EffectSlotNames();
        var slotMatrix: Matrix;
        var i, count: int;

        count = slots.Size();
        for (i = 0; i < count; i += 1) {
            if (!entity.HasSlot(slots[i])) continue;
            if (!entity.CalcEntitySlotMatrix(slots[i], slotMatrix)) continue;

            position = MatrixGetTranslation(slotMatrix);
            return true;
        }
        return false;
    }

    private function EffectSlotNames(): array<name> {
        var slots: array<name>;

        slots.PushBack('fire');
        slots.PushBack('fire1');
        slots.PushBack('fire2');
        slots.PushBack('fx');
        slots.PushBack('fx1');
        slots.PushBack('fx2');
        slots.PushBack('candle01');
        slots.PushBack('candle02');
        slots.PushBack('light_point');
        return slots;
    }
}
