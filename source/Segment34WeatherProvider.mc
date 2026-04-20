import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Time;
using Toybox.Position;

const WEATHER_PROVIDER_GARMIN = 0;
const WEATHER_PROVIDER_OPEN_METEO_FR = 1;
const WEATHER_PROVIDER_STATE_KEY = "weather_provider_state_v1";
const WEATHER_SNAPSHOT_KEY = "weather_snapshot_v2";
const WEATHER_PROVIDER_GARMIN_LOCATION_KEY = "garmin_weather_location_v1";
const WEATHER_PROVIDER_OPEN_METEO_NAME = "open_meteo_fr";
const WEATHER_SNAPSHOT_VERSION = 2;
const WEATHER_PROVIDER_FETCH_INTERVAL_S = 3600;
const WEATHER_PROVIDER_STALE_AFTER_S = 21600;
const WEATHER_PROVIDER_IMMEDIATE_GUARD_S = 300;
const WEATHER_PROVIDER_LOCATION_SOURCE_DEVICE = "device";
const WEATHER_PROVIDER_LOCATION_SOURCE_GARMIN_CACHE = "garmin_cache";
const WEATHER_PROVIDER_LOCATION_SOURCE_STATE = "provider_state";
const WEATHER_PROVIDER_LOCATION_SOURCE_UNAVAILABLE = "unavailable";
const WEATHER_PROVIDER_ERROR_LOCATION_UNAVAILABLE = "Location unavailable";
const WEATHER_PROVIDER_ERROR_INVALID_RESPONSE = "Invalid response";
const WEATHER_PROVIDER_ERROR_REQUEST_FAILED = "Request failed";
const WEATHER_PROVIDER_OPEN_METEO_URL = "https://api.open-meteo.com/v1/meteofrance";

function weatherProviderGetSelection() as Number {
    var provider = Application.Properties.getValue("weatherProvider");
    if (provider == null) { return WEATHER_PROVIDER_GARMIN; }
    return provider as Number;
}

function weatherProviderUsesOpenMeteo() as Boolean {
    return weatherProviderGetSelection() == WEATHER_PROVIDER_OPEN_METEO_FR;
}

function weatherProviderGetPropertyOrDefault(key as String, defaultValue) {
    var value = Application.Properties.getValue(key);
    if (value == null) { return defaultValue; }
    return value;
}

function weatherProviderIsWeatherSourceId(id as Number) as Boolean {
    if (id == 20 || id == 39 || id == 40 || (id >= 43 && id <= 55) || (id >= 63 && id <= 79)) {
        return true;
    }
    return false;
}

function weatherProviderIsWeatherRequired() as Boolean {
    var weatherFields = [
        weatherProviderGetPropertyOrDefault("sunriseFieldShows", 39) as Number,
        weatherProviderGetPropertyOrDefault("sunsetFieldShows", 40) as Number,
        weatherProviderGetPropertyOrDefault("weatherLine1Shows", 78) as Number,
        weatherProviderGetPropertyOrDefault("weatherLine2Shows", 79) as Number,
        weatherProviderGetPropertyOrDefault("dateFieldShows", -1) as Number,
        weatherProviderGetPropertyOrDefault("bottomFieldShows", 17) as Number,
        weatherProviderGetPropertyOrDefault("aodFieldShows", -1) as Number,
        weatherProviderGetPropertyOrDefault("aodRightFieldShows", -2) as Number,
        weatherProviderGetPropertyOrDefault("bottomField2Shows", -2) as Number
    ];

    var touchAlternativeActive = weatherProviderGetPropertyOrDefault("touchAlternativeActive", false) as Boolean;
    if (touchAlternativeActive) {
        weatherFields.add(weatherProviderGetPropertyOrDefault("touchAlternativeLeftValueShows", 12) as Number);
        weatherFields.add(weatherProviderGetPropertyOrDefault("touchAlternativeMiddleValueShows", 2) as Number);
        weatherFields.add(weatherProviderGetPropertyOrDefault("touchAlternativeRightValueShows", 32) as Number);
        weatherFields.add(weatherProviderGetPropertyOrDefault("touchAlternativeFourthValueShows", -2) as Number);
    } else {
        weatherFields.add(weatherProviderGetPropertyOrDefault("leftValueShows", 11) as Number);
        weatherFields.add(weatherProviderGetPropertyOrDefault("middleValueShows", 29) as Number);
        weatherFields.add(weatherProviderGetPropertyOrDefault("rightValueShows", 6) as Number);
        weatherFields.add(weatherProviderGetPropertyOrDefault("fourthValueShows", 10) as Number);
    }

    for (var i = 0; i < weatherFields.size(); i++) {
        if (weatherProviderIsWeatherSourceId(weatherFields[i] as Number)) {
            return true;
        }
    }
    return false;
}

