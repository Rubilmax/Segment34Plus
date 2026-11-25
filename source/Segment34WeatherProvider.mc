import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.Position;
import Toybox.System;
import Toybox.Time;
import Toybox.Weather;
using Toybox.Position;

// The background weather service and the foreground watch face share this helper
// surface, so every exported weather-provider symbol must be linked into the
// background process explicitly.
(:background)
const WEATHER_PROVIDER_GARMIN = 0;
(:background)
const WEATHER_PROVIDER_OPEN_METEO = 1;
(:background)
const WEATHER_PROVIDER_STATE_KEY = "weather_provider_state_v1";
(:background)
const WEATHER_SNAPSHOT_KEY = "weather_snapshot_v2";
(:background)
const WEATHER_PROVIDER_LEGACY_GARMIN_LOCATION_KEY = "garmin_weather_location_v1";
(:background)
const WEATHER_PROVIDER_OPEN_METEO_NAME = "open_meteo_best_match";
(:background)
const WEATHER_SNAPSHOT_VERSION = 2;
(:background)
const WEATHER_PROVIDER_FETCH_INTERVAL_S = 1200;
(:background)
const WEATHER_PROVIDER_STALE_AFTER_S = 64800;
(:background)
const WEATHER_PROVIDER_IMMEDIATE_GUARD_S = 300;
(:background)
const WEATHER_PROVIDER_HOURLY_FORECAST_LIMIT = 72;
(:background)
const WEATHER_PROVIDER_COMPACT_FORECAST_LIMIT = 36;
(:background)
const WEATHER_PROVIDER_BACKGROUND_MIN_HOURLY_LIMIT = 1;
// The hourly window can spill into the next local calendar day late in the day.
(:background)
const WEATHER_PROVIDER_FORECAST_DAYS = 3;
(:background)
const WEATHER_PROVIDER_LOCATION_SOURCE_DEVICE = "device";
(:background)
const WEATHER_PROVIDER_LOCATION_SOURCE_GARMIN_CACHE = "garmin_cache";
(:background)
const WEATHER_PROVIDER_LOCATION_SOURCE_UNAVAILABLE = "unavailable";
(:background)
const WEATHER_PROVIDER_ERROR_LOCATION_UNAVAILABLE = "Location unavailable";
(:background)
const WEATHER_PROVIDER_ERROR_INVALID_RESPONSE = "Invalid response";
(:background)
const WEATHER_PROVIDER_ERROR_REQUEST_FAILED = "Request failed";
(:background)
const WEATHER_PROVIDER_OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast";
(:background)
const WEATHER_PROVIDER_BACKGROUND_PAYLOAD_VERSION = 1;
(:background)
const WEATHER_PROVIDER_BACKGROUND_RESULT_SUCCESS = 0;
(:background)
const WEATHER_PROVIDER_BACKGROUND_RESULT_LOCATION_UNAVAILABLE = 1;
(:background)
const WEATHER_PROVIDER_BACKGROUND_RESULT_INVALID_RESPONSE = 2;
(:background)
const WEATHER_PROVIDER_BACKGROUND_RESULT_REQUEST_FAILED = 3;

(:background)
function weatherProviderGetSelection() as Number {
    var provider = weatherProviderGetPropertyOrDefault("weatherProvider", WEATHER_PROVIDER_OPEN_METEO);
    return provider == WEATHER_PROVIDER_GARMIN ? WEATHER_PROVIDER_GARMIN : WEATHER_PROVIDER_OPEN_METEO;
}

(:background)
function weatherProviderUsesOpenMeteo() as Boolean {
    return weatherProviderGetSelection() == WEATHER_PROVIDER_OPEN_METEO;
}

(:background)
function weatherProviderIsOpenMeteoProviderName(provider as String?) as Boolean {
    return provider != null && provider.equals(WEATHER_PROVIDER_OPEN_METEO_NAME);
}

(:background)
function weatherProviderGetPropertyOrDefault(key as String, defaultValue) {
    try {
        var value = Application.Properties.getValue(key);
        if (defaultValue instanceof Number && value instanceof Number) { return value; }
        if (defaultValue instanceof Boolean && value instanceof Boolean) { return value; }
    } catch (e) {}
    return defaultValue;
}

(:background)
function weatherProviderIsWeatherSourceId(id as Number) as Boolean {
    if (id == 20 || id == 39 || id == 40 || (id >= 43 && id <= 55) || (id >= 63 && id <= 70) || (id >= 73 && id <= 75) || (id >= 77 && id <= 79)) {
        return true;
    }
    return false;
}

