/**
 * Undo stack for light-source parameter edits.
 *
 * Each entry snapshots every entity in the edit scope before the edit lands, so
 * Undo can restore them wholesale. Edits are bracketed with StartEdit/Commit:
 * discrete edits do both in one call; analog holds snapshot at BeginAdjust and
 * commit at EndAdjust once the whole drag is known.
 */
class LRDebug_EditHistory {
    private var entries: array<LRDebug_EditEntry>;
    private var pending: LRDebug_EditEntry;
    private const var MAX_ENTRIES: int;  default MAX_ENTRIES = 100;

    public function StartEdit(entities: array<CGameplayEntity>, label: string) {
        var i, count: int;

        pending = new LRDebug_EditEntry in this;
        pending.label = label;

        count = entities.Size();
        for (i = 0; i < count; i += 1) {
            if (!entities[i]) continue;

            pending.entities.PushBack(entities[i]);
            pending.snapshots.PushBack(SnapshotParams(entities[i]));
        }
    }

    /** Drop the snapshot when nothing changed, so a no-op hold leaves no undo step */
    public function Commit(keep: bool) {
        if (!pending) return;

        if (keep) {
            if (entries.Size() >= MAX_ENTRIES) entries.Erase(0);
            entries.PushBack(pending);
        }

        pending = NULL;
    }

    public function Undo(): LRDebug_EditEntry {
        var record: LRDebug_EditEntry;

        if (entries.Size() == 0) return NULL;

        record = entries[entries.Size() - 1];
        entries.PopBack();
        RestoreEntry(record);
        return record;
    }

    /** A reset clears the light's baseline too, so restoring its old snapshot would break export */
    public function ForgetEntity(entity: CGameplayEntity) {
        var i: int;

        if (pending) {
            pending.Remove(entity);
            if (pending.entities.Size() == 0) pending = NULL;
        }

        for (i = entries.Size() - 1; i >= 0; i -= 1) {
            entries[i].Remove(entity);
            if (entries[i].entities.Size() == 0) entries.Erase(i);
        }
    }

    /** Falls back to effective params when unedited, so undoing a no-op leaves no debug params behind */
    private function SnapshotParams(entity: CGameplayEntity): CLightRewriteSourceParams {
        var rewriter: ILightSourceRewriter;
        var src: CLightRewriteSourceParams;

        rewriter = entity.LRDebug_GetOrCreateRewriter();
        src = entity.lrDebugParams;
        if (!src) src = rewriter.LRDebug_GetEffectiveParams();
        return CloneParams(src, this);
    }

    private function RestoreEntry(record: LRDebug_EditEntry) {
        var entity: CGameplayEntity;
        var rewriter: ILightSourceRewriter;
        var i, count: int;

        count = record.entities.Size();
        for (i = 0; i < count; i += 1) {
            entity = record.entities[i];
            if (!entity) continue;

            rewriter = entity.LRDebug_GetOrCreateRewriter();
            entity.lrDebugParams = CloneParams(record.snapshots[i], entity);
            rewriter.LRDebug_SetMenuOverrideParams(entity.lrDebugParams);
            rewriter.RestoreOriginalState();
            rewriter.RewriteLight();
        }
    }

    /** Decouple the stored snapshot from the live params so later edits can't mutate it */
    private function CloneParams(
        src: CLightRewriteSourceParams,
        owner: IScriptable
    ): CLightRewriteSourceParams {
        var copy: CLightRewriteSourceParams;

        copy = new CLightRewriteSourceParams in owner;
        src.ApplyTo(copy);
        return copy;
    }
}

class LRDebug_EditEntry {
    public var entities : array<CGameplayEntity>;
    public var snapshots: array<CLightRewriteSourceParams>;
    public var label    : string;

    public function Remove(entity: CGameplayEntity) {
        var idx: int = entities.FindFirst(entity);

        if (idx == -1) return;

        entities.Erase(idx);
        snapshots.Erase(idx);
    }
}