function weatherProviderToNumber(value) as Number? {
    if (value == null) { return null; }
    return value.toNumber();
}

function weatherProviderToFloat(value) as Float? {
    if (value == null) { return null; }
    return value.toFloat();
}

function weatherProviderToString(value) as String? {
    if (value == null) { return null; }
    if (value instanceof String) {
        return value as String;
    }
    return value.toString();
}

function weatherProviderNormalizeLocation(location as Array?) as Array<Float>? {
    if (location == null || location.size() < 2 || location[0] == null || location[1] == null) {
        return null;
    }
    return [(location[0] as Number).toFloat(), (location[1] as Number).toFloat()];
}

function weatherProviderStoreGarminCachedLocation(location as Array?) as Void {
    var normalized = weatherProviderNormalizeLocation(location);
    if (normalized == null) { return; }
    Application.Storage.setValue(WEATHER_PROVIDER_GARMIN_LOCATION_KEY, normalized);
}

function weatherProviderStoreGarminCachedLocationFromWeather(weather) as Void {
    if (weather == null || weather.observationLocationPosition == null) { return; }

    try {
        weatherProviderStoreGarminCachedLocation(weather.observationLocationPosition.toDegrees() as Array?);
    } catch(e) {}
}

function weatherProviderBuildLocation(location as Array?) as Position.Location or Null {
    var normalized = weatherProviderNormalizeLocation(location);
    if (normalized == null) { return null; }
    return new Position.Location({
        :latitude => normalized[0],
        :longitude => normalized[1],
        :format => :degrees
    });
}

function weatherProviderLoadState() as Dictionary? {
    return Application.Storage.getValue(WEATHER_PROVIDER_STATE_KEY) as Dictionary?;
}

function weatherProviderStoreState(state as Dictionary) as Void {
    Application.Storage.setValue(WEATHER_PROVIDER_STATE_KEY, state);
}

function weatherProviderBuildState(provider as String, lastAttemptAt as Number?, lastSuccessAt as Number?, lastErrorCode as Number?, lastErrorMessage as String?, locationSource as String?, location as Array?) as Dictionary {
    return {
        "provider" => provider,
        "lastAttemptAt" => lastAttemptAt,
        "lastSuccessAt" => lastSuccessAt,
        "lastErrorCode" => lastErrorCode,
        "lastErrorMessage" => weatherProviderTruncateString(lastErrorMessage, 120),
        "locationSource" => locationSource,
        "location" => weatherProviderNormalizeLocation(location)
    };
}

function weatherProviderLoadSnapshotRaw() as Dictionary? {
    var snapshot = Application.Storage.getValue(WEATHER_SNAPSHOT_KEY) as Dictionary?;
    if (snapshot == null) { return null; }
    if ((snapshot.get("version") as Number?) != WEATHER_SNAPSHOT_VERSION) { return null; }
    if ((snapshot.get("provider") as String?) != WEATHER_PROVIDER_OPEN_METEO_NAME) { return null; }
    return snapshot;
}

function weatherProviderLoadSnapshot() as Dictionary? {
    var snapshot = weatherProviderLoadSnapshotRaw();
    if (snapshot == null) { return null; }

    var fetchedAt = weatherProviderToNumber(snapshot.get("fetchedAt"));
    if (fetchedAt == null) { return null; }
    if (Time.now().value() - fetchedAt >= WEATHER_PROVIDER_STALE_AFTER_S) { return null; }

    return snapshot;
}

function weatherProviderStoreSnapshot(snapshot as Dictionary) as Void {
    Application.Storage.setValue(WEATHER_SNAPSHOT_KEY, snapshot);
}