(:background)
function weatherProviderPropertyNeedsWeather(key as String, defaultValue as Number) as Boolean {
    return weatherProviderIsWeatherSourceId(weatherProviderGetPropertyOrDefault(key, defaultValue) as Number);
}

(:background)
function weatherProviderIsWeatherRequired() as Boolean {
    if (weatherProviderPropertyNeedsWeather("sunriseFieldShows", 39)) { return true; }
    if (weatherProviderPropertyNeedsWeather("sunsetFieldShows", 40)) { return true; }
    if (weatherProviderPropertyNeedsWeather("weatherLine1Shows", 78)) { return true; }
    if (weatherProviderPropertyNeedsWeather("weatherLine2Shows", 79)) { return true; }
    if (weatherProviderPropertyNeedsWeather("dateFieldShows", -1)) { return true; }
    if (weatherProviderPropertyNeedsWeather("bottomFieldShows", 17)) { return true; }
    if (weatherProviderPropertyNeedsWeather("aodFieldShows", -1)) { return true; }
    if (weatherProviderPropertyNeedsWeather("aodRightFieldShows", -2)) { return true; }
    if (weatherProviderPropertyNeedsWeather("bottomField2Shows", -2)) { return true; }
    if (weatherProviderPropertyNeedsWeather("notificationCountShows", 14)) { return true; }

    var touchAlternativeActive = weatherProviderGetPropertyOrDefault("touchAlternativeActive", false) as Boolean;
    if (touchAlternativeActive) {
        if (weatherProviderPropertyNeedsWeather("touchAlternativeLeftValueShows", 12)) { return true; }
        if (weatherProviderPropertyNeedsWeather("touchAlternativeMiddleValueShows", 2)) { return true; }
        if (weatherProviderPropertyNeedsWeather("touchAlternativeRightValueShows", 32)) { return true; }
        if (weatherProviderPropertyNeedsWeather("touchAlternativeFourthValueShows", -2)) { return true; }
        return false;
    }

    if (weatherProviderPropertyNeedsWeather("leftValueShows", 11)) { return true; }
    if (weatherProviderPropertyNeedsWeather("middleValueShows", 29)) { return true; }
    if (weatherProviderPropertyNeedsWeather("rightValueShows", 6)) { return true; }
    return weatherProviderPropertyNeedsWeather("fourthValueShows", 10);
}

(:background)
function weatherProviderToNumber(value) as Number? {
    if (value == null) { return null; }
    if (value instanceof Number) { return value as Number; }
    try {
        return value.toNumber();
    } catch(e) {}
    return null;
}

(:background)
function weatherProviderToFloat(value) as Float? {
    if (value == null) { return null; }
    if (value instanceof Float) { return value as Float; }
    try {
        return value.toFloat();
    } catch(e) {}
    return null;
}

(:background)
function weatherProviderToString(value) as String? {
    if (value == null) { return null; }
    if (value instanceof String) {
        return value as String;
    }
    try {
        return value.toString();
    } catch(e) {}
    return null;
}

(:background)
function weatherProviderNormalizeLocation(location as Array?) as Array<Float>? {
    if (location == null || location.size() < 2) { return null; }
    var latitude = weatherProviderToFloat(location[0]);
    var longitude = weatherProviderToFloat(location[1]);
    if (latitude == null || longitude == null) { return null; }
    if (!(latitude >= -90.0f && latitude <= 90.0f && longitude >= -180.0f && longitude <= 180.0f)) {
        return null;
    }
    return [latitude, longitude];
}

(:background)
function weatherProviderDeleteLegacyLocationData() as Void {
    Application.Storage.deleteValue(WEATHER_PROVIDER_LEGACY_GARMIN_LOCATION_KEY);

    var state = weatherProviderLoadState();
    if (state == null || state.get("location") == null) { return; }

    var provider = weatherProviderToString(state.get("provider"));
    if (provider == null) { return; }

    weatherProviderStoreState(weatherProviderBuildState(
        provider,
        weatherProviderToNumber(state.get("lastAttemptAt")),
        weatherProviderToNumber(state.get("lastSuccessAt")),
        weatherProviderToNumber(state.get("lastErrorCode")),
        weatherProviderToString(state.get("lastErrorMessage")),
        weatherProviderToString(state.get("locationSource"))
    ));
}

(:background)
function weatherProviderBuildLocation(location as Array?) as Position.Location or Null {
    var normalized = weatherProviderNormalizeLocation(location);
    if (normalized == null) { return null; }
    return new Position.Location({
        :latitude => normalized[0],
        :longitude => normalized[1],
        :format => :degrees
    });
}

