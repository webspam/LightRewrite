/** Analogue clock face using oneliners. */
class LRDebug_ClockFace {
    // 0x40006200
    private const var BASE_ID     : int;    default BASE_ID = 1073766912;
    private const var TICKS       : int;    default TICKS = 12;
    private const var CENTER_X    : float;  default CENTER_X = 0.5;
    private const var CENTER_Y    : float;  default CENTER_Y = 0.7;
    private const var RADIUS_RATIO: float;  default RADIUS_RATIO = 0.05;

    private const var HOUR_HAND_LENGTH  : float;  default HOUR_HAND_LENGTH = 0.5;
    private const var MINUTE_HAND_LENGTH: float;  default MINUTE_HAND_LENGTH = 0.85;

    private const var HAND_BASE_DEGREES: float;  default HAND_BASE_DEGREES = 0.0;
    private const var HAND_SCALE_PER_PX: float;  default HAND_SCALE_PER_PX = 4.5;
    private const var NUDGE_HANDS_UP   : float;  default NUDGE_HANDS_UP = 155;
    private const var HOUR_THICKNESS   : float;  default HOUR_THICKNESS = 220.0;
    private const var MINUTE_THICKNESS : float;  default MINUTE_THICKNESS = 130.0;

    private var ticks     : array<LRDebug_WarpLabel>;
    private var hourHand  : LRDebug_WarpLabel;
    private var minuteHand: LRDebug_WarpLabel;
    private var hub       : LRDebug_WarpLabel;
    private var digital   : LRDebug_ScreenLabel;

    private var hud: CR4ScriptedHud;

    public function Init() {
        var i: int;
        var tick: LRDebug_WarpLabel;

        hud = (CR4ScriptedHud)theGame.GetHud();

        for (i = 0; i < TICKS; i += 1) {
            tick = new LRDebug_WarpLabel in this;
            tick.Init(BASE_ID + i, TickGlyph(i));
            ticks.PushBack(tick);
        }

        hourHand = new LRDebug_WarpLabel in this;
        hourHand.Init(BASE_ID + 20, HandGlyph("#c96944"));

        minuteHand = new LRDebug_WarpLabel in this;
        minuteHand.Init(BASE_ID + 21, HandGlyph("#7d6d97"));

        hub = new LRDebug_WarpLabel in this;
        hub.Init(BASE_ID + 22, "<font size='20' color='#46fbc1'>&#8226;</font>");

        digital = new LRDebug_ScreenLabel in this;
        digital.Init(BASE_ID + 23, CENTER_X, CENTER_Y + RADIUS_RATIO + 0.025);
    }

    public function Show(hours: float) {
        Layout(hours);
    }

    public function Hide() {
        var i: int;

        for (i = 0; i < ticks.Size(); i += 1) ticks[i].Hide();

        hourHand.Hide();
        minuteHand.Hide();
        hub.Hide();
        digital.Hide();
    }

    private function Layout(hours: float) {
        var center, edge: Vector;
        var radiusPx, hourAngle, minuteAngle: float;
        var i: int;

        center = hud.GetScaleformPoint(CENTER_X, CENTER_Y);
        edge = hud.GetScaleformPoint(CENTER_X, CENTER_Y - RADIUS_RATIO);
        radiusPx = center.Y - edge.Y;

        for (i = 0; i < TICKS; i += 1) {
            PlaceTick(i, center, radiusPx);
        }

        hourAngle = LRDebug_FloatOverflow(hours, 12.0) * 30.0;
        minuteAngle = LRDebug_FloatOverflow(hours, 1.0) * 360.0;

        WarpHand(hourHand, center, radiusPx * HOUR_HAND_LENGTH, hourAngle, HOUR_THICKNESS);
        WarpHand(minuteHand, center, radiusPx * MINUTE_HAND_LENGTH, minuteAngle, MINUTE_THICKNESS);

        hub.Place(center.X, center.Y);
        digital.SetText(DigitalText(hours));
        digital.Show();
    }

    private function PlaceTick(index: int, center: Vector, radiusPx: float) {
        var theta: float = (float)index * 30.0;
        var px: float = center.X + radiusPx * SinDeg(theta);
        var py: float = center.Y - radiusPx * CosDeg(theta);

        ticks[index].Place(px, py);
    }

    private function WarpHand(
        hand: LRDebug_WarpLabel,
        center: Vector,
        lengthPx: float,
        angle: float,
        thickness: float
    ) {
        hand.Warp(
            center.X,
            center.Y - (NUDGE_HANDS_UP * RADIUS_RATIO),
            angle + HAND_BASE_DEGREES,
            thickness,
            lengthPx * HAND_SCALE_PER_PX
        );
    }

    private function TickGlyph(index: int): string {
        var label: string;

        switch (index) {
            case 0:   label = "12";       break;
            case 3:   label = "3";        break;
            case 6:   label = "6";        break;
            case 9:   label = "9";        break;
            default:  label = "&#8226;";
        }

        return "<font size='16' color='#46fbc1'>" + label + "</font>";
    }

    private function HandGlyph(color: string): string {
        return "<font size='22' color='" + color + "'>|</font>";
    }

    private function DigitalText(hours: float): string {
        var h: int = (int)LRDebug_FloatOverflow(hours, 24.0);
        var m: int = (int)(LRDebug_FloatOverflow(hours, 1.0) * 60.0);

        return "<font size='16' color='#46fbc1'>" + Pad2(h) + ":" + Pad2(m) + "</font>";
    }

    private function CosDeg(deg: float): float {
        var v: Vector = VecFromHeading(deg);
        return v.Y;
    }

    private function SinDeg(deg: float): float {
        var v: Vector = VecFromHeading(deg);
        return -v.X;
    }

    private function Pad2(value: int): string {
        if (value < 10) return "0" + value;
        return value;
    }
}