function weatherProviderDeleteScheduledRefresh() as Void {
    try {
        Background.deleteTemporalEvent();
    } catch(e) {}
}

function weatherProviderScheduleNextRefresh() as Void {
    try {
        Background.registerForTemporalEvent(new Time.Duration(WEATHER_PROVIDER_FETCH_INTERVAL_S));
    } catch(e) {}
}

function weatherProviderScheduleImmediateRefreshIfNeeded() as Void {
    if (!weatherProviderUsesOpenMeteo() || !weatherProviderIsWeatherRequired()) {
        weatherProviderDeleteScheduledRefresh();
        return;
    }

    var state = weatherProviderLoadState();
    var lastAttemptAt = (state != null) ? weatherProviderToNumber(state.get("lastAttemptAt")) : null;
    var now = Time.now().value();

    // Known limitation: a failed refresh still throttles immediate retries until the
    // normal hourly schedule runs again, which can leave Open-Meteo blank after a
    // transient location or network failure.
    if (lastAttemptAt != null && now - (lastAttemptAt as Number) < WEATHER_PROVIDER_FETCH_INTERVAL_S) {
        return;
    }

    if (lastAttemptAt != null && now - (lastAttemptAt as Number) < WEATHER_PROVIDER_IMMEDIATE_GUARD_S) {
        return;
    }

    try {
        Background.registerForTemporalEvent(Time.now());
    } catch(e) {
        try {
            Background.registerForTemporalEvent(new Time.Duration(WEATHER_PROVIDER_IMMEDIATE_GUARD_S));
        } catch(e2) {}
    }
}

function weatherProviderBuildOpenMeteoParams(location as Array?) as Dictionary {
    var normalized = weatherProviderNormalizeLocation(location);
    return {
        "latitude" => (normalized[0] as Float).format("%.6f"),
        "longitude" => (normalized[1] as Float).format("%.6f"),
        "timezone" => "auto",
        "timeformat" => "unixtime",
        "forecast_days" => "4",
        "wind_speed_unit" => "ms",
        "current" => "temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m",
        "hourly" => "temperature_2m,relative_humidity_2m,apparent_temperature,precipitation_probability,weather_code,wind_speed_10m,wind_direction_10m,uv_index",
        "daily" => "temperature_2m_max,temperature_2m_min,uv_index_max,sunrise,sunset"
    };
}

function weatherProviderGetArrayValue(values as Array?, index as Number) {
    if (values == null || index < 0 || index >= values.size()) { return null; }
    return values[index];
}

function weatherProviderGetArrayNumber(values as Array?, index as Number) as Number? {
    return weatherProviderToNumber(weatherProviderGetArrayValue(values, index));
}

function weatherProviderGetArrayFloat(values as Array?, index as Number) as Float? {
    return weatherProviderToFloat(weatherProviderGetArrayValue(values, index));
}

function weatherProviderGetLocalDayStart(timestamp as Number, utcOffsetSeconds as Number) as Number {
    var localTimestamp = timestamp + utcOffsetSeconds;
    var remainder = localTimestamp % 86400;
    if (remainder < 0) {
        remainder += 86400;
    }
    return localTimestamp - remainder;
}

function weatherProviderFindNearestHourlyIndex(times as Array?, target as Number?, maxDiffSeconds as Number) as Number {
    if (times == null || target == null) { return -1; }

    var bestIdx = -1;
    var bestDiff = maxDiffSeconds + 1;
    for (var i = 0; i < times.size(); i++) {
        var timeValue = weatherProviderToNumber(times[i]);
        if (timeValue == null) { continue; }

        var diff = timeValue - (target as Number);
        if (diff < 0) {
            diff = -diff;
        }
        if (diff <= maxDiffSeconds && diff < bestDiff) {
            bestDiff = diff;
            bestIdx = i;
        }
    }

    return bestIdx;
}

function weatherProviderFindDailyIndexForTime(times as Array?, timestamp as Number?, utcOffsetSeconds as Number) as Number {
    if (times == null || timestamp == null) { return -1; }

    var targetDay = weatherProviderGetLocalDayStart(timestamp as Number, utcOffsetSeconds);
    for (var i = 0; i < times.size(); i++) {
        var timeValue = weatherProviderToNumber(times[i]);
        if (timeValue == null) { continue; }
        if (weatherProviderGetLocalDayStart(timeValue, utcOffsetSeconds) == targetDay) {
            return i;
        }
    }

    return -1;
}