(:background)
function weatherProviderLoadState() as Dictionary? {
    return Application.Storage.getValue(WEATHER_PROVIDER_STATE_KEY) as Dictionary?;
}

(:background)
function weatherProviderLoadOpenMeteoState() as Dictionary? {
    var state = weatherProviderLoadState();
    if (state == null) { return null; }
    var provider = weatherProviderToString(state.get("provider"));
    if (!weatherProviderIsOpenMeteoProviderName(provider)) {
        return null;
    }
    return state;
}

(:background)
function weatherProviderStoreState(state as Dictionary) as Void {
    Application.Storage.setValue(WEATHER_PROVIDER_STATE_KEY, state);
}

(:background)
function weatherProviderDeleteState() as Void {
    try {
        Application.Storage.deleteValue(WEATHER_PROVIDER_STATE_KEY);
    } catch(e) {
        System.println("Open-Meteo state delete failure: " + e);
    }
}

(:background)
function weatherProviderBuildState(provider as String, lastAttemptAt as Number?, lastSuccessAt as Number?, lastErrorCode as Number?, lastErrorMessage as String?, locationSource as String?) as Dictionary {
    return {
        "provider" => provider,
        "lastAttemptAt" => lastAttemptAt,
        "lastSuccessAt" => lastSuccessAt,
        "lastErrorCode" => lastErrorCode,
        "lastErrorMessage" => weatherProviderTruncateString(lastErrorMessage, 120),
        "locationSource" => locationSource
    };
}

(:background)
function weatherProviderLoadSnapshotRaw() as Dictionary? {
    var snapshot = Application.Storage.getValue(WEATHER_SNAPSHOT_KEY) as Dictionary?;
    if (snapshot == null) { return null; }

    var version = weatherProviderToNumber(snapshot.get("version"));
    if (version != WEATHER_SNAPSHOT_VERSION) {
        return null;
    }

    var provider = weatherProviderToString(snapshot.get("provider"));
    if (!weatherProviderIsOpenMeteoProviderName(provider)) {
        return null;
    }

    return snapshot;
}

(:background)
function weatherProviderLoadSnapshot() as Dictionary? {
    var snapshot = weatherProviderLoadSnapshotRaw();
    if (snapshot == null) { return null; }

    var fetchedAt = weatherProviderToNumber(snapshot.get("fetchedAt"));
    if (fetchedAt == null || !weatherProviderIsSnapshotFresh(fetchedAt, Time.now().value())) { return null; }
    return snapshot;
}

(:background)
function weatherProviderIsSnapshotFresh(fetchedAt as Number, now as Number) as Boolean {
    var age = now - fetchedAt;
    return age >= 0 && age < WEATHER_PROVIDER_STALE_AFTER_S;
}

(:background)
function weatherProviderStoreSnapshot(snapshot as Dictionary) as Void {
    Application.Storage.setValue(WEATHER_SNAPSHOT_KEY, snapshot);
}

(:background)
function weatherProviderDeleteSnapshot() as Void {
    try {
        Application.Storage.deleteValue(WEATHER_SNAPSHOT_KEY);
    } catch(e) {
        System.println("Open-Meteo snapshot delete failure: " + e);
    }
}

(:background)
function weatherProviderDeleteScheduledRefresh() as Void {
    try {
        if (Background.getTemporalEventRegisteredTime() != null) {
            Background.deleteTemporalEvent();
        }
    } catch (e) {}
}

(:background)
function weatherProviderScheduleNextRefresh(interval as Number) as Void {
    try {
        var registration = Background.getTemporalEventRegisteredTime();
        if (registration instanceof Time.Duration && registration.value() == interval) { return; }
        Background.registerForTemporalEvent(new Time.Duration(interval));
    } catch (e) {
        System.println("Open-Meteo scheduling failure: " + e);
    }
}

(:background)
function weatherProviderEnsureRefreshScheduled() as Void {
    try {
        if (Background.getTemporalEventRegisteredTime() != null) { return; }
        var lastEvent = Background.getLastTemporalEventTime();
        var nextEvent = lastEvent == null ? Time.now() : lastEvent.add(new Time.Duration(WEATHER_PROVIDER_IMMEDIATE_GUARD_S));
        Background.registerForTemporalEvent(nextEvent);
    } catch (e) {
        weatherProviderScheduleNextRefresh(WEATHER_PROVIDER_IMMEDIATE_GUARD_S);
    }
}

