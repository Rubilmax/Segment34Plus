import Toybox.Lang;
import Toybox.Test;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Time;

(:test)
function hazardFamilies(logger as Test.Logger) as Boolean {
    var standard = [0, 1, 2, 9, 20, 22, 23, 29, 39, 40, 52];
    for (var i = 0; i < standard.size(); i++) { Test.assertEqual(weatherHazardFamily(standard[i]), 0); }
    var hazards = [3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 21, 24, 25, 26, 27, 28, 30, 31, 32, 33, 34, 35, 36, 37, 38, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51];
    for (var j = 0; j < hazards.size(); j++) { Test.assert(weatherHazardFamily(hazards[j]) > 0); }
    Test.assertEqual(weatherHazardFamily(null), -1);
    Test.assertEqual(weatherHazardFamily(53), -1);
    Test.assertEqual(weatherHazardFamily(99), -1);
    Test.assertEqual(weatherProviderWmoToGarminCondition(97), 6);
    return true;
}

(:test)
function hazardWindowsBridgeOneHour(logger as Test.Logger) as Boolean {
    var windows = weatherBuildHazardWindows([[0, 14], [3600, 3], [7200, 0], [10800, 15], [14400, 6], [18000, 12]], 0);
    Test.assertEqual(windows.size(), 2);
    Test.assertEqual(windows[0][0], 3);
    Test.assertEqual(windows[0][1], 0);
    Test.assertEqual(windows[0][2], 14400);
    Test.assertEqual(windows[1][0], 6);
    Test.assertEqual(windows[1][1], 14400);
    Test.assertEqual(windows[1][2], 21600);
    Test.assertEqual(weatherBuildHazardWindows([[0, 3], [3600, 0], [7200, 20], [10800, 3]], 0).size(), 2);
    return true;
}

(:test)
function hazardWindowsRespectMissingData(logger as Test.Logger) as Boolean {
    Test.assertEqual(weatherBuildHazardWindows([[0, 3], [3600, null], [7200, 3]], 0).size(), 2);
    Test.assertEqual(weatherBuildHazardWindows([[0, 3], [3600, 53], [7200, 3]], 0).size(), 2);
    Test.assertEqual(weatherBuildHazardWindows([[0, 3], [null, 0], [7200, 3]], 0).size(), 2);
    Test.assertEqual(weatherBuildHazardWindows([[0, 3], [7200, 3]], 0).size(), 2);
    var current = weatherBuildHazardWindows([[0, 3], [3600, 3], [7200, 3]], 5400);
    Test.assertEqual(current[0][1], 3600);
    Test.assertEqual(current[0][2], 10800);
    Test.assertEqual(weatherBuildHazardWindows([[0, 0], [3600, 20]], 0).size(), 0);
    Test.assertEqual(weatherBuildHazardWindows([], 0).size(), 0);
    return true;
}

(:test)
function hazardHoursAndColors(logger as Test.Logger) as Boolean {
    Test.assertEqual(weatherFormatHazardHours(22 * 3600, 27 * 3600, 0), "22-3H");
    Test.assertEqual(weatherFormatHazardHours(0, 3600, 19800), "5-6H");
    Test.assertEqual(weatherHazardDayColor(0, 0, 0), 0xFFFFFF);
    Test.assertEqual(weatherHazardDayColor(86400, 0, 0), 0xFFD6C4);
    Test.assertEqual(weatherHazardDayColor(172800, 0, 0), 0xFFB494);
    Test.assertEqual(weatherHazardDayColor(259200, 0, 0), 0xFF9161);
    Test.assertEqual(weatherHazardDayColor(86400, 86400, 0), 0xFFFFFF);
    Test.assertEqual(weatherHazardDayColor(22 * 3600, 21 * 3600, 7200), 0xFFD6C4);
    Test.assertEqual(weatherHazardDayColor(86400, 0, -18000), 0xFFD6C4);
    return true;
}