function weatherProviderGetForecastHour(timestamp as Number, utcOffsetSeconds as Number) as Number {
    var localTimestamp = timestamp + utcOffsetSeconds;
    var remainder = localTimestamp % 86400;
    if (remainder < 0) {
        remainder += 86400;
    }
    return (remainder / 3600).toNumber();
}

function weatherProviderWmoToGarminCondition(wmoCode as Number?) as Number {
    if (wmoCode == null) { return 53; }

    if (wmoCode == 0) { return 0; }
    if (wmoCode == 1) { return 23; }
    if (wmoCode == 2) { return 1; }
    if (wmoCode == 3) { return 20; }
    if (wmoCode == 45 || wmoCode == 48) { return 8; }
    if (wmoCode == 51 || wmoCode == 53 || wmoCode == 55) { return 31; }
    if (wmoCode == 56 || wmoCode == 57 || wmoCode == 66 || wmoCode == 67) { return 49; }
    if (wmoCode == 61) { return 14; }
    if (wmoCode == 63) { return 3; }
    if (wmoCode == 65) { return 15; }
    if (wmoCode == 71) { return 16; }
    if (wmoCode == 73) { return 4; }
    if (wmoCode == 75) { return 17; }
    if (wmoCode == 77) { return 48; }
    if (wmoCode == 80) { return 24; }
    if (wmoCode == 81) { return 25; }
    if (wmoCode == 82) { return 26; }
    if (wmoCode == 85) { return 48; }
    if (wmoCode == 86) { return 17; }
    if (wmoCode == 95) { return 6; }
    if (wmoCode == 96) { return 12; }
    if (wmoCode == 99) { return 10; }

    return 53;
}

function weatherProviderGetDailyNumber(daily as Dictionary?, key as String, index as Number) as Number? {
    if (daily == null) { return null; }
    return weatherProviderGetArrayNumber(daily.get(key) as Array?, index);
}

function weatherProviderGetHourlyNumber(hourly as Dictionary?, key as String, index as Number) as Number? {
    if (hourly == null) { return null; }
    return weatherProviderGetArrayNumber(hourly.get(key) as Array?, index);
}

function weatherProviderGetHourlyFloat(hourly as Dictionary?, key as String, index as Number) as Float? {
    if (hourly == null) { return null; }
    return weatherProviderGetArrayFloat(hourly.get(key) as Array?, index);
}