(:background)
function weatherProviderBuildOpenMeteoParams(location as Array?) as Dictionary {
    var normalized = weatherProviderNormalizeLocation(location);
    if (normalized == null) { return {}; }
    var forecastHours = weatherProviderGetHourlyForecastLimit();
    return {
        "latitude" => (normalized[0] as Float).format("%.6f"),
        "longitude" => (normalized[1] as Float).format("%.6f"),
        "timezone" => "auto",
        "timeformat" => "unixtime",
        "forecast_days" => WEATHER_PROVIDER_FORECAST_DAYS.format("%d"),
        "forecast_hours" => forecastHours.format("%d"),
        "wind_speed_unit" => "ms",
        "current" => "temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m,precipitation_probability,uv_index",
        "hourly" => "weather_code,precipitation_probability,uv_index",
        "daily" => "temperature_2m_max,temperature_2m_min,apparent_temperature_min,apparent_temperature_max,uv_index_max,sunrise,sunset"
    };
}

(:background)
function weatherProviderForecastLimitForMemory(backgroundMemory as Number, lowMemoryWatch as Boolean) as Number {
    return backgroundMemory <= 32768 || lowMemoryWatch ? WEATHER_PROVIDER_COMPACT_FORECAST_LIMIT : WEATHER_PROVIDER_HOURLY_FORECAST_LIMIT;
}

(:background, :NoWeatherCache)
function weatherProviderGetHourlyForecastLimit() as Number {
    return weatherProviderForecastLimitForMemory(System.getSystemStats().totalMemory, true);
}

(:background, :WeatherCache)
function weatherProviderGetHourlyForecastLimit() as Number {
    return weatherProviderForecastLimitForMemory(System.getSystemStats().totalMemory, false);
}

(:background)
function weatherProviderGetArrayValue(values as Array?, index as Number) {
    if (values == null || index < 0 || index >= weatherProviderGetArraySize(values)) { return null; }
    try {
        return values[index];
    } catch(e) {}
    return null;
}

(:background)
function weatherProviderGetArraySize(values as Array?) as Number {
    if (values == null) { return 0; }
    try {
        return values.size();
    } catch(e) {}
    return 0;
}

(:background)
function weatherProviderGetArrayNumber(values as Array?, index as Number) as Number? {
    return weatherProviderToNumber(weatherProviderGetArrayValue(values, index));
}

(:background)
function weatherProviderGetArrayFloat(values as Array?, index as Number) as Float? {
    return weatherProviderToFloat(weatherProviderGetArrayValue(values, index));
}

(:background)
function weatherProviderGetLocalDayStart(timestamp as Number, utcOffsetSeconds as Number) as Number {
    var localTimestamp = timestamp + utcOffsetSeconds;
    var remainder = localTimestamp % 86400;
    if (remainder < 0) {
        remainder += 86400;
    }
    return localTimestamp - remainder;
}

(:background)
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

(:background)
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

(:background)
function weatherProviderGetForecastHour(timestamp as Number, utcOffsetSeconds as Number) as Number {
    var localTimestamp = timestamp + utcOffsetSeconds;
    var remainder = localTimestamp % 86400;
    if (remainder < 0) {
        remainder += 86400;
    }
    return (remainder / 3600).toNumber();
}

(:background)
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
    if (wmoCode == 95 || wmoCode == 97) { return 6; }
    if (wmoCode == 96) { return 12; }
    if (wmoCode == 99) { return 10; }

    return 53;
}

(:background)
function weatherProviderGetDailyNumber(daily as Dictionary?, key as String, index as Number) as Number? {
    if (daily == null) { return null; }
    return weatherProviderGetArrayNumber(daily.get(key) as Array?, index);
}

(:background)
function weatherProviderBuildSunEvents(daily as Dictionary?, dailyTimes as Array?, utcOffsetSeconds as Number) as Array {
    var sunEvents = [];
    if (daily == null || dailyTimes == null) { return sunEvents; }

    var dailyCount = weatherProviderGetArraySize(dailyTimes);
    for (var i = 0; i < dailyCount; i++) {
        var dayTime = weatherProviderGetArrayNumber(dailyTimes, i);
        var sunrise = weatherProviderGetDailyNumber(daily, "sunrise", i);
        var sunset = weatherProviderGetDailyNumber(daily, "sunset", i);
        if (dayTime == null || sunrise == null || sunset == null) { continue; }

        sunEvents.add([
            weatherProviderGetLocalDayStart(dayTime as Number, utcOffsetSeconds),
            sunrise,
            sunset
        ]);
    }

    return sunEvents;
}

(:background)
function weatherProviderGetHourlyNumber(hourly as Dictionary?, key as String, index as Number) as Number? {
    if (hourly == null) { return null; }
    return weatherProviderGetArrayNumber(hourly.get(key) as Array?, index);
}

