import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Timer;
import Toybox.UserProfile;
import Toybox.WatchUi;

const HR_SAMPLE_CACHE_INTERVAL_MS = 250;
const HR_BLINK_PULSE_MS = 125;
const HR_BLINK_WINDOW_MS = 500;
const HR_BLINK_CYCLE_MS = 1500;
const HR_BLINK_THRESHOLD_PERCENT = 90;
const HR_FADE_FALLBACK_START_PERCENT = 60;

var hrBlinkTimer = null;
var hrBlinkTimerRunning = false;
var hrBlinkActive = false;
var hrCachedSample = null;
var hrCachedSampleValid = false;
var hrCachedSampleTimestampMs = 0;

function hrResetState() as Void {
    hrBlinkActive = false;
    hrCachedSample = null;
    hrCachedSampleValid = false;
    hrCachedSampleTimestampMs = 0;
    hrStopBlinkTimer();
}

function hrStopBlinkTimer() as Void {
    if (hrBlinkTimer != null && hrBlinkTimerRunning) {
        hrBlinkTimer.stop();
    }
    hrBlinkTimerRunning = false;
}

function hrOnBlinkTimerTick() as Void {
    WatchUi.requestUpdate();
}

function hrIsLiveHeartRateComplication(complicationType as Number) as Boolean {
    return complicationType == 10;
}

function hrHasActiveDisplay(displayTypes as Array<Number>) as Boolean {
    for (var i = 0; i < displayTypes.size(); i++) {
        if (hrIsLiveHeartRateComplication(displayTypes[i])) {
            return true;
        }
    }
    return false;
}

function hrReadCurrentHeartRateSample() as Number? {
    var sample = null;
    var activityInfo = Activity.getActivityInfo();
    if (activityInfo != null) {
        sample = activityInfo.currentHeartRate;
    }

    if (sample == null && (ActivityMonitor has :getHeartRateHistory)) {
        var history = ActivityMonitor.getHeartRateHistory(1, true);
        if (history != null) {
            var hist = history.next();
            if (hist != null && hist.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                sample = hist.heartRate;
            }
        }
    }

    return sample;
}

function hrGetCurrentHeartRateSample() as Number? {
    var nowMs = System.getTimer();
    if (hrCachedSampleValid && (nowMs - hrCachedSampleTimestampMs) < HR_SAMPLE_CACHE_INTERVAL_MS) {
        return hrCachedSample;
    }

    hrCachedSample = hrReadCurrentHeartRateSample();
    hrCachedSampleValid = true;
    hrCachedSampleTimestampMs = nowMs;
    return hrCachedSample;
}

function hrGetHeartRateZones() as Array? {
    var sport = null;
    var zones = null;

    if (UserProfile has :getCurrentSport) {
        try {
            sport = UserProfile.getCurrentSport();
        } catch(e) {}
    }

    if (sport == null && UserProfile has :HR_ZONE_SPORT_GENERIC) {
        sport = UserProfile.HR_ZONE_SPORT_GENERIC;
    }

    if (sport != null && UserProfile has :getHeartRateZones) {
        try {
            zones = UserProfile.getHeartRateZones(sport);
        } catch(e) {}
    }

    if (zones == null && UserProfile has :HR_ZONE_SPORT_GENERIC && UserProfile has :getHeartRateZones) {
        try {
            zones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);
        } catch(e) {}
    }

    return zones;
}

function hrGetMaxHeartRate() as Number? {
    var profile = UserProfile.getProfile();
    if (profile != null && profile has :maxHeartRate) {
        return profile.maxHeartRate;
    }
    return null;
}

function hrGetFadeStartBpm(maxHeartRate as Number?) as Number? {
    if (maxHeartRate == null || maxHeartRate <= 0) {
        return null;
    }

    var zones = hrGetHeartRateZones();
    if (zones != null && zones.size() > 0) {
        var minZone1 = zones[0];
        if (minZone1 != null && minZone1 > 0 && minZone1 < maxHeartRate) {
            return minZone1;
        }
    }

    var fallbackStart = Math.round((maxHeartRate * HR_FADE_FALLBACK_START_PERCENT) / 100.0).toNumber();
    if (fallbackStart <= 0 || fallbackStart >= maxHeartRate) {
        return null;
    }
    return fallbackStart;
}

function hrGetFadePercent(hr as Number?, startBpm as Number?, maxHeartRate as Number?) as Number {
    if (hr == null || startBpm == null || maxHeartRate == null || startBpm >= maxHeartRate || hr <= startBpm) {
        return 0;
    }
    if (hr >= maxHeartRate) {
        return 100;
    }
    return Math.round(((hr - startBpm) * 100.0) / (maxHeartRate - startBpm)).toNumber();
}

function hrBlendColorChannel(baseChannel as Number, accentChannel as Number, accentPercent as Number) as Number {
    return Math.round(((baseChannel * (100 - accentPercent)) + (accentChannel * accentPercent)) / 100.0).toNumber();
}

function hrBlendColor(baseColor as Graphics.ColorType, accentColor as Graphics.ColorType, accentPercent as Number) as Graphics.ColorType {
    var red = hrBlendColorChannel((baseColor >> 16) & 0xFF, (accentColor >> 16) & 0xFF, accentPercent);
    var green = hrBlendColorChannel((baseColor >> 8) & 0xFF, (accentColor >> 8) & 0xFF, accentPercent);
    var blue = hrBlendColorChannel(baseColor & 0xFF, accentColor & 0xFF, accentPercent);
    return (red << 16) | (green << 8) | blue;
}

