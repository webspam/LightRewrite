/*
 * Mouse wheel up/down to cycle weather.
 */

@addField(CR4Player) public var weatherCycler: CWeatherCycler;

@wrapMethod(CR4Player)
function OnSpawned(spawnData: SEntitySpawnData) {
    wrappedMethod(spawnData);

    weatherCycler = new CWeatherCycler in this;
    weatherCycler.Init();
}

class CWeatherCycler {
    private const var BLEND_TIME           : float;  default BLEND_TIME = 0.0;
    private const var NOTIFICATION_DURATION: float;  default NOTIFICATION_DURATION = 3000.0;

    public function Init() {
        theInput.RegisterListener(this, 'OnCycleWeather', 'WeatherCycler_Cycle');
    }

    public function OnCycleWeather(action: SInputAction): bool {
        if (!action.value) return false;

        Cycle(-((int)SignF(action.value)));
        return true;
    }

    private function Cycle(direction: int) {
        var weatherNames: array<name>;
        var targetWeather: name;
        var index, count: int;

        GetWeatherNames(weatherNames);
        count = weatherNames.Size();
        if (count == 0) {
            Notify("Weather: none available");
            return;
        }

        index = weatherNames.FindFirst(GetWeatherConditionName());
        if (index < 0 && direction < 0) index = 0;

        targetWeather = weatherNames[(index + direction + count) % count];
        if (!RequestWeatherChangeTo(targetWeather, BLEND_TIME, true)) {
            Notify("Weather change failed: " + NameToString(targetWeather));
            return;
        }

        Notify("Weather: " + NameToString(targetWeather));
    }

    private function Notify(text: string) {
        theGame.GetGuiManager().ShowNotification(text, NOTIFICATION_DURATION);
    }
}