(:test)
function dailyFeelsLikeRange(logger as Test.Logger) as Boolean {
    Test.assertEqual(weatherFormatDailyFeelsLike([7.4f, 16.6f, 0], 3600, 0, "C"), "\uE0007-17\u00B0");
    Test.assertEqual(weatherFormatDailyFeelsLike([0.0f, 10.0f, 0], 3600, 0, "F"), "\uE00032-50\u00B0");
    Test.assertEqual(weatherFormatDailyFeelsLike([-7.6f, -1.6f, 0], 3600, 0, "C"), "\uE000-8--2\u00B0");
    Test.assertEqual(weatherFormatDailyFeelsLike([0.0f, 10.0f, 0], 86400, 0, "C"), "");
    Test.assertEqual(weatherFormatDailyFeelsLike([0.0f, 10.0f, 86400], 22 * 3600, 7200, "C"), "\uE0000-10\u00B0");
    Test.assertEqual(weatherFormatDailyFeelsLike([null, 10.0f, 0], 0, 0, "C"), "");
    Test.assertEqual(weatherFormatDailyFeelsLike([10.0f, 0.0f, 0], 0, 0, "C"), "");
    Test.assertEqual(weatherFormatDailyFeelsLike(null, 0, 0, "C"), "");
    return true;
}

(:test)
function weatherMemoryAndCompatibility(logger as Test.Logger) as Boolean {
    Test.assertEqual(weatherProviderForecastLimitForMemory(32768, false), 36);
    Test.assertEqual(weatherProviderForecastLimitForMemory(65536, true), 36);
    Test.assertEqual(weatherProviderForecastLimitForMemory(65536, false), 72);
    var legacy = weatherProviderDecodeBackgroundCurrentEntry([3, 12, 10.0f, 80, 50, 180, 2.0f, 15, 8, 1.0f]);
    Test.assert(legacy.get("dailyFeelsLike") == null);
    legacy["dailyFeelsLike"] = [2.0f, 14.0f, 0];
    var decoded = weatherProviderDecodeBackgroundCurrentEntry(weatherProviderEncodeBackgroundCurrentEntry(legacy));
    Test.assertEqual((decoded.get("dailyFeelsLike") as Array)[1], 14.0f);
    var columns = [0, 12, 8, [3, 3, 0, 0, 6, 6, 6, 6, 4, 4, 4, 4], [], [1, 2, 3, 4, 5, 6, 7, 8], [], [], [], [], []];
    var limited = weatherProviderLimitHourlyColumns(columns, 4);
    Test.assertEqual(limited[1], 4);
    Test.assertEqual(limited[2], 4);
    Test.assertEqual((limited[3] as Array).size(), 4);
    Test.assertEqual((limited[5] as Array).size(), 4);
    Test.assertEqual(columns[1], 12);
    Test.assertEqual(weatherProviderLimitHourlyColumns(columns, 0).size(), 0);
    return true;
}

(:test)
function weatherCompactColumns(logger as Test.Logger) as Boolean {
    var hourly = {"weather_code" => [61, 63, 0, 65], "temperature_2m" => [1.0f, 2.0f, 3.0f, 4.0f]};
    var columns = weatherProviderBuildHourlyColumns(hourly, [0, 3600, 7200, 10800], 0, 72);
    Test.assertEqual(columns[1], 4);
    Test.assertEqual((columns[4] as Array).size(), 0);
    Test.assertEqual((columns[3] as Array)[0], 14);
    Test.assertEqual((columns[5] as Array)[3], 4.0f);
    var gap = weatherProviderBuildHourlyColumns(hourly, [0, 3600, 10800, 14400], 0, 72);
    Test.assert((gap[3] as Array)[2] == null);
    Test.assertEqual((gap[3] as Array)[3], 0);
    Test.assertEqual((gap[3] as Array)[4], 15);
    return true;
}

