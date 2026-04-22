import Toybox.Background;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.PersistedContent;
import Toybox.Position;
import Toybox.System;
import Toybox.Time;
using Toybox.Position;

(:background)
class Segment34WeatherServiceDelegate extends System.ServiceDelegate {

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        weatherProviderSetScheduledRefreshPending(false);

        var settingsSnapshot = weatherProviderLoadSettingsSnapshot();
        if (!weatherProviderUsesOpenMeteoSnapshot(settingsSnapshot) || !weatherProviderIsWeatherRequiredFromSnapshot(settingsSnapshot)) {
            weatherProviderDeleteScheduledRefresh();
            Background.exit(null);
            return;
        }

        weatherProviderScheduleNextRefresh();

        var now = Time.now().value();
        var previousState = weatherProviderLoadOpenMeteoState();
        var lastSuccessAt = (previousState != null) ? weatherProviderToNumber(previousState.get("lastSuccessAt")) : null;
        var resolvedLocation = resolveWeatherLocation();
        var location = resolvedLocation.get("location") as Array?;
        var locationSource = resolvedLocation.get("source") as String?;

        if (location == null) {
            weatherProviderStoreState(weatherProviderBuildState(
                WEATHER_PROVIDER_OPEN_METEO_NAME,
                now,
                lastSuccessAt,
                -1,
                WEATHER_PROVIDER_ERROR_LOCATION_UNAVAILABLE,
                WEATHER_PROVIDER_LOCATION_SOURCE_UNAVAILABLE,
                null
            ));
            Background.exit({"weatherUpdated" => false});
            return;
        }

        weatherProviderStoreState(weatherProviderBuildState(
            WEATHER_PROVIDER_OPEN_METEO_NAME,
            now,
            lastSuccessAt,
            null,
            null,
            locationSource,
            location
        ));

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            :context => {
                "fetchedAt" => now,
                "location" => location,
                "locationSource" => locationSource,
                "lastAttemptAt" => now,
                "lastSuccessAt" => lastSuccessAt
            }
        };

        try {
            Communications.makeWebRequest(
                WEATHER_PROVIDER_OPEN_METEO_URL,
                weatherProviderBuildOpenMeteoParams(location),
                options,
                method(:onWeatherResponse)
            );
        } catch(e) {
            logOpenMeteoRequestFailure(
                WEATHER_PROVIDER_ERROR_REQUEST_FAILED,
                -1,
                options.get(:context) as Dictionary
            );
            persistFailureState(-1, WEATHER_PROVIDER_ERROR_REQUEST_FAILED, options.get(:context) as Dictionary);
            Background.exit({"weatherUpdated" => false});
        }
    }

    hidden function onWeatherResponse(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null, context as Object) as Void {
        var responseContext = context as Dictionary;
        var location = responseContext.get("location") as Array?;
        var locationSource = responseContext.get("locationSource") as String?;
        var lastAttemptAt = weatherProviderToNumber(responseContext.get("lastAttemptAt"));
        var lastSuccessAt = weatherProviderToNumber(responseContext.get("lastSuccessAt"));

        if (responseCode == 200 && data instanceof Dictionary) {
            var snapshot = weatherProviderBuildSnapshotFromOpenMeteoResponse(
                data as Dictionary,
                location,
                weatherProviderToNumber(responseContext.get("fetchedAt")) as Number
            );
            if (snapshot != null) {
                weatherProviderStoreSnapshot(snapshot);
                weatherProviderStoreState(weatherProviderBuildState(
                    WEATHER_PROVIDER_OPEN_METEO_NAME,
                    lastAttemptAt,
                    Time.now().value(),
                    null,
                    null,
                    locationSource,
                    location
                ));
                Background.exit({"weatherUpdated" => true});
                return;
            }
        }

        var errorMessage = WEATHER_PROVIDER_ERROR_INVALID_RESPONSE;
        if (responseCode != 200) {
            errorMessage = WEATHER_PROVIDER_ERROR_REQUEST_FAILED + " (" + responseCode.format("%d") + ")";
        }

        logOpenMeteoRequestFailure(errorMessage, responseCode, responseContext);
        weatherProviderStoreState(weatherProviderBuildState(
            WEATHER_PROVIDER_OPEN_METEO_NAME,
            lastAttemptAt,
            lastSuccessAt,
            responseCode,
            errorMessage,
            locationSource,
            location
        ));
        Background.exit({"weatherUpdated" => false});
    }

    hidden function resolveWeatherLocation() as Dictionary {
        try {
            var info = Position.getInfo();
            if (info != null && info has :position && info.position != null) {
                var degrees = info.position.toDegrees() as Array?;
                var normalized = weatherProviderNormalizeLocation(degrees);
                if (normalized != null) {
                    return {
                        "location" => normalized,
                        "source" => WEATHER_PROVIDER_LOCATION_SOURCE_DEVICE
                    };
                }
            }
        } catch(e) {}

        var garminLocation = weatherProviderLoadGarminCachedLocation();
        if (garminLocation != null) {
            return {
                "location" => garminLocation,
                "source" => WEATHER_PROVIDER_LOCATION_SOURCE_GARMIN_CACHE
            };
        }

        var stateLocation = weatherProviderLoadStateLocation();
        if (stateLocation != null) {
            return {
                "location" => stateLocation,
                "source" => WEATHER_PROVIDER_LOCATION_SOURCE_STATE
            };
        }

        return {
            "location" => null,
            "source" => WEATHER_PROVIDER_LOCATION_SOURCE_UNAVAILABLE
        };
    }

    hidden function persistFailureState(responseCode as Number, message as String, context as Dictionary) as Void {
        weatherProviderStoreState(weatherProviderBuildState(
            WEATHER_PROVIDER_OPEN_METEO_NAME,
            weatherProviderToNumber(context.get("lastAttemptAt")),
            weatherProviderToNumber(context.get("lastSuccessAt")),
            responseCode,
            message,
            context.get("locationSource") as String?,
            context.get("location") as Array?
        ));
    }

    hidden function logOpenMeteoRequestFailure(message as String, responseCode as Number, context as Dictionary) as Void {
        var locationSource = context.get("locationSource") as String?;
        var location = weatherProviderNormalizeLocation(context.get("location") as Array?);
        var locationText = "unknown";
        if (location != null) {
            locationText = (location[0] as Float).format("%.4f") + "," + (location[1] as Float).format("%.4f");
        }

        System.println(
            "Open-Meteo request failure"
            + ": code=" + responseCode.format("%d")
            + ", message=" + message
            + ", locationSource=" + ((locationSource == null) ? "unknown" : locationSource)
            + ", location=" + locationText
        );
    }
}
