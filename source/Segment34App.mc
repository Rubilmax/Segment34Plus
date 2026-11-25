import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

(:background)
class Segment34App extends Application.AppBase {
    
    (:typecheck(disableBackgroundCheck))
    var mView as Segment34View or Null;
    
    function initialize() {
        AppBase.initialize();
    }

    // Return the initial view of your application here
    // AppBase is shared with the background process, but this callback is
    // foreground-only and intentionally wires up UI classes.
    (:typecheck(disableBackgroundCheck))
    function getInitialView() {
        var view = new Segment34View();
        mView = view;
        var delegate = new Segment34Delegate(view);
        return [view, delegate];
    }

    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new Segment34WeatherServiceDelegate()];
    }

    (:typecheck(disableBackgroundCheck))
    function onSettingsChanged() as Void {
        if (mView != null) {
            mView.onSettingsChanged();
        } else if (!weatherProviderUsesOpenMeteo() || !weatherProviderIsWeatherRequired()) {
            weatherProviderDeleteScheduledRefresh();
        }
    }

    (:typecheck(disableBackgroundCheck))
    function onStorageChanged() as Void {
        if (mView != null) {
            mView.onWeatherDataChanged();
        }
        WatchUi.requestUpdate();
    }

    (:typecheck(disableBackgroundCheck))
    function onBackgroundData(data) as Void {
        var applied = false;
        try {
            if (!weatherProviderUsesOpenMeteo() || !weatherProviderIsWeatherRequired()) { return; }
            applied = weatherProviderApplyBackgroundPayload(data);
        } catch(e) {
            System.println("Open-Meteo background payload apply failure: " + e);
        }

        if (!applied) {
            return;
        }

        if (mView != null) {
            mView.onWeatherDataChanged();
        }
        WatchUi.requestUpdate();
    }
}

function getApp() as Segment34App {
    return Application.getApp() as Segment34App;
}