(:background)
function weatherProviderGetHourlyFloat(hourly as Dictionary?, key as String, index as Number) as Float? {
    if (hourly == null) { return null; }
    return weatherProviderGetArrayFloat(hourly.get(key) as Array?, index);
}

(:background)
function weatherProviderBuildEncodedOpenMeteoSnapshot(data as Dictionary, location as Array?, fetchedAt as Number) as Dictionary? {
    var normalizedLocation = weatherProviderNormalizeLocation(location);
    if (normalizedLocation == null) { return null; }

    var current = data.get("current");
    var hourly = data.get("hourly");
    var daily = data.get("daily");
    var utcOffsetSeconds = weatherProviderToNumber(data.get("utc_offset_seconds"));
    if (!(current instanceof Dictionary) || !(hourly instanceof Dictionary) ||
        !(daily instanceof Dictionary) || utcOffsetSeconds == null) { return null; }

    var timezone = weatherProviderToString(data.get("timezone"));
    if (timezone == null) { timezone = "GMT"; }

    var currentTime = weatherProviderToNumber(current.get("time"));
    if (currentTime == null) { currentTime = fetchedAt; }

    var hourlyTimes = hourly.get("time");
    var dailyTimes = daily.get("time");
    if (!(hourlyTimes instanceof Array) || !(dailyTimes instanceof Array) || hourlyTimes.size() == 0 || dailyTimes.size() == 0) {
        return null;
    }

    var currentDayIdx = weatherProviderFindDailyIndexForTime(dailyTimes, currentTime, utcOffsetSeconds as Number);
    var hasCurrentDay = currentDayIdx >= 0;
    if (currentDayIdx < 0) { currentDayIdx = 0; }

    var currentUv = weatherProviderToFloat(current.get("uv_index"));
    var currentPrecipitationChance = weatherProviderToNumber(current.get("precipitation_probability"));
    if (currentUv == null || currentPrecipitationChance == null) {
        var nearestHourlyIdx = weatherProviderFindNearestHourlyIndex(hourlyTimes, currentTime, 1800);
        if (nearestHourlyIdx >= 0) {
            if (currentUv == null) {
                currentUv = weatherProviderGetHourlyFloat(hourly, "uv_index", nearestHourlyIdx);
            }
            if (currentPrecipitationChance == null) {
                currentPrecipitationChance = weatherProviderGetHourlyNumber(hourly, "precipitation_probability", nearestHourlyIdx);
            }
        }
    }
    if (currentUv == null) {
        currentUv = weatherProviderGetHourlyFloat(daily, "uv_index_max", currentDayIdx);
    }

    var sunEvents = weatherProviderBuildSunEvents(daily, dailyTimes, utcOffsetSeconds as Number);

    // Match the transport order used by weatherProviderDecodeBackgroundCurrentEntry.
    var currentSnapshot = [
        weatherProviderWmoToGarminCondition(weatherProviderToNumber(current.get("weather_code"))),
        weatherProviderToNumber(current.get("temperature_2m")),
        weatherProviderToFloat(current.get("apparent_temperature")),
        currentPrecipitationChance,
        weatherProviderToNumber(current.get("relative_humidity_2m")),
        weatherProviderToNumber(current.get("wind_direction_10m")),
        weatherProviderToFloat(current.get("wind_speed_10m")),
        weatherProviderGetDailyNumber(daily, "temperature_2m_max", currentDayIdx),
        weatherProviderGetDailyNumber(daily, "temperature_2m_min", currentDayIdx),
        currentUv,
        hasCurrentDay ? [
            weatherProviderGetHourlyFloat(daily, "apparent_temperature_min", currentDayIdx),
            weatherProviderGetHourlyFloat(daily, "apparent_temperature_max", currentDayIdx),
            weatherProviderGetLocalDayStart(currentTime as Number, utcOffsetSeconds as Number)
        ] : null
    ];

    // Keep columns compact while the parsed response is alive on the background heap.
    var hourlyStartIdx = 0;
    while (hourlyStartIdx + 1 < hourlyTimes.size()) {
        var nextTime = weatherProviderGetArrayNumber(hourlyTimes, hourlyStartIdx + 1);
        if (nextTime == null || nextTime > (currentTime as Number)) { break; }
        hourlyStartIdx++;
    }
    var hourlyColumns = weatherProviderBuildHourlyColumns(hourly, hourlyTimes, hourlyStartIdx, weatherProviderGetHourlyForecastLimit());

    return {
        "t" => fetchedAt,
        "l" => normalizedLocation,
        "z" => timezone,
        "o" => utcOffsetSeconds,
        "c" => currentSnapshot,
        "d" => sunEvents,
        "q" => hourlyColumns
    };
}

