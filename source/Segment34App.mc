import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class Segment34App extends Application.AppBase {
    
    var mView;
    
    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        scheduleWeatherRefresh();
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() {
        mView = new Segment34View();
        onSettingsChanged();
        var delegate = new Segment34Delegate(mView);
        return [mView, delegate];
    }

    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new Segment34WeatherServiceDelegate()];
    }

    function onSettingsChanged() as Void {
        if (mView != null) {
            mView.onSettingsChanged();
        }
        scheduleWeatherRefresh();
        WatchUi.requestUpdate();
    }

    function onStorageChanged() as Void {
        if (mView != null) {
            mView.onWeatherDataChanged();
        }
        WatchUi.requestUpdate();
    }

    function onBackgroundData(data) as Void {
        if (mView != null) {
            mView.onWeatherDataChanged();
        }
        WatchUi.requestUpdate();
    }

    hidden function scheduleWeatherRefresh() as Void {
        if (!weatherProviderUsesOpenMeteo() || !weatherProviderIsWeatherRequired()) {
            try {
                Background.deleteTemporalEvent();
            } catch(e) {}
            return;
        }

        weatherProviderPrimeGarminLocationCache();

        if (mView != null) {
            mView.scheduleImmediateCustomWeatherRefreshIfNeeded();
        } else {
            weatherProviderScheduleImmediateRefreshIfNeeded();
        }
    }

}

function getApp() as Segment34App {
    return Application.getApp() as Segment34App;
}
