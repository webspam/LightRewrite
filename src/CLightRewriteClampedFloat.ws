class CLightRewriteClampedFloat {
    public var value: SLightRewriteOptionalFloat;
    public var min  : SLightRewriteOptionalFloat;
    public var max  : SLightRewriteOptionalFloat;

    public function SetValue(newValue: float) {
        value.has = true;
        value.value = newValue;
        min.has = false;
        max.has = false;
    }

    public function SetClampedValue(newValue: float) {
        var clamped: float = Clamp(newValue);

        SetValue(clamped);
    }

    public function MergeFrom(higherWeight: CLightRewriteClampedFloat) {
        if (higherWeight.value.has) {
            SetValue(higherWeight.value.value);
            return;
        }

        if (value.has) {
            SetValue(higherWeight.Resolve(value.value));
            return;
        }

        if (higherWeight.min.has && max.has && max.value < higherWeight.min.value) max.has = false;
        if (higherWeight.max.has && min.has && min.value > higherWeight.max.value) min.has = false;

        if (higherWeight.min.has) min = higherWeight.min;
        if (higherWeight.max.has) max = higherWeight.max;
    }

    public function Resolve(baseGameValue: float): float {
        if (value.has) return value.value;
        return Clamp(baseGameValue);
    }

    private function Clamp(input: float): float {
        var clamped: float = input;

        if (min.has && clamped < min.value) clamped = min.value;
        if (max.has && clamped > max.value) clamped = max.value;
        return clamped;
    }
}