(:test)
function weatherSnapshotDailyRangeAndFallback(logger as Test.Logger) as Boolean {
    var now = 22 * 3600 + 1800;
    var data = {
        "utc_offset_seconds" => 7200,
        "timezone" => "Europe/Paris",
        "current" => {"time" => now, "weather_code" => 61, "apparent_temperature" => 20.0f},
        "hourly" => {"time" => [22 * 3600, 23 * 3600, 24 * 3600], "weather_code" => [61, 63, 95]},
        "daily" => {
            "time" => [-7200, 79200, 165600],
            "apparent_temperature_min" => [-5.0f, -1.0f, 2.0f],
            "apparent_temperature_max" => [10.0f, 8.0f, 14.0f]
        }
    };
    var snapshot = weatherProviderBuildSnapshotFromOpenMeteoResponse(data, [48.0f, 2.0f], now) as Dictionary;
    var range = (snapshot.get("current") as Dictionary).get("dailyFeelsLike") as Array;
    Test.assertEqual(range[0], -1.0f);
    Test.assertEqual(range[1], 8.0f);
    Test.assertEqual(range[2], 86400);
    Test.assertEqual(weatherFormatDailyFeelsLike(range, now, 7200, "C"), "\uE000-1-8\u00B0");
    var columns = snapshot.get("hourlyColumns") as Array;
    Test.assertEqual(columns[0], 22 * 3600);
    Test.assertEqual(columns[1], 3);
    var encoded = weatherProviderEncodeBackgroundSnapshotWithHourlyLimit(snapshot, 1) as Dictionary;
    var decoded = weatherProviderDecodeBackgroundSnapshot(encoded) as Dictionary;
    Test.assertEqual((decoded.get("hourlyColumns") as Array)[1], 1);
    Test.assertEqual(((decoded.get("current") as Dictionary).get("dailyFeelsLike") as Array)[1], 8.0f);
    var currentOnly = weatherProviderDecodeBackgroundSnapshot(weatherProviderEncodeBackgroundSnapshotWithHourlyLimit(snapshot, 0)) as Dictionary;
    Test.assertEqual((currentOnly.get("hourly") as Array).size(), 0);
    Test.assertEqual(((currentOnly.get("current") as Dictionary).get("dailyFeelsLike") as Array)[0], -1.0f);
    return true;
}

(:test)
function weatherViewRendersForecast(logger as Test.Logger) as Boolean {
    var savedSnapshot = Application.Storage.getValue(WEATHER_SNAPSHOT_KEY);
    var savedProperties = {};
    var properties = {"weatherProvider" => 1, "weatherLine1Shows" => 78, "weatherLine2Shows" => 79, "tempUnit" => 2,
        "sunriseFieldShows" => -2, "sunsetFieldShows" => -2};
    var now = Time.now().value();
    try {
        var keys = properties.keys();
        for (var i = 0; i < keys.size(); i++) {
            savedProperties[keys[i]] = Application.Properties.getValue(keys[i] as String);
            Application.Properties.setValue(keys[i] as String, properties[keys[i]]);
        }
        weatherProviderStoreSnapshot({
            "version" => WEATHER_SNAPSHOT_VERSION, "provider" => WEATHER_PROVIDER_OPEN_METEO_NAME,
            "fetchedAt" => now, "location" => [48.0f, 2.0f], "utcOffsetSeconds" => 7200,
            "current" => {"condition" => 3, "windBearing" => 180, "windSpeed" => 12.0f,
                "uvIndex" => 12.0f, "relativeHumidity" => 100,
                "dailyFeelsLike" => [-40.0f, 40.0f, weatherProviderGetLocalDayStart(now, 7200)]},
            "hourlyColumns" => [now - now % 3600, 3, 0, [3, 3, 6], [], [], [], [], [], [], []]
        });
        var view = new Segment34View();
        var settings = System.getDeviceSettings();
        var options = {:width => settings.screenWidth, :height => settings.screenHeight};
        var bitmap = Graphics has :createBufferedBitmap ? Graphics.createBufferedBitmap(options).get()
            : new Graphics.BufferedBitmap(options);
        view.onShow();
        view.onUpdate(bitmap.getDc());
        view.onHide();
        logger.debug("Forecast rendered; free memory: " + System.getSystemStats().freeMemory);
    } finally {
        if (savedSnapshot == null) { weatherProviderDeleteSnapshot(); }
        else { Application.Storage.setValue(WEATHER_SNAPSHOT_KEY, savedSnapshot); }
        var savedKeys = savedProperties.keys();
        for (var j = 0; j < savedKeys.size(); j++) {
            Application.Properties.setValue(savedKeys[j] as String, savedProperties[savedKeys[j]]);
        }
    }
    return true;
}