(:background)
function weatherProviderBuildHourlyColumns(hourly as Dictionary, times as Array, start as Number, limit as Number) as Array {
    var firstTime = weatherProviderGetArrayNumber(times, start);
    if (firstTime == null) { return []; }
    var lastTime = firstTime;
    for (var last = times.size() - 1; last >= start; last--) {
        var value = weatherProviderGetArrayNumber(times, last);
        if (value != null) { lastTime = value; break; }
    }
    if (lastTime < firstTime || limit <= 0) { return []; }
    var count = (lastTime - firstTime) / 3600 + 1;
    if (count > limit) { count = limit; }
    var conditions = new [count];
    var codes = hourly.get("weather_code");
    var weatherCodes = codes instanceof Array ? codes as Array : null;
    var sourceIdx = start;
    for (var i = 0; i < count; i++) {
        var expectedTime = (firstTime as Number) + i * 3600;
        var sourceTime = weatherProviderGetArrayNumber(times, sourceIdx);
        while (sourceIdx < times.size() && (sourceTime == null || sourceTime < expectedTime)) {
            sourceIdx++;
            sourceTime = weatherProviderGetArrayNumber(times, sourceIdx);
        }
        var validTime = sourceTime == expectedTime;
        conditions[i] = validTime ? weatherProviderWmoToGarminCondition(weatherProviderGetArrayNumber(weatherCodes, sourceIdx)) : null;
    }
    // Keep the legacy column header and reserved slot for persisted snapshots.
    return [firstTime, count, 0, conditions, []];
}

(:background)
function weatherProviderLimitHourlyColumns(columns as Array, limit as Number) as Array {
    var count = weatherProviderGetBackgroundHourlyColumnCount(columns);
    if (limit <= 0 || count <= 0) { return []; }
    if (count <= limit) { return columns; }
    var details = weatherProviderGetArrayNumber(columns, 2);
    if (details == null || details > limit) { details = limit; }
    var limited = [columns[0], limit, details];
    for (var i = 3; i < columns.size(); i++) {
        var values = columns[i] as Array;
        var valueLimit = i == 3 ? limit : details as Number;
        if (valueLimit > values.size()) { valueLimit = values.size(); }
        limited.add(values.slice(0, valueLimit));
    }
    return limited;
}

(:background)
function weatherProviderEncodeBackgroundLocationSource(source as String?) as Number {
    if (source != null && source.equals(WEATHER_PROVIDER_LOCATION_SOURCE_DEVICE)) { return 0; }
    if (source != null && source.equals(WEATHER_PROVIDER_LOCATION_SOURCE_GARMIN_CACHE)) { return 1; }
    return 2;
}

(:background)
function weatherProviderDecodeBackgroundLocationSource(code as Number?) as String {
    if (code == 0) { return WEATHER_PROVIDER_LOCATION_SOURCE_DEVICE; }
    if (code == 1) { return WEATHER_PROVIDER_LOCATION_SOURCE_GARMIN_CACHE; }
    return WEATHER_PROVIDER_LOCATION_SOURCE_UNAVAILABLE;
}

(:background)
function weatherProviderDecodeBackgroundCurrentEntry(values as Array?) as Dictionary? {
    if (values == null) { return null; }

    return {
        "condition" => weatherProviderGetArrayNumber(values, 0),
        "temperature" => weatherProviderGetArrayNumber(values, 1),
        "feelsLikeTemperature" => weatherProviderGetArrayFloat(values, 2),
        "precipitationChance" => weatherProviderGetArrayNumber(values, 3),
        "relativeHumidity" => weatherProviderGetArrayNumber(values, 4),
        "windBearing" => weatherProviderGetArrayNumber(values, 5),
        "windSpeed" => weatherProviderGetArrayFloat(values, 6),
        "highTemperature" => weatherProviderGetArrayNumber(values, 7),
        "lowTemperature" => weatherProviderGetArrayNumber(values, 8),
        "uvIndex" => weatherProviderGetArrayFloat(values, 9),
        "dailyFeelsLike" => weatherProviderGetArrayValue(values, 10) as Array?
    };
}