function weatherProviderBuildSnapshotFromOpenMeteoResponse(data as Dictionary, location as Array?, fetchedAt as Number) as Dictionary? {
    var normalizedLocation = weatherProviderNormalizeLocation(location);
    if (normalizedLocation == null) { return null; }

    var current = data.get("current") as Dictionary?;
    var hourly = data.get("hourly") as Dictionary?;
    var daily = data.get("daily") as Dictionary?;
    var utcOffsetSeconds = weatherProviderToNumber(data.get("utc_offset_seconds"));
    if (current == null || hourly == null || daily == null || utcOffsetSeconds == null) { return null; }

    var timezone = weatherProviderToString(data.get("timezone"));
    if (timezone == null) { timezone = "GMT"; }

    var currentTime = weatherProviderToNumber(current.get("time"));
    if (currentTime == null) { currentTime = fetchedAt; }

    var hourlyTimes = hourly.get("time") as Array?;
    var dailyTimes = daily.get("time") as Array?;
    if (hourlyTimes == null || dailyTimes == null || hourlyTimes.size() == 0 || dailyTimes.size() == 0) {
        return null;
    }

    var nearestHourlyIdx = weatherProviderFindNearestHourlyIndex(hourlyTimes, currentTime, 1800);
    var currentDayIdx = weatherProviderFindDailyIndexForTime(dailyTimes, currentTime, utcOffsetSeconds as Number);
    if (currentDayIdx < 0) { currentDayIdx = 0; }

    var currentUv = (nearestHourlyIdx >= 0) ? weatherProviderGetHourlyFloat(hourly, "uv_index", nearestHourlyIdx) : null;
    if (currentUv == null) {
        currentUv = weatherProviderToFloat(weatherProviderGetDailyNumber(daily, "uv_index_max", currentDayIdx));
    }

    var currentSnapshot = {
        "condition" => weatherProviderWmoToGarminCondition(weatherProviderToNumber(current.get("weather_code"))),
        "temperature" => weatherProviderToNumber(current.get("temperature_2m")),
        "feelsLikeTemperature" => weatherProviderToFloat(current.get("apparent_temperature")),
        "precipitationChance" => (nearestHourlyIdx >= 0) ? weatherProviderGetHourlyNumber(hourly, "precipitation_probability", nearestHourlyIdx) : null,
        "relativeHumidity" => weatherProviderToNumber(current.get("relative_humidity_2m")),
        "windBearing" => weatherProviderToNumber(current.get("wind_direction_10m")),
        "windSpeed" => weatherProviderToFloat(current.get("wind_speed_10m")),
        "highTemperature" => weatherProviderGetDailyNumber(daily, "temperature_2m_max", currentDayIdx),
        "lowTemperature" => weatherProviderGetDailyNumber(daily, "temperature_2m_min", currentDayIdx),
        "uvIndex" => currentUv
    };

    var hourlySnapshot = [];
    for (var i = 0; i < hourlyTimes.size(); i++) {
        var forecastTime = weatherProviderToNumber(hourlyTimes[i]);
        if (forecastTime == null) { continue; }

        var dayIdx = weatherProviderFindDailyIndexForTime(dailyTimes, forecastTime, utcOffsetSeconds as Number);
        if (dayIdx < 0) { dayIdx = currentDayIdx; }

        hourlySnapshot.add({
            "forecastTime" => forecastTime,
            "forecastHour" => weatherProviderGetForecastHour(forecastTime, utcOffsetSeconds as Number),
            "condition" => weatherProviderWmoToGarminCondition(weatherProviderGetHourlyNumber(hourly, "weather_code", i)),
            "temperature" => weatherProviderGetHourlyNumber(hourly, "temperature_2m", i),
            "feelsLikeTemperature" => weatherProviderGetHourlyFloat(hourly, "apparent_temperature", i),
            "precipitationChance" => weatherProviderGetHourlyNumber(hourly, "precipitation_probability", i),
            "relativeHumidity" => weatherProviderGetHourlyNumber(hourly, "relative_humidity_2m", i),
            "windBearing" => weatherProviderGetHourlyNumber(hourly, "wind_direction_10m", i),
            "windSpeed" => weatherProviderGetHourlyFloat(hourly, "wind_speed_10m", i),
            "highTemperature" => weatherProviderGetDailyNumber(daily, "temperature_2m_max", dayIdx),
            "lowTemperature" => weatherProviderGetDailyNumber(daily, "temperature_2m_min", dayIdx),
            "uvIndex" => weatherProviderGetHourlyFloat(hourly, "uv_index", i)
        });
    }

    return {
        "version" => WEATHER_SNAPSHOT_VERSION,
        "provider" => WEATHER_PROVIDER_OPEN_METEO_NAME,
        "fetchedAt" => fetchedAt,
        "location" => normalizedLocation,
        "timezone" => timezone,
        "utcOffsetSeconds" => utcOffsetSeconds,
        "current" => currentSnapshot,
        "hourly" => hourlySnapshot
    };
}

function weatherProviderLoadGarminCachedLocation() as Array<Float>? {
    var storedLocation = Application.Storage.getValue(WEATHER_PROVIDER_GARMIN_LOCATION_KEY) as Array?;
    var normalized = weatherProviderNormalizeLocation(storedLocation);
    if (normalized != null) { return normalized; }

    var currentConditions = Application.Storage.getValue("current_conditions") as Dictionary?;
    if (currentConditions == null) { return null; }
    return weatherProviderNormalizeLocation(currentConditions.get("observationLocationPosition") as Array?);
}

function weatherProviderLoadStateLocation() as Array<Float>? {
    var state = weatherProviderLoadState();
    if (state == null) { return null; }
    return weatherProviderNormalizeLocation(state.get("location") as Array?);
}

function weatherProviderTruncateString(value as String?, maxLength as Number) as String? {
    if (value == null) { return null; }
    if (value.length() <= maxLength) { return value; }
    return value.substring(0, maxLength);
}
