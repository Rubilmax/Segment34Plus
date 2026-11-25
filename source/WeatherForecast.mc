import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

const WEATHER_HAZARD_WINDOW_WIDTH = 3;

// Positive values are canonical Garmin conditions; zero is standard, -1 is missing.
function weatherHazardFamily(condition as Number?) as Number {
    if (condition == null || condition < 0 || condition >= 53) { return -1; }
    switch (condition) {
        case 3: case 11: case 13: case 14: case 15: case 24: case 25:
        case 26: case 27: case 31: case 45: return 3;
        case 6: case 12: case 28: return 6;
        case 4: case 16: case 17: case 43: case 46: case 48: return 4;
        case 7: case 18: case 19: case 21: case 44: case 47: return 21;
        case 34: case 49: case 50: case 51: return 34;
        case 5: case 8: case 10: case 30: case 32: case 33: case 35:
        case 36: case 37: case 38: case 41: case 42: return condition;
    }
    return 0;
}

// Garmin and older snapshots use [UTC timestamp, condition] rows. Compact snapshots
// keep only the condition column and an hourly start time. Both yield the same windows.
// Store consecutive [family, start, end] triples without one object per window.
function weatherBuildHazardWindows(hours as Array, now as Number, start as Number?) as Array {
    var windows = [];
    var active = -1;
    var previousTime = null as Number?;
    var standardHours = 0;
    for (var i = 0; i < hours.size(); i++) {
        var time = start == null ? (hours[i] as Array)[0] as Number? : start + i * 3600;
        if (time == null) {
            active = -1;
            previousTime = null;
            continue;
        }
        if (time + 3600 <= now) { continue; }
        if (previousTime == null || time != previousTime + 3600) {
            active = -1;
            standardHours = 0;
        }
        previousTime = time;
        var condition = start == null ? (hours[i] as Array)[1] as Number? : weatherProviderGetArrayNumber(hours, i);
        var family = weatherHazardFamily(condition);
        if (family > 0) {
            if (active >= 0 && windows[active] == family && standardHours <= 1) {
                windows[active + 2] = time + 3600;
            } else {
                active = windows.size();
                windows.add(family);
                windows.add(time);
                windows.add(time + 3600);
            }
            standardHours = 0;
        } else if (family == 0) {
            standardHours++;
            if (standardHours > 1) { active = -1; }
        } else {
            active = -1;
            standardHours = 0;
        }
    }
    return windows;
}

function weatherHazardDayColor(start as Number, now as Number, offset as Number) as Graphics.ColorType {
    var day = (weatherProviderGetLocalDayStart(start, offset) - weatherProviderGetLocalDayStart(now, offset)) / 86400;
    if (day <= 0) { return 0xFFFFFF; }
    if (day == 1) { return 0xFFD6C4; }
    if (day == 2) { return 0xFFB494; }
    return 0xFF9161;
}

function weatherFormatHazardHours(start as Number, end as Number, offset as Number) as String {
    return weatherProviderGetForecastHour(start, offset).format("%d") + "-"
        + weatherProviderGetForecastHour(end, offset).format("%d") + "H";
}

function weatherFormatDailyFeelsLike(range as Array?, now as Number, offset as Number, unit as String) as String {
    if (range == null || range.size() < 3 || range[0] == null || range[1] == null || range[2] == null) { return ""; }
    if (range[2] != weatherProviderGetLocalDayStart(now, offset)) { return ""; }
    var low = (range[0] as Float).toFloat();
    var high = (range[1] as Float).toFloat();
    if (low > high) { return ""; }
    if (unit.equals("F")) {
        low = low * 1.8f + 32;
        high = high * 1.8f + 32;
    }
    return "\uE000" + Math.round(low).format("%d") + "-" + Math.round(high).format("%d") + "\u00B0";
}