function hrGetDangerColor(backgroundColor as Graphics.ColorType) as Graphics.ColorType {
    if (backgroundColor == 0xFFFFFF) {
        return 0xB00000;
    }
    return 0xFF4A4A;
}

function hrGetBaseDangerColor(backgroundColor as Graphics.ColorType) as Graphics.ColorType {
    if (backgroundColor == 0xFFFFFF) {
        return 0x550000;
    }
    return 0xAA2020;
}

function hrGetDisplayValueColor(complicationType as Number, defaultColor as Graphics.ColorType, backgroundColor as Graphics.ColorType) as Graphics.ColorType {
    if (!hrIsLiveHeartRateComplication(complicationType)) {
        return defaultColor;
    }

    var maxHeartRate = hrGetMaxHeartRate();
    var accentPercent = hrGetFadePercent(hrGetCurrentHeartRateSample(), hrGetFadeStartBpm(maxHeartRate), maxHeartRate);
    if (accentPercent <= 0) {
        return defaultColor;
    }
    return hrBlendColor(hrGetBaseDangerColor(backgroundColor), hrGetDangerColor(backgroundColor), accentPercent);
}

function hrRefreshBlinkState(displayTypes as Array<Number>) as Void {
    if (!hrHasActiveDisplay(displayTypes)) {
        hrBlinkActive = false;
        return;
    }

    var maxHeartRate = hrGetMaxHeartRate();
    var sample = hrGetCurrentHeartRateSample();
    hrBlinkActive = sample != null
        && maxHeartRate != null
        && maxHeartRate > 0
        && (sample * 100) >= (maxHeartRate * HR_BLINK_THRESHOLD_PERCENT);
}

function hrShouldBlink(visible as Boolean, isSleeping as Boolean, displayTypes as Array<Number>) as Boolean {
    if (!visible || isSleeping || !hrHasActiveDisplay(displayTypes)) {
        return false;
    }
    return hrBlinkActive;
}

function hrSyncBlinkTimer(visible as Boolean, isSleeping as Boolean, displayTypes as Array<Number>) as Void {
    if (!hrShouldBlink(visible, isSleeping, displayTypes)) {
        hrStopBlinkTimer();
        return;
    }

    if (hrBlinkTimer == null) {
        hrBlinkTimer = new Timer.Timer();
    }
    if (!hrBlinkTimerRunning) {
        hrBlinkTimer.start(new Lang.Method($, :hrOnBlinkTimerTick), HR_BLINK_PULSE_MS, true);
        hrBlinkTimerRunning = true;
    }
}

function hrShouldDrawValue(complicationType as Number, visible as Boolean, isSleeping as Boolean, displayTypes as Array<Number>) as Boolean {
    if (!hrIsLiveHeartRateComplication(complicationType)) {
        return true;
    }
    if (!hrShouldBlink(visible, isSleeping, displayTypes)) {
        return true;
    }

    var blinkPhaseMs = System.getTimer() % HR_BLINK_CYCLE_MS;
    if (blinkPhaseMs >= HR_BLINK_WINDOW_MS) {
        return true;
    }

    return !(blinkPhaseMs < HR_BLINK_PULSE_MS
        || (blinkPhaseMs >= HR_BLINK_PULSE_MS * 2 && blinkPhaseMs < HR_BLINK_PULSE_MS * 3));
}

function hrDrawNotificationValue(dc, x as Number, y as Number, value as String, suffix as String, fontSmallData, drawConfig as Array) as Void {
    var valueColor = drawConfig[0];
    var notifColor = drawConfig[1];
    var justification = drawConfig[2];
    var showValue = drawConfig[3];
    if (value.length() == 0 && suffix.length() == 0) {
        return;
    }

    var valueWidth = value.length() > 0 ? dc.getTextWidthInPixels(value, fontSmallData) : 0;
    var suffixWidth = suffix.length() > 0 ? dc.getTextWidthInPixels(suffix, fontSmallData) : 0;

    if (justification == Graphics.TEXT_JUSTIFY_RIGHT) {
        if (suffix.length() > 0) {
            dc.setColor(notifColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, y, fontSmallData, suffix, Graphics.TEXT_JUSTIFY_RIGHT);
        }
        if (showValue && value.length() > 0) {
            dc.setColor(valueColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x - suffixWidth, y, fontSmallData, value, Graphics.TEXT_JUSTIFY_RIGHT);
        }
        return;
    }

    if (justification == Graphics.TEXT_JUSTIFY_CENTER) {
        var totalWidth = valueWidth + suffixWidth;
        var leftX = x - Math.round(totalWidth / 2.0);
        if (showValue && value.length() > 0) {
            dc.setColor(valueColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(leftX, y, fontSmallData, value, Graphics.TEXT_JUSTIFY_LEFT);
        }
        if (suffix.length() > 0) {
            dc.setColor(notifColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(leftX + valueWidth, y, fontSmallData, suffix, Graphics.TEXT_JUSTIFY_LEFT);
        }
        return;
    }

    if (showValue && value.length() > 0) {
        dc.setColor(valueColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, fontSmallData, value, Graphics.TEXT_JUSTIFY_LEFT);
    }
    if (suffix.length() > 0) {
        dc.setColor(notifColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + valueWidth, y, fontSmallData, suffix, Graphics.TEXT_JUSTIFY_LEFT);
    }
}
