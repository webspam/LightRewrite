/**
 * Base for the overlay's world-marker managers.
 *
 * Each pool draws its markers onto the shared oneliner HUD module, so every marker needs a
 * flash id unique across all pools.
 */
class LRDebug_MarkerPool {
    protected var markers: array<LRDebug_WorldMarker>;
    private var lastId   : int;

    protected function InitPool(idBase: int) {
        lastId = idBase;
    }

    protected function AddMarker(text: string, fontSize: int, colour: string) {
        var marker: LRDebug_WorldMarker;

        lastId += 1;
        marker = new LRDebug_WorldMarker in this;
        marker.Init(text, fontSize, colour, lastId);

        markers.PushBack(marker);
    }

    public function Hide() {
        var i, count: int;

        count = markers.Size();
        for (i = 0; i < count; i += 1) {
            markers[i].Hide();
        }
    }
}