(:background)
function weatherProviderDecodeBackgroundHourlyEntry(values as Array?, utcOffsetSeconds as Number) as Dictionary? {
    if (values == null) { return null; }

    var forecastTime = weatherProviderGetArrayNumber(values, 0);
    if (forecastTime == null) { return null; }

    return {
        "forecastTime" => forecastTime,
        "forecastHour" => weatherProviderGetForecastHour(forecastTime, utcOffsetSeconds),
        "condition" => weatherProviderGetArrayNumber(values, 1),
        "temperature" => weatherProviderGetArrayNumber(values, 2),
        "feelsLikeTemperature" => weatherProviderGetArrayFloat(values, 3),
        "precipitationChance" => weatherProviderGetArrayNumber(values, 4),
        "relativeHumidity" => weatherProviderGetArrayNumber(values, 5),
        "windBearing" => weatherProviderGetArrayNumber(values, 6),
        "windSpeed" => weatherProviderGetArrayFloat(values, 7),
        "highTemperature" => weatherProviderGetArrayNumber(values, 8),
        "lowTemperature" => weatherProviderGetArrayNumber(values, 9),
        "uvIndex" => weatherProviderGetArrayFloat(values, 10)
    };
}

(:background)
function weatherProviderDecodeBackgroundSunEvents(values as Array?) as Array {
    var sunEvents = [];
    var eventCount = weatherProviderGetArraySize(values);

    for (var i = 0; i < eventCount; i++) {
        var entry = weatherProviderGetArrayValue(values, i) as Array?;
        if (entry == null || weatherProviderGetArraySize(entry) < 3) { continue; }

        var dayStart = weatherProviderGetArrayNumber(entry, 0);
        var sunrise = weatherProviderGetArrayNumber(entry, 1);
        var sunset = weatherProviderGetArrayNumber(entry, 2);
        if (dayStart == null || sunrise == null || sunset == null) { continue; }

        sunEvents.add([dayStart, sunrise, sunset]);
    }

    return sunEvents;
}

(:background)
function weatherProviderTryGetArrayNumber(values as Array?, index as Number) as Number? {
    try {
        return weatherProviderGetArrayNumber(values, index);
    } catch(e) {}
    return null;
}

(:background)
function weatherProviderIsBackgroundHourlyColumns(values as Array?) as Boolean {
    if (weatherProviderGetArraySize(values) < 5) { return false; }
    return weatherProviderTryGetArrayNumber(values, 0) != null
        && weatherProviderTryGetArrayNumber(values, 1) != null;
}

(:background)
function weatherProviderGetBackgroundHourlyColumnCount(values as Array?) as Number {
    if (!weatherProviderIsBackgroundHourlyColumns(values)) { return 0; }
    var count = weatherProviderGetArrayNumber(values, 1);
    if (count == null || count < 0) { return 0; }
    return count as Number;
}

(:background)
function weatherProviderDecodeBackgroundSnapshot(snapshot as Dictionary?) as Dictionary? {
    if (snapshot == null) { return null; }

    var fetchedAt = weatherProviderToNumber(snapshot.get("t"));
    var location = weatherProviderNormalizeLocation(snapshot.get("l") as Array?);
    var utcOffsetSeconds = weatherProviderToNumber(snapshot.get("o"));
    var current = weatherProviderDecodeBackgroundCurrentEntry(snapshot.get("c") as Array?);
    if (fetchedAt == null || location == null || utcOffsetSeconds == null || current == null) {
        return null;
    }

    var timezone = weatherProviderToString(snapshot.get("z"));
    if (timezone == null) { timezone = "GMT"; }

    var hourlyColumns = snapshot.get("q") as Array?;
    var compactHourlyColumns = weatherProviderIsBackgroundHourlyColumns(hourlyColumns) ? hourlyColumns : null;
    var hourly = [];

    var hourlyEntries = snapshot.get("h") as Array?;
    if (compactHourlyColumns == null && hourlyEntries != null) {
        if (weatherProviderIsBackgroundHourlyColumns(hourlyEntries)) {
            compactHourlyColumns = hourlyEntries;
        } else {
            var hourlyEntryCount = weatherProviderGetArraySize(hourlyEntries);
            for (var i = 0; i < hourlyEntryCount; i++) {
                var decoded = weatherProviderDecodeBackgroundHourlyEntry(weatherProviderGetArrayValue(hourlyEntries, i) as Array?, utcOffsetSeconds as Number);
                if (decoded != null) {
                    hourly.add(decoded);
                }
            }
        }
    }

    return {
        "version" => WEATHER_SNAPSHOT_VERSION,
        "provider" => WEATHER_PROVIDER_OPEN_METEO_NAME,
        "fetchedAt" => fetchedAt,
        "location" => location,
        "timezone" => timezone,
        "utcOffsetSeconds" => utcOffsetSeconds,
        "current" => current,
        "sunEvents" => weatherProviderDecodeBackgroundSunEvents(snapshot.get("d") as Array?),
        "hourly" => hourly,
        "hourlyColumns" => compactHourlyColumns
    };
}

(:background)
function weatherProviderBuildBackgroundSuccessPayloadFromEncodedSnapshot(encodedSnapshot as Dictionary?, lastAttemptAt as Number, lastSuccessAt as Number, locationSource as String?) as Dictionary? {
    if (encodedSnapshot == null) { return null; }

    return {
        "v" => WEATHER_PROVIDER_BACKGROUND_PAYLOAD_VERSION,
        "r" => WEATHER_PROVIDER_BACKGROUND_RESULT_SUCCESS,
        "a" => lastAttemptAt,
        "u" => lastSuccessAt,
        "s" => weatherProviderEncodeBackgroundLocationSource(locationSource),
        "p" => encodedSnapshot
    };
}

(:background)
function weatherProviderBuildBackgroundFailurePayload(reason as Number, lastAttemptAt as Number, responseCode as Number?, locationSource as String?) as Dictionary {
    return {
        "v" => WEATHER_PROVIDER_BACKGROUND_PAYLOAD_VERSION,
        "r" => reason,
        "a" => lastAttemptAt,
        "c" => responseCode,
        "s" => weatherProviderEncodeBackgroundLocationSource(locationSource)
    };
}

(:background)
function weatherProviderBuildBackgroundErrorMessage(reason as Number, responseCode as Number?) as String {
    if (reason == WEATHER_PROVIDER_BACKGROUND_RESULT_LOCATION_UNAVAILABLE) {
        return WEATHER_PROVIDER_ERROR_LOCATION_UNAVAILABLE;
    }

    if (reason == WEATHER_PROVIDER_BACKGROUND_RESULT_INVALID_RESPONSE) {
        return WEATHER_PROVIDER_ERROR_INVALID_RESPONSE;
    }

    if (responseCode != null && responseCode >= 0) {
        return WEATHER_PROVIDER_ERROR_REQUEST_FAILED + " (" + responseCode.format("%d") + ")";
    }

    return WEATHER_PROVIDER_ERROR_REQUEST_FAILED;
}

(:background)
function weatherProviderApplyBackgroundPayload(data) as Boolean {
    if (!(data instanceof Dictionary)) { return false; }

    var payload = data as Dictionary;
    if (weatherProviderToNumber(payload.get("v")) != WEATHER_PROVIDER_BACKGROUND_PAYLOAD_VERSION) {
        return false;
    }

    var reason = weatherProviderToNumber(payload.get("r"));
    var lastAttemptAt = weatherProviderToNumber(payload.get("a"));
    if (reason == null || lastAttemptAt == null) {
        return false;
    }

    var locationSource = weatherProviderDecodeBackgroundLocationSource(weatherProviderToNumber(payload.get("s")));
    var responseCode = null as Number?;
    var errorMessage = WEATHER_PROVIDER_ERROR_INVALID_RESPONSE;
    if (reason == WEATHER_PROVIDER_BACKGROUND_RESULT_SUCCESS) {
        var snapshot = weatherProviderDecodeBackgroundSnapshot(payload.get("p") as Dictionary?);
        if (snapshot != null) {
            var successAt = weatherProviderToNumber(payload.get("u"));
            weatherProviderStoreSnapshot(snapshot);
            weatherProviderStoreState(weatherProviderBuildState(
                WEATHER_PROVIDER_OPEN_METEO_NAME,
                lastAttemptAt,
                successAt == null ? lastAttemptAt : successAt,
                null,
                null,
                locationSource
            ));
            return true;
        }
    } else {
        responseCode = weatherProviderToNumber(payload.get("c"));
        errorMessage = weatherProviderBuildBackgroundErrorMessage(reason as Number, responseCode);
    }

    var existingState = weatherProviderLoadOpenMeteoState();
    var lastSuccessAt = existingState == null ? null : weatherProviderToNumber(existingState.get("lastSuccessAt"));
    weatherProviderStoreState(weatherProviderBuildState(
        WEATHER_PROVIDER_OPEN_METEO_NAME,
        lastAttemptAt,
        lastSuccessAt,
        responseCode,
        errorMessage,
        locationSource
    ));
    return false;
}

(:background)
function weatherProviderTruncateString(value as String?, maxLength as Number) as String? {
    if (value == null) { return null; }
    if (value.length() <= maxLength) { return value; }
    return value.substring(0, maxLength);
}
