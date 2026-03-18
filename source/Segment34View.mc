import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Weather;
import Toybox.Complications;
using Toybox.Position;

class Segment34View extends WatchUi.WatchFace {

    hidden var visible as Boolean = true;
    hidden var screenHeight as Number;
    hidden var screenWidth as Number;
    (:initialized) hidden var clockHeight as Number;
    (:initialized) hidden var clockWidth as Number;
    (:initialized) hidden var labelHeight as Number;
    (:initialized) hidden var labelMargin as Number;
    (:initialized) hidden var tinyDataHeight as Number;
    (:initialized) hidden var smallDataHeight as Number;
    (:initialized) hidden var largeDataHeight as Number;
    (:initialized) hidden var largeDataWidth as Number;
    (:initialized) hidden var bottomDataWidth as Number;
    (:initialized) hidden var baseX as Number;
    (:initialized) hidden var baseY as Number;
    hidden var centerX as Number;
    hidden var centerY as Number;
    hidden var marginX as Number;
    hidden var marginY as Number;
    hidden var halfMarginY as Number;
    hidden var halfClockHeight as Number;
    hidden var halfClockWidth as Number;
    hidden var barBottomAdj as Number = 0;
    hidden var bottomFiveAdj as Number = 0;
    hidden var fieldSpaceingAdj as Number = 0;
    hidden var textSideAdj as Number = 0;
    hidden var iconYAdj as Number = 0;

    hidden var fontMoon as WatchUi.FontResource;
    hidden var fontIcons as WatchUi.FontResource;
    (:initialized) hidden var fontClock as WatchUi.FontResource;
    (:initialized) hidden var fontClockOutline as WatchUi.FontResource;
    (:initialized) hidden var fontLabel as WatchUi.FontResource;
    (:initialized) hidden var fontTinyData as WatchUi.FontResource;
    (:initialized) hidden var fontSmallData as WatchUi.FontResource;
    (:initialized) hidden var fontLargeData as WatchUi.FontResource;
    (:initialized) hidden var fontAODData as WatchUi.FontResource;
    (:initialized) hidden var fontBottomData as WatchUi.FontResource;
    (:initialized) hidden var fontBattery as WatchUi.FontResource;
    hidden var weekNames as Array<String>?;
    hidden var monthNames as Array<String>?;

    // Layout Caching
    hidden var cachedFieldWidths as Array<Number> = [0, 0, 0, 0];
    hidden var cachedSysStats as System.Stats?;
    hidden var wakeTimestamp as Number = 0;
    hidden var lastWeatherPhase as Number = -1;
    hidden var cachedStressData as Number? = null;
    hidden var cachedStressDataValid as Boolean = false;
    hidden var cachedBBData as Number? = null;
    hidden var cachedBBDataValid as Boolean = false;
    hidden var fieldXCoords as Array<Number> = [0, 0, 0, 0];
    hidden var fieldY as Number = 0;
    hidden var bottomFiveY as Number = 0;
    (:Square) hidden var bottomFive1X as Number = 0;
    (:Square) hidden var bottomFive2X as Number = 0;
    (:Square) hidden var dualBottomFieldActive as Boolean = false;
    (:Square) hidden var bottomFiveYOriginal as Number = 0;

    hidden var drawGradient as BitmapResource?;
    hidden var drawAODPattern as BitmapResource?;
    
    hidden var themeColors as Array<Graphics.ColorType> = [];
    (:WeatherCache) hidden var weatherCondition as CurrentConditions or StoredWeather or Null;
    (:NoWeatherCache) hidden var weatherCondition as CurrentConditions or Null;
    hidden var canBurnIn as Boolean = false;
    hidden var isSleeping as Boolean = false;
    hidden var lastUpdate as Number? = null;
    hidden var lastSlowUpdate as Number? = null;
    hidden var cachedValues as Dictionary = {};
    hidden var refreshCache as Dictionary = {};
    hidden var cachedTempUnit as String = "C";

    hidden var isWeatherRequired as Boolean = false;
    (:WeatherCache) hidden var lastHfTime as Number? = null;
    (:WeatherCache) hidden var lastCcHash as Number? = null;
    hidden var isLowMem as Boolean = false;

    hidden var doesPartialUpdate as Boolean = false;
    hidden var hasComplications as Boolean = false;

    // CGM Connect Widget complication IDs
    hidden var cgmComplicationId as Complications.Id? = null;
    hidden var cgmAgeComplicationId as Complications.Id? = null;
    
    // Packed settings to keep the watch face under the class member limit on MIP devices.
    // propBitmapA: theme[0:4], outline[5:7], clockFont[8], reserved[9:10], showSeconds[11],
    // alwaysShowSeconds[12], clockBg[13], dataBg[14], aodStyle[15:16], aodAlign[17],
    // dateAlign[18], bottomAlign[19:20], bottomLabelAlign[21:22], hemisphere[23],
    // hourFormat[24:25], zeropadHour[26], timeSeparator[27:28], tempUnit[29:30]
    // propBitmapB: showTempUnit[0], windUnit[1:3], pressureUnit[4:5], topPartShows[6],
    // dateFormat[7:10], labelVisibility[11:12], smallFontVariant[13:14],
    // stressDynamicColor[15], is24H[16], reserved[17:22], fieldLayout[23:26]
    hidden var propBitmapA as Number = 0;
    hidden var propBitmapB as Number = 0;
    hidden var propLeftValueShows as Number = 6;
    hidden var propMiddleValueShows as Number = 10;
    hidden var propRightValueShows as Number = 0;
    hidden var propFourthValueShows as Number = 0;
    hidden var propAodFieldShows as Number = -1;
    hidden var propAodRightFieldShows as Number = -2;
    hidden var propDateFieldShows as Number = -1;
    hidden var propBottomFieldShows as Number = 17;
    (:Square) hidden var propBottomField2Shows as Number = -2;
    hidden var propLeftBarShows as Number = 1;
    hidden var propRightBarShows as Number = 2;
    hidden var propIcon1 as Number = 1;
    hidden var propIcon2 as Number = 2;
    hidden var propSunriseFieldShows as Number = 39;
    hidden var propSunsetFieldShows as Number = 40;
    hidden var propWeatherLine1Shows as Number = 49;
    hidden var propWeatherLine2Shows as Number = 79;
    hidden var cachedHourlyForecast as Array<ForecastWeather> = [];
    hidden var cachedForecastChange as Array? = null;
    hidden var cachedForecastWorse as Array? = null;
    hidden var cachedLineForecastChange as Array? = null;
    hidden var cachedLineForecastWorse as Array? = null;
    hidden var lineWeatherCondition as ForecastWeather or Null = null;
    hidden var weatherConditionOverride as ForecastWeather or Null = null;
    hidden var forecastChangeOverride as Array? = null;
    hidden var forecastWorseOverride as Array? = null;
    hidden var propNotificationCountShows as Number = 36;
    hidden var propWeekOffset as Number = 0;

    // Cached Labels
    hidden var strLabelTopLeft as String = "";
    hidden var strLabelTopRight as String = "";
    hidden var strLabelBottomLeft as String = "";
    hidden var strLabelBottomMiddle as String = "";
    hidden var strLabelBottomRight as String = "";
    hidden var strLabelBottomFourth as String = "";

    // Cached unit strings (loaded once from resources)
    hidden var cachedUnitKcal as String = "";
    hidden var cachedUnitM as String = "";
    hidden var cachedUnitFt as String = "";
    hidden var cachedUnitSteps as String = "";
    hidden var cachedUnitPushes as String = "";
    hidden var cachedLabelNa as String = "";
    hidden var cachedLabelPosNa as String = "";
    hidden var cachedLabelFl as String = "";

    const battFull = "|||||||||||||||||||||||||||||||||||";
    const battEmpty = "{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{";
    const fullUpdateIntervalS = 60;

    // Pre-computed background strings to avoid per-frame string concatenation
    hidden var bgStrings as Array<String> = ["", "#", "##", "###", "####", "#####"];
    hidden var bgStringsAlt as Array<String> = ["", "$", "$$", "$$$", "$$$$", "$$$$$"];

    // Cached weather condition resource IDs to avoid per-frame array allocation
    hidden var cachedWeatherResIds as Array = [
        Rez.Strings.WEATHER_0, Rez.Strings.WEATHER_1, Rez.Strings.WEATHER_2, Rez.Strings.WEATHER_3,
        Rez.Strings.WEATHER_4, Rez.Strings.WEATHER_5, Rez.Strings.WEATHER_6, Rez.Strings.WEATHER_7,
        Rez.Strings.WEATHER_8, Rez.Strings.WEATHER_9, Rez.Strings.WEATHER_10, Rez.Strings.WEATHER_11,
        Rez.Strings.WEATHER_12, Rez.Strings.WEATHER_13, Rez.Strings.WEATHER_14, Rez.Strings.WEATHER_15,
        Rez.Strings.WEATHER_16, Rez.Strings.WEATHER_17, Rez.Strings.WEATHER_18, Rez.Strings.WEATHER_19,
        Rez.Strings.WEATHER_20, Rez.Strings.WEATHER_21, Rez.Strings.WEATHER_22, Rez.Strings.WEATHER_23,
        Rez.Strings.WEATHER_24, Rez.Strings.WEATHER_25, Rez.Strings.WEATHER_26, Rez.Strings.WEATHER_27,
        Rez.Strings.WEATHER_28, Rez.Strings.WEATHER_29, Rez.Strings.WEATHER_30, Rez.Strings.WEATHER_31,
        Rez.Strings.WEATHER_32, Rez.Strings.WEATHER_33, Rez.Strings.WEATHER_34, Rez.Strings.WEATHER_35,
        Rez.Strings.WEATHER_36, Rez.Strings.WEATHER_37, Rez.Strings.WEATHER_38, Rez.Strings.WEATHER_39,
        Rez.Strings.WEATHER_40, Rez.Strings.WEATHER_41, Rez.Strings.WEATHER_42, Rez.Strings.WEATHER_43,
        Rez.Strings.WEATHER_44, Rez.Strings.WEATHER_45, Rez.Strings.WEATHER_46, Rez.Strings.WEATHER_47,
        Rez.Strings.WEATHER_48, Rez.Strings.WEATHER_49, Rez.Strings.WEATHER_50, Rez.Strings.WEATHER_51,
        Rez.Strings.WEATHER_52, Rez.Strings.WEATHER_53
    ];

    enum colorNames {
        bg = 0,
        clock,
        clockBg,
        outline,
        dataVal,
        fieldBg,
        fieldLbl,
        date,
        dateDim,
        notif,
        stress,
        bodybatt,
        moon,
        lowBatt
    }

    var clockBgText = "#####";

    (:Round240) const bottomFieldWidths = [3, 3, 3, 0];
    (:Round260) const bottomFieldWidths = [3, 4, 3, 0];
    (:Round280) const bottomFieldWidths = [4, 3, 4, 0];
    (:Round360) const bottomFieldWidths = [3, 4, 3, 0];
    (:Round390) const bottomFieldWidths = [4, 3, 4, 0];
    (:InstinctCrossover) const bottomFieldWidths = [4, 3, 4, 0];
    (:Round416) const bottomFieldWidths = [4, 4, 4, 0];
    (:Round454) const bottomFieldWidths = [4, 4, 4, 0];
    (:Square) const bottomFieldWidths = [4, 4, 4, 0];

    (:Round240) const barWidth = 3;
    (:Round260) const barWidth = 3;
    (:Round280) const barWidth = 3;
    (:Round360) const barWidth = 3;
    (:Round390) const barWidth = 4;
    (:InstinctCrossover) const barWidth = 4;
    (:Round416) const barWidth = 4;
    (:Round454) const barWidth = 4;
    (:Square) const barWidth = 4;

    function initialize() {
        WatchFace.initialize();

        if(System.getDeviceSettings() has :requiresBurnInProtection) { canBurnIn = System.getDeviceSettings().requiresBurnInProtection; }
        updateProperties();
        
        screenHeight = Toybox.System.getDeviceSettings().screenHeight;
        screenWidth = Toybox.System.getDeviceSettings().screenWidth;
        fontMoon = Application.loadResource(Rez.Fonts.moon);
        fontIcons = Application.loadResource(Rez.Fonts.icons);
        centerX = Math.round(screenWidth / 2);
        centerY = Math.round(screenHeight / 2);
        marginY = Math.round(screenHeight / 30);
        marginX = Math.round(screenWidth / 20);
        
        loadResources();

        halfClockHeight = Math.round(clockHeight / 2);
        if(clockBgText.length() == 4) {
            halfClockWidth = Math.round((clockWidth / 5 * 4.2) / 2);
        } else {
            halfClockWidth = Math.round(clockWidth / 2);
        }
        
        halfMarginY = Math.round(marginY / 2);
        hasComplications = Toybox has :Complications;

        // Cache string resources (loadResource reads from flash each call)
        cachedUnitKcal = Application.loadResource(Rez.Strings.UNIT_KCAL);
        cachedUnitM = Application.loadResource(Rez.Strings.UNIT_M);
        cachedUnitFt = Application.loadResource(Rez.Strings.UNIT_FT);
        cachedUnitSteps = Application.loadResource(Rez.Strings.UNIT_STEPS);
        cachedUnitPushes = Application.loadResource(Rez.Strings.UNIT_PUSHES);
        cachedLabelNa = Application.loadResource(Rez.Strings.LABEL_NA);
        cachedLabelPosNa = Application.loadResource(Rez.Strings.LABEL_POS_NA);
        cachedLabelFl = Application.loadResource(Rez.Strings.LABEL_FL);

        calculateLayout();

        updateWeather();
    }

    hidden function updateActiveLabels() as Void {
        cachedFieldWidths = getFieldWidths();
        strLabelTopLeft = getLabelByType(propSunriseFieldShows, 1);
        strLabelTopRight = getLabelByType(propSunsetFieldShows, 1);
        strLabelBottomLeft = getLabelByType(propLeftValueShows, cachedFieldWidths[0] - 1);
        strLabelBottomMiddle = getLabelByType(propMiddleValueShows, cachedFieldWidths[1] - 1);
        strLabelBottomRight = getLabelByType(propRightValueShows, cachedFieldWidths[2] - 1);
        strLabelBottomFourth = getLabelByType(propFourthValueShows, cachedFieldWidths[3] - 1);
    }

    hidden function loadSmallFont(resDefault, resReadable, resLines) as Void {
        var propSmallFontVariant = (propBitmapB >> 13) & 0x3;
        var selectedRes = resLines;
        if (propSmallFontVariant == 0) {
            selectedRes = resDefault;
        } else if (propSmallFontVariant == 1) {
            selectedRes = resReadable;
        }
        fontSmallData = Application.loadResource(selectedRes);
    }

    (:Round240)
    hidden function loadResources() as Void {
        var propClockFont = (propBitmapA >> 8) & 0x1;
        if(propClockFont == 0) {
            fontClock = Application.loadResource(Rez.Fonts.segments80narrow);
        } else {
            fontClock = Application.loadResource(Rez.Fonts.segments80narrow_2);
        }
        fontTinyData = Application.loadResource(Rez.Fonts.smol);
        loadSmallFont(Rez.Fonts.led_small, Rez.Fonts.led_small_readable, Rez.Fonts.led_small_lines);
        fontLargeData = Application.loadResource(Rez.Fonts.led);
        fontBottomData = Application.loadResource(Rez.Fonts.led_small);
        fontLabel = Application.loadResource(Rez.Fonts.xsmol);
        fontBattery = fontTinyData;

        clockHeight = 80;
        clockWidth = 220;
        labelHeight = 5;
        labelMargin = 6;
        tinyDataHeight = 8;
        smallDataHeight = 13;
        largeDataHeight = 20;
        largeDataWidth = 18;
        bottomDataWidth = 12;

        baseX = centerX;
        baseY = centerY - smallDataHeight + 4;
        marginY = Math.round(screenHeight / 35);
        fieldSpaceingAdj = 10;
        barBottomAdj = 1;
    }

    (:Round260)
    hidden function loadResources() as Void {
        var propClockFont = (propBitmapA >> 8) & 0x1;
        if(propClockFont == 0) {
            fontClock = Application.loadResource(Rez.Fonts.segments80);
        } else {
            fontClock = Application.loadResource(Rez.Fonts.segments80_2);
        }
        fontTinyData = Application.loadResource(Rez.Fonts.smol);
        loadSmallFont(Rez.Fonts.led_small, Rez.Fonts.led_small_readable, Rez.Fonts.led_small_lines);
        fontLargeData = Application.loadResource(Rez.Fonts.led);
        fontBottomData = fontLargeData;
        fontLabel = Application.loadResource(Rez.Fonts.xsmol);
        fontBattery = fontTinyData;

        clockHeight = 80;
        clockWidth = 227;
        labelHeight = 5;
        labelMargin = 6;
        tinyDataHeight = 8;
        smallDataHeight = 13;
        largeDataHeight = 20;
        largeDataWidth = 18;
        bottomDataWidth = 18;

        baseX = centerX + 1;
        baseY = centerY - smallDataHeight - 1;
        fieldSpaceingAdj = 15;
        bottomFiveAdj = 2;
        barBottomAdj = 1;
    }

    (:Round280)
    hidden function loadResources() as Void {
        var propClockFont = (propBitmapA >> 8) & 0x1;
        if(propClockFont == 0) {
            fontClock = Application.loadResource(Rez.Fonts.segments80wide);
        } else {
            fontClock = Application.loadResource(Rez.Fonts.segments80wide_2);
        }
        fontTinyData = Application.loadResource(Rez.Fonts.storre);
        loadSmallFont(Rez.Fonts.led_small, Rez.Fonts.led_small_readable, Rez.Fonts.led_small_lines);
        fontLargeData = Application.loadResource(Rez.Fonts.led);
        fontBottomData = fontLargeData;
        fontLabel = Application.loadResource(Rez.Fonts.smol);
        fontBattery = fontLabel;

        clockHeight = 80;
        clockWidth = 236;
        labelHeight = 8;
        labelMargin = 6;
        tinyDataHeight = 10;
        smallDataHeight = 13;
        largeDataHeight = 20;
        largeDataWidth = 18;
        bottomDataWidth = 18;

        baseX = centerX;
        baseY = centerY - smallDataHeight - 4;
        bottomFiveAdj = 5;
        barBottomAdj = 1;
    }

    (:Round360)
    hidden function loadResources() as Void {
        var propClockFont = (propBitmapA >> 8) & 0x1;
        if(propClockFont == 0) {
            fontClock = Application.loadResource(Rez.Fonts.segments125narrow);
            fontClockOutline = Application.loadResource(Rez.Fonts.segments125narrowoutline);
        } else {
            fontClock = Application.loadResource(Rez.Fonts.segments125narrow_2);
            fontClockOutline = Application.loadResource(Rez.Fonts.segments125narrowoutline_2);
        }
        fontTinyData = Application.loadResource(Rez.Fonts.storre);
        loadSmallFont(Rez.Fonts.led, Rez.Fonts.led_inbetween, Rez.Fonts.led_lines);
        fontLargeData = Application.loadResource(Rez.Fonts.led_big);
        fontBottomData = Application.loadResource(Rez.Fonts.led);
        fontLabel = Application.loadResource(Rez.Fonts.smol);
        fontAODData = fontBottomData;
        fontBattery = Application.loadResource(Rez.Fonts.led_small_lines);

        drawGradient = Application.loadResource(Rez.Drawables.gradient) as BitmapResource;
        drawAODPattern = Application.loadResource(Rez.Drawables.aod) as BitmapResource;

        clockHeight = 125;
        clockWidth = 345;
        labelHeight = 8;
        labelMargin = 8;
        tinyDataHeight = 10;
        smallDataHeight = 20;
        largeDataHeight = 27;
        largeDataWidth = 24;
        bottomDataWidth = 18;

        baseX = centerX;
        baseY = centerY - smallDataHeight + 4;
        fieldSpaceingAdj = 20;
        barBottomAdj = 2;
        textSideAdj = 10;
        iconYAdj = -4;
        marginY = 10;
    }

    (:Round390)
    hidden function loadResources() as Void {
        var propClockFont = (propBitmapA >> 8) & 0x1;
        if(propClockFont == 0) {
            fontClock = Application.loadResource(Rez.Fonts.segments125);
            fontClockOutline = Application.loadResource(Rez.Fonts.segments125outline);
        } else {
            fontClock = Application.loadResource(Rez.Fonts.segments125_2);
            fontClockOutline = Application.loadResource(Rez.Fonts.segments125outline_2);
        }
        fontTinyData = Application.loadResource(Rez.Fonts.led_small_lines);
        loadSmallFont(Rez.Fonts.led, Rez.Fonts.led_inbetween, Rez.Fonts.led_lines);
        fontLargeData = Application.loadResource(Rez.Fonts.led_big);
        fontBottomData = fontLargeData;
        fontLabel = Application.loadResource(Rez.Fonts.storre);
        fontAODData = Application.loadResource(Rez.Fonts.led);
        fontBattery = fontTinyData;

        drawGradient = Application.loadResource(Rez.Drawables.gradient) as BitmapResource;
        drawAODPattern = Application.loadResource(Rez.Drawables.aod) as BitmapResource;

        clockHeight = 125;
        clockWidth = 355;
        labelHeight = 10;
        labelMargin = 8;
        tinyDataHeight = 13;
        smallDataHeight = 20;
        largeDataHeight = 27;
        largeDataWidth = 24;
        bottomDataWidth = 24;

        baseX = centerX;
        baseY = centerY - smallDataHeight - 3;
        barBottomAdj = 2;
        bottomFiveAdj = 6;
        marginY = 10;
    }

    (:InstinctCrossover)
    hidden function loadResources() as Void {
        var propClockFont = (propBitmapA >> 8) & 0x1;
        if(propClockFont == 0) {
            fontClock = Application.loadResource(Rez.Fonts.segments125);
            fontClockOutline = Application.loadResource(Rez.Fonts.segments125outline);
        } else {
            fontClock = Application.loadResource(Rez.Fonts.segments125_2);
            fontClockOutline = Application.loadResource(Rez.Fonts.segments125outline_2);
        }
        fontTinyData = Application.loadResource(Rez.Fonts.led_small_lines);
        loadSmallFont(Rez.Fonts.led, Rez.Fonts.led_inbetween, Rez.Fonts.led_lines);
        fontLargeData = Application.loadResource(Rez.Fonts.led_big);
        fontBottomData = fontLargeData;
        fontLabel = Application.loadResource(Rez.Fonts.storre);
        fontAODData = Application.loadResource(Rez.Fonts.led);
        fontBattery = fontTinyData;

        drawGradient = Application.loadResource(Rez.Drawables.gradient) as BitmapResource;
        drawAODPattern = Application.loadResource(Rez.Drawables.aod) as BitmapResource;

        clockHeight = 125;
        clockWidth = 350;
        labelHeight = 10;
        labelMargin = 8;
        tinyDataHeight = 15;
        smallDataHeight = 20;
        largeDataHeight = 27;
        largeDataWidth = 24;
        bottomDataWidth = 24;

        baseX = centerX;
        baseY = centerY;  // Centered for analog hands
        barBottomAdj = 2;
        bottomFiveAdj = 10;
        marginY = 9;
    }

    (:Round416)
    hidden function loadResources() as Void {
        var propClockFont = (propBitmapA >> 8) & 0x1;
        if(propClockFont == 0) {
            fontClock = Application.loadResource(Rez.Fonts.segments125);
            fontClockOutline = Application.loadResource(Rez.Fonts.segments125outline);
        } else {
            fontClock = Application.loadResource(Rez.Fonts.segments125_2);
            fontClockOutline = Application.loadResource(Rez.Fonts.segments125outline_2);
        }
        fontTinyData = Application.loadResource(Rez.Fonts.led_small_lines);
        loadSmallFont(Rez.Fonts.led, Rez.Fonts.led_inbetween, Rez.Fonts.led_lines);
        fontLargeData = Application.loadResource(Rez.Fonts.led_big);
        fontBottomData = fontLargeData;
        fontLabel = Application.loadResource(Rez.Fonts.storre);
        fontAODData = Application.loadResource(Rez.Fonts.led);
        fontBattery = fontTinyData;

        drawGradient = Application.loadResource(Rez.Drawables.gradient) as BitmapResource;
        drawAODPattern = Application.loadResource(Rez.Drawables.aod) as BitmapResource;

        clockHeight = 125;
        clockWidth = 360;
        labelHeight = 10;
        labelMargin = 8;
        tinyDataHeight = 13;
        smallDataHeight = 20;
        largeDataHeight = 27;
        largeDataWidth = 24;
        bottomDataWidth = 24;

        baseX = centerX;
        baseY = centerY - smallDataHeight - 5;
        barBottomAdj = 2;
        bottomFiveAdj = 8;
    }

    (:Round454)
    hidden function loadResources() as Void {
        var propClockFont = (propBitmapA >> 8) & 0x1;
        if(propClockFont == 0) {
            fontClock = Application.loadResource(Rez.Fonts.segments145);
            fontClockOutline = Application.loadResource(Rez.Fonts.segments145outline);
        } else {
            fontClock = Application.loadResource(Rez.Fonts.segments145_2);
            fontClockOutline = Application.loadResource(Rez.Fonts.segments145outline_2);
        }
        fontTinyData = Application.loadResource(Rez.Fonts.led_small_lines);
        loadSmallFont(Rez.Fonts.led, Rez.Fonts.led_inbetween, Rez.Fonts.led_lines);
        fontLargeData = Application.loadResource(Rez.Fonts.led_big);
        fontBottomData = fontLargeData;
        fontLabel = Application.loadResource(Rez.Fonts.storre);
        fontAODData = Application.loadResource(Rez.Fonts.led);
        fontBattery = fontTinyData;

        drawGradient = Application.loadResource(Rez.Drawables.gradient) as BitmapResource;
        drawAODPattern = Application.loadResource(Rez.Drawables.aod) as BitmapResource;

        clockHeight = 145;
        clockWidth = 413;
        labelHeight = 10;
        labelMargin = 8;
        tinyDataHeight = 13;
        smallDataHeight = 20;
        largeDataHeight = 27;
        largeDataWidth = 24;
        bottomDataWidth = 24;

        baseX = centerX + 3;
        baseY = centerY - smallDataHeight + 4;
        fieldSpaceingAdj = 20;
        textSideAdj = 4;
        bottomFiveAdj = 4;
        barBottomAdj = 2;
        marginY = 17;
    }

    (:Square)
    hidden function loadResources() as Void {
        var propClockFont = (propBitmapA >> 8) & 0x1;
        if(propClockFont == 0) {
            fontClock = Application.loadResource(Rez.Fonts.segments145);
            fontClockOutline = Application.loadResource(Rez.Fonts.segments145outline);
        } else {
            fontClock = Application.loadResource(Rez.Fonts.segments145_2);
            fontClockOutline = Application.loadResource(Rez.Fonts.segments145outline_2);
        }
        fontTinyData = Application.loadResource(Rez.Fonts.led_small_lines);
        loadSmallFont(Rez.Fonts.led, Rez.Fonts.led_inbetween, Rez.Fonts.led_lines);
        fontLargeData = Application.loadResource(Rez.Fonts.led_big);
        fontBottomData = fontLargeData;
        fontLabel = Application.loadResource(Rez.Fonts.storre);
        fontAODData = Application.loadResource(Rez.Fonts.led);
        fontBattery = fontTinyData;

        drawGradient = Application.loadResource(Rez.Drawables.gradient) as BitmapResource;
        drawAODPattern = Application.loadResource(Rez.Drawables.aod) as BitmapResource;

        clockHeight = 145;
        clockWidth = 413;
        labelHeight = 10;
        labelMargin = 8;
        tinyDataHeight = 13;
        smallDataHeight = 20;
        largeDataHeight = 27;
        largeDataWidth = 24;
        bottomDataWidth = 24;

        baseX = centerX + 3;
        baseY = centerY - smallDataHeight + 4;
        fieldSpaceingAdj = 20;
        textSideAdj = 4;
        bottomFiveAdj = 4;
        barBottomAdj = 2;
        marginY = 17;
    }

    hidden function computeDisplayValues(now as Gregorian.Info) as Dictionary {
        var values = {};
        var actInfo = ActivityMonitor.getInfo();
        var sysStats = System.getSystemStats();
        var propAlwaysShowSeconds = ((propBitmapA >> 12) & 0x1) == 1;
        cachedSysStats = sysStats;
        refreshCache = {};
        cachedStressDataValid = false;
        cachedBBDataValid = false;

        // From updateSlowData logic
        values[:dataClock] = getClockData(now);
        values[:dataMoon] = moonPhase(now);
        values[:dataLabelTopLeft] = strLabelTopLeft;
        values[:dataLabelTopRight] = strLabelTopRight;
        values[:dataLabelBottomLeft] = strLabelBottomLeft;
        values[:dataLabelBottomMiddle] = strLabelBottomMiddle;
        values[:dataLabelBottomRight] = strLabelBottomRight;
        values[:dataLabelBottomFourth] = strLabelBottomFourth;

        // From updateData logic
        var fieldWidths = cachedFieldWidths;
        values[:dataTopLeft] = getValueByType(propSunriseFieldShows, 5, now, actInfo, sysStats);
        values[:dataTopRight] = getValueByType(propSunsetFieldShows, 5, now, actInfo, sysStats);
        values[:dataAboveLine1] = getWeatherLineValue(propWeatherLine1Shows, 10, now, actInfo, sysStats);
        values[:dataAboveLine2] = getWeatherLineValue(propWeatherLine2Shows, 10, now, actInfo, sysStats);
        values[:dataBelow] = getValueByTypeWithUnit(propDateFieldShows, 10, now, actInfo, sysStats);
        values[:dataNotifications] = getValueByTypeWithUnit(propNotificationCountShows, 2, now, actInfo, sysStats);
        if (values[:dataNotifications].length() > 0) {
            if (propNotificationCountShows == 14) {
                values[:dataNotifications] = values[:dataNotifications] + "\u2665  ";
            } else if (propNotificationCountShows == 10 or propNotificationCountShows == 76) {
                values[:dataNotifications] = values[:dataNotifications] + "\u2764  ";
            }
        }
        values[:dataBottomLeft] = getValueByType(propLeftValueShows, fieldWidths[0], now, actInfo, sysStats);
        values[:dataBottomMiddle] = getValueByType(propMiddleValueShows, fieldWidths[1], now, actInfo, sysStats);
        values[:dataBottomRight] = getValueByType(propRightValueShows, fieldWidths[2], now, actInfo, sysStats);
        values[:dataBottomFourth] = getValueByType(propFourthValueShows, fieldWidths[3], now, actInfo, sysStats);
        values[:dataBottom] = getValueByType(propBottomFieldShows, 5, now, actInfo, sysStats);
        computeBottomField2Values(values, now, actInfo, sysStats);
        values[:dataIcon1] = getIconState(propIcon1, actInfo);
        values[:dataIcon2] = getIconState(propIcon2, actInfo);
        values[:dataBattery] = getBattData(sysStats);
        values[:dataAODLeft] = getValueByType(propAodFieldShows, 10, now, actInfo, sysStats);
        values[:dataAODRight] = getValueByType(propAodRightFieldShows, 5, now, actInfo, sysStats);
        values[:dataLeftBar] = getBarData(propLeftBarShows, actInfo);
        values[:dataRightBar] = getBarData(propRightBarShows, actInfo);

        // updateSeconds logic
        if(isSleeping and (!propAlwaysShowSeconds or canBurnIn)) {
            values[:dataSeconds] = "";
        } else {
            values[:dataSeconds] = now.sec.format("%02d");
        }

        return values;
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
    }

    // Called when this View is brought to the foreground.
    // Restore the state of this View and prepare it to be shown.
    // This includes loading resources into memory.
    function onShow() as Void {
        visible = true;
        lastUpdate = null;
        lastSlowUpdate = null;
        wakeTimestamp = Time.now().value();
        lastWeatherPhase = -1;
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        if(!visible) { return; }

        var now = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var unix_timestamp = Time.now().value();
        var propAlwaysShowSeconds = ((propBitmapA >> 12) & 0x1) == 1;

        if(doesPartialUpdate) {
            dc.clearClip();
            doesPartialUpdate = false;
        }

        if(now.sec % 60 == 0 or lastSlowUpdate == null or unix_timestamp - lastSlowUpdate >= 60) {
            lastSlowUpdate = unix_timestamp;
            updateWeather();
        }

        if(lastUpdate == null or unix_timestamp - lastUpdate >= fullUpdateIntervalS) {
            lastUpdate = unix_timestamp;
            cachedValues = computeDisplayValues(now);
        } else {
            // Only update time-sensitive values
            cachedValues[:dataClock] = getClockData(now);
            if(isSleeping and (!propAlwaysShowSeconds or canBurnIn)) {
                cachedValues[:dataSeconds] = "";
            } else {
                cachedValues[:dataSeconds] = now.sec.format("%02d");
            }
            // Refresh weather lines every 4 seconds for forecast cycling
            if (propWeatherLine1Shows == 79 || propWeatherLine2Shows == 79) {
                var phaseBucket = ((unix_timestamp - wakeTimestamp) / 4).toNumber();
                if (phaseBucket != lastWeatherPhase) {
                    lastWeatherPhase = phaseBucket;
                    var sysStats = cachedSysStats;
                    if (sysStats == null) {
                        sysStats = System.getSystemStats();
                        cachedSysStats = sysStats;
                    }
                    var forecastLine = getWeatherLineValue(79, 10, now, null, sysStats);
                    if (propWeatherLine1Shows == 79) {
                        cachedValues[:dataAboveLine1] = forecastLine;
                    }
                    if (propWeatherLine2Shows == 79) {
                        cachedValues[:dataAboveLine2] = forecastLine;
                    }
                }
            }
        }

        if(isSleeping and canBurnIn) {
            drawAOD(dc, now, cachedValues);
        } else {
            drawWatchface(dc, now, false, cachedValues);
        }
    }

    // Called when this View is removed from the screen.
    // Save the state of this View here.
    // This includes freeing resources from memory.
    function onHide() as Void {
        visible = false;
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        wakeTimestamp = Time.now().value();
        lastWeatherPhase = -1;
        lastUpdate = null;
        lastSlowUpdate = null;
        isSleeping = false;
        WatchUi.requestUpdate();
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        lastUpdate = null;
        lastSlowUpdate = null;
        isSleeping = true;
        WatchUi.requestUpdate();
    }

    function onSettingsChanged() as Void {
        initialize();
        lastUpdate = null;
        lastSlowUpdate = null;
        WatchUi.requestUpdate();
    }

    function onPartialUpdate(dc) {
        if(canBurnIn) { return; }
        var propShowSeconds = ((propBitmapA >> 11) & 0x1) == 1;
        var propAlwaysShowSeconds = ((propBitmapA >> 12) & 0x1) == 1;
        if(!propShowSeconds) { return; }
        if(!propAlwaysShowSeconds) { return; }
        doesPartialUpdate = true;

        var clip_width = 24;
        var clip_height = 20;
        var now = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var y1 = baseY + halfClockHeight + marginY;

        var seconds = now.sec.format("%02d");
        
        dc.setClip(baseX + halfClockWidth - textSideAdj - clip_width, y1, clip_width, clip_height);
        dc.setColor(themeColors[bg], themeColors[bg]);
        dc.clear();

        dc.setColor(themeColors[date], Graphics.COLOR_TRANSPARENT);
        dc.drawText(baseX + halfClockWidth - textSideAdj, y1, fontSmallData, seconds, Graphics.TEXT_JUSTIFY_RIGHT);
    }

    (:DefaultLayout)
    hidden function calculateLayout() as Void {
        var propLabelVisibility = (propBitmapB >> 11) & 0x3;
        var y1 = baseY + halfClockHeight + marginY;
        var y2 = y1 + smallDataHeight + marginY;
        var y3 = y2 + labelHeight + labelMargin + largeDataHeight;

        fieldY = y2 - 3;

        var data_width = Math.sqrt(centerY*centerY - (y3 - centerY)*(y3 - centerY)) * 2 + fieldSpaceingAdj;
        var left_edge = Math.round((screenWidth - data_width) / 2);

        calculateFieldXCoords(data_width, left_edge);

        bottomFiveY = y3 + halfMarginY + bottomFiveAdj - 2;
        if((propLabelVisibility == 1 or propLabelVisibility == 3)) { bottomFiveY = bottomFiveY - labelHeight; }
        calculateSquareLayout();
    }

    (:InstinctCrossover)
    hidden function calculateLayout() as Void {
        var propLabelVisibility = (propBitmapB >> 11) & 0x3;
        var y1 = baseY + halfClockHeight + marginY;
        var y2 = y1 + labelHeight + labelMargin + largeDataHeight;

        fieldY = y1 - 3;

        var data_width = Math.sqrt(centerY*centerY - (y2 - centerY)*(y2 - centerY)) * 2 + fieldSpaceingAdj;
        var left_edge = Math.round((screenWidth - data_width) / 2);

        calculateFieldXCoords(data_width, left_edge);

        bottomFiveY = y2 + halfMarginY + bottomFiveAdj - 2;
        if((propLabelVisibility == 1 or propLabelVisibility == 3)) { bottomFiveY = bottomFiveY - labelHeight; }
    }
    
    hidden function calculateFieldXCoords(data_width as Float, left_edge as Number) as Void {
        var digits = getFieldWidths();
        var tot_digits = digits[0] + digits[1] + digits[2] + digits[3];
        if (tot_digits == 0) { return; } 
        var dw1 = Math.round(digits[0] * data_width / tot_digits);
        var dw2 = Math.round(digits[1] * data_width / tot_digits);
        var dw3 = Math.round(digits[2] * data_width / tot_digits);
        var dw4 = Math.round(digits[3] * data_width / tot_digits);

        fieldXCoords[0] = left_edge + Math.round(dw1 / 2);
        fieldXCoords[1] = left_edge + Math.round(dw1 + (dw2 / 2));
        fieldXCoords[2] = left_edge + Math.round(dw1 + dw2 + (dw3 / 2));
        fieldXCoords[3] = left_edge + Math.round(dw1 + dw2 + dw3 + (dw4 / 2));
    }

    (:DefaultLayout)
    hidden function drawWatchface(dc as Dc, now as Gregorian.Info, aod as Boolean, values as Dictionary) as Void {
        var propTopPartShows = (propBitmapB >> 6) & 0x1;
        var propLabelVisibility = (propBitmapB >> 11) & 0x3;
        var propShowClockBg = ((propBitmapA >> 13) & 0x1) == 1;
        var propClockOutlineStyle = (propBitmapA >> 5) & 0x7;
        var propDateAlignment = (propBitmapA >> 18) & 0x1;
        var propShowSeconds = ((propBitmapA >> 11) & 0x1) == 1;

        // Clear
        dc.setColor(themeColors[bg], themeColors[bg]);
        dc.clear();
        var yn1 = baseY - halfClockHeight - marginY - smallDataHeight;
        var yn2 = yn1 - marginY - smallDataHeight;

        // Draw Top data fields
        var top_data_height = halfMarginY;
        var top_field_font = fontTinyData;
        var top_field_center_offset = 20;
        if(propTopPartShows == 1) { top_field_center_offset = labelHeight; }
        if(propLabelVisibility == 0 or propLabelVisibility == 3) {
            dc.setColor(themeColors[fieldLbl], Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX - top_field_center_offset, marginY, fontLabel, values[:dataLabelTopLeft], Graphics.TEXT_JUSTIFY_RIGHT);
            dc.drawText(centerX + top_field_center_offset, marginY, fontLabel, values[:dataLabelTopRight], Graphics.TEXT_JUSTIFY_LEFT);

            top_data_height = labelHeight + halfMarginY;
        }

        dc.setColor(themeColors[dataVal], Graphics.COLOR_TRANSPARENT);
        if(propTopPartShows == 0) {
            dc.drawText(centerX - top_field_center_offset, marginY + top_data_height, top_field_font, values[:dataTopLeft], Graphics.TEXT_JUSTIFY_RIGHT);
            dc.drawText(centerX + top_field_center_offset, marginY + top_data_height, top_field_font, values[:dataTopRight], Graphics.TEXT_JUSTIFY_LEFT);

            // Draw Moon
            dc.setColor(themeColors[moon], Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, marginY + ((top_data_height + tinyDataHeight) / 2), fontMoon, values[:dataMoon], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            if(top_data_height == halfMarginY) { top_field_font = fontSmallData; }
            dc.drawText(centerX - top_field_center_offset, marginY + top_data_height, top_field_font, values[:dataTopLeft], Graphics.TEXT_JUSTIFY_RIGHT);
            dc.drawText(centerX + top_field_center_offset, marginY + top_data_height, top_field_font, values[:dataTopRight], Graphics.TEXT_JUSTIFY_LEFT);
        }

        // Draw Lines above clock
        dc.setColor(themeColors[dataVal], Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, yn2, fontSmallData, values[:dataAboveLine1], Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, yn1, fontSmallData, values[:dataAboveLine2], Graphics.TEXT_JUSTIFY_CENTER);        

        // Draw Clock
        dc.setColor(themeColors[clockBg], Graphics.COLOR_TRANSPARENT);
        if(propShowClockBg and !aod) {
            dc.drawText(baseX, baseY, fontClock, clockBgText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        dc.setColor(themeColors[clock], Graphics.COLOR_TRANSPARENT);
        dc.drawText(baseX, baseY, fontClock, values[:dataClock], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Draw clock gradient
        if(drawGradient != null and themeColors[bg] == 0x000000 and !aod) {
            dc.drawBitmap(centerX - halfClockWidth, baseY - halfClockHeight, drawGradient);
        }

        if(propClockOutlineStyle == 2 or propClockOutlineStyle == 3) {
            if(fontClockOutline != null) { // Someone has only bothered to draw this font for AMOLED sizes
                // Draw outline
                dc.setColor(themeColors[outline], Graphics.COLOR_TRANSPARENT);
                dc.drawText(baseX, baseY, fontClockOutline, values[:dataClock], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        // Draw stress and body battery bars
        drawSideBars(dc, values);

        // Draw Line below clock
        var y1 = baseY + halfClockHeight + marginY;
        dc.setColor(themeColors[date], Graphics.COLOR_TRANSPARENT);
        if(propDateAlignment == 0) {
            dc.drawText(baseX - halfClockWidth + textSideAdj, y1, fontSmallData, values[:dataBelow], Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.drawText(baseX, y1, fontSmallData, values[:dataBelow], Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // Draw seconds
        if(propShowSeconds) {
            dc.drawText(baseX + halfClockWidth - textSideAdj, y1, fontSmallData, values[:dataSeconds], Graphics.TEXT_JUSTIFY_RIGHT);
        }

        // Draw Notification count
        dc.setColor(themeColors[notif], Graphics.COLOR_TRANSPARENT);
        if(propDateAlignment == 0) {
            if(!propShowSeconds) { // No seconds, notification on right side
                dc.drawText(baseX + halfClockWidth - textSideAdj, y1, fontSmallData, values[:dataNotifications], Graphics.TEXT_JUSTIFY_RIGHT);
            } else {
                var date_width = dc.getTextWidthInPixels(values[:dataBelow], fontSmallData);
                var sec_width = dc.getTextWidthInPixels(values[:dataSeconds], fontSmallData); 
                var date_right_edge = baseX - halfClockWidth + textSideAdj + date_width;
                var sec_left = baseX + halfClockWidth - textSideAdj - sec_width;
                var pos = sec_left - marginX;
                if((sec_left - date_right_edge) < 3 * marginX) {
                    pos = (date_right_edge + sec_left) / 2;
                }
                dc.drawText(pos, y1, fontSmallData, values[:dataNotifications], Graphics.TEXT_JUSTIFY_CENTER);
            }
        } else { // Date is centered, notification on left side
            dc.drawText(baseX - halfClockWidth, y1, fontSmallData, values[:dataNotifications], Graphics.TEXT_JUSTIFY_LEFT);
        }

        // Draw the three bottom data fields
        var digits = getFieldWidths();

        drawDataField(dc, fieldXCoords[0], fieldY, 3, values[:dataLabelBottomLeft], values[:dataBottomLeft], digits[0], fontLargeData, largeDataWidth * digits[0]);
        drawDataField(dc, fieldXCoords[1], fieldY, 3, values[:dataLabelBottomMiddle], values[:dataBottomMiddle], digits[1], fontLargeData, largeDataWidth * digits[1]);
        drawDataField(dc, fieldXCoords[2], fieldY, 3, values[:dataLabelBottomRight], values[:dataBottomRight], digits[2], fontLargeData, largeDataWidth * digits[2]);
        drawDataField(dc, fieldXCoords[3], fieldY, 3, values[:dataLabelBottomFourth], values[:dataBottomFourth], digits[3], fontLargeData, largeDataWidth * digits[3]);

        // Draw the 5 digit bottom field(s) and icons
        drawBottomFieldsWithIcons(dc, values);

        // Draw battery icon
        if(screenHeight == 240 and propBottomFieldShows != -2) {
            drawBatteryIcon(dc, centerX + 32, bottomFiveY, values);
        } else {
            drawBatteryIcon(dc, null, null, values);
        }
    }

    (:InstinctCrossover)
    hidden function drawWatchface(dc as Dc, now as Gregorian.Info, aod as Boolean, values as Dictionary) as Void {
        var propTopPartShows = (propBitmapB >> 6) & 0x1;
        var propLabelVisibility = (propBitmapB >> 11) & 0x3;
        var propShowClockBg = ((propBitmapA >> 13) & 0x1) == 1;
        var propClockOutlineStyle = (propBitmapA >> 5) & 0x7;
        var propDateAlignment = (propBitmapA >> 18) & 0x1;
        var propShowSeconds = ((propBitmapA >> 11) & 0x1) == 1;

        // Clear
        dc.setColor(themeColors[bg], themeColors[bg]);
        dc.clear();

        // Shifted positions: date line is now above clock
        var yn0 = baseY - halfClockHeight - marginY - smallDataHeight;  // date line (above clock)
        var yn1 = yn0 - marginY - smallDataHeight;  // weather line 2
        var yn2 = yn1 - marginY - smallDataHeight;  // weather line 1

        // Draw Top data fields
        var top_data_height = halfMarginY;
        var top_field_font = fontTinyData;
        var top_field_center_offset = 20;
        if(propTopPartShows == 1) { top_field_center_offset = labelHeight; }
        if(propLabelVisibility == 0 or propLabelVisibility == 3) {
            dc.setColor(themeColors[fieldLbl], Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX - top_field_center_offset, marginY, fontLabel, values[:dataLabelTopLeft], Graphics.TEXT_JUSTIFY_RIGHT);
            dc.drawText(centerX + top_field_center_offset, marginY, fontLabel, values[:dataLabelTopRight], Graphics.TEXT_JUSTIFY_LEFT);

            top_data_height = labelHeight + halfMarginY + 2;
        }

        dc.setColor(themeColors[dataVal], Graphics.COLOR_TRANSPARENT);
        if(propTopPartShows == 0) {
            dc.drawText(centerX - top_field_center_offset, marginY + top_data_height, top_field_font, values[:dataTopLeft], Graphics.TEXT_JUSTIFY_RIGHT);
            dc.drawText(centerX + top_field_center_offset, marginY + top_data_height, top_field_font, values[:dataTopRight], Graphics.TEXT_JUSTIFY_LEFT);

            // Draw Moon
            dc.setColor(themeColors[moon], Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, marginY + ((top_data_height + tinyDataHeight) / 2), fontMoon, values[:dataMoon], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            if(top_data_height == halfMarginY) { top_field_font = fontSmallData; }
            dc.drawText(centerX - top_field_center_offset, marginY + top_data_height, top_field_font, values[:dataTopLeft], Graphics.TEXT_JUSTIFY_RIGHT);
            dc.drawText(centerX + top_field_center_offset, marginY + top_data_height, top_field_font, values[:dataTopRight], Graphics.TEXT_JUSTIFY_LEFT);
        }

        // Draw Lines above clock (shifted up by one row)
        dc.setColor(themeColors[dataVal], Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, yn2, fontSmallData, values[:dataAboveLine1], Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, yn1, fontSmallData, values[:dataAboveLine2], Graphics.TEXT_JUSTIFY_CENTER);

        // Draw date line ABOVE clock (at yn0)
        dc.setColor(themeColors[date], Graphics.COLOR_TRANSPARENT);
        if(propDateAlignment == 0) {
            dc.drawText(baseX - halfClockWidth + textSideAdj, yn0, fontSmallData, values[:dataBelow], Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.drawText(baseX, yn0, fontSmallData, values[:dataBelow], Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Draw seconds (above clock)
        if(propShowSeconds) {
            dc.drawText(baseX + halfClockWidth - textSideAdj, yn0, fontSmallData, values[:dataSeconds], Graphics.TEXT_JUSTIFY_RIGHT);
        }

        // Draw Notification count (above clock)
        dc.setColor(themeColors[notif], Graphics.COLOR_TRANSPARENT);
        if(propDateAlignment == 0) {
            if(!propShowSeconds) {
                dc.drawText(baseX + halfClockWidth - textSideAdj, yn0, fontSmallData, values[:dataNotifications], Graphics.TEXT_JUSTIFY_RIGHT);
            } else {
                var date_width = dc.getTextWidthInPixels(values[:dataBelow], fontSmallData);
                var sec_width = dc.getTextWidthInPixels(values[:dataSeconds], fontSmallData);
                var date_right_edge = baseX - halfClockWidth + textSideAdj + date_width;
                var sec_left = baseX + halfClockWidth - textSideAdj - sec_width;
                var pos = sec_left - marginX;
                if((sec_left - date_right_edge) < 3 * marginX) {
                    pos = (date_right_edge + sec_left) / 2;
                }
                dc.drawText(pos, yn0, fontSmallData, values[:dataNotifications], Graphics.TEXT_JUSTIFY_CENTER);
            }
        } else {
            dc.drawText(baseX - halfClockWidth, yn0, fontSmallData, values[:dataNotifications], Graphics.TEXT_JUSTIFY_LEFT);
        }

        // Draw Clock
        dc.setColor(themeColors[clockBg], Graphics.COLOR_TRANSPARENT);
        if(propShowClockBg and !aod) {
            dc.drawText(baseX, baseY, fontClock, clockBgText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        dc.setColor(themeColors[clock], Graphics.COLOR_TRANSPARENT);
        dc.drawText(baseX, baseY, fontClock, values[:dataClock], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Draw clock gradient
        if(drawGradient != null and themeColors[bg] == 0x000000 and !aod) {
            dc.drawBitmap(centerX - halfClockWidth, baseY - halfClockHeight, drawGradient);
        }

        if(propClockOutlineStyle == 2 or propClockOutlineStyle == 3) {
            if(fontClockOutline != null) {
                dc.setColor(themeColors[outline], Graphics.COLOR_TRANSPARENT);
                dc.drawText(baseX, baseY, fontClockOutline, values[:dataClock], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        // Draw stress and body battery bars
        drawSideBars(dc, values);

        // Draw the three bottom data fields (directly below clock, no date row)
        var digits = getFieldWidths();

        drawDataField(dc, fieldXCoords[0], fieldY, 3, values[:dataLabelBottomLeft], values[:dataBottomLeft], digits[0], fontLargeData, largeDataWidth * digits[0]);
        drawDataField(dc, fieldXCoords[1], fieldY, 3, values[:dataLabelBottomMiddle], values[:dataBottomMiddle], digits[1], fontLargeData, largeDataWidth * digits[1]);
        drawDataField(dc, fieldXCoords[2], fieldY, 3, values[:dataLabelBottomRight], values[:dataBottomRight], digits[2], fontLargeData, largeDataWidth * digits[2]);
        drawDataField(dc, fieldXCoords[3], fieldY, 3, values[:dataLabelBottomFourth], values[:dataBottomFourth], digits[3], fontLargeData, largeDataWidth * digits[3]);

        // Draw the 5 digit bottom field
        var step_width = drawDataField(dc, centerX, bottomFiveY, 0, null, values[:dataBottom], 5, fontBottomData, bottomDataWidth * 5);

        // Draw icons
        dc.setColor(themeColors[dataVal], Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX - (step_width / 2) - (marginX / 2), bottomFiveY + (largeDataHeight / 2) + iconYAdj, fontIcons, values[:dataIcon1], Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX + (step_width / 2) + (marginX / 2) - 2, bottomFiveY + (largeDataHeight / 2) + iconYAdj, fontIcons, values[:dataIcon2], Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // Draw battery icon
        drawBatteryIcon(dc, null, null, values);
    }

    (:MIP)
    hidden function drawAOD(dc as Dc, now as Gregorian.Info, values as Dictionary) as Void { }

    (:AMOLED)
    hidden function drawAOD(dc as Dc, now as Gregorian.Info, values as Dictionary) as Void {
        var propAodStyle = (propBitmapA >> 15) & 0x3;
        var propClockOutlineStyle = (propBitmapA >> 5) & 0x7;
        var propAodAlignment = (propBitmapA >> 17) & 0x1;
        dc.setColor(0x000000, 0x000000);
        dc.clear();

        if(propAodStyle == 2) {
            drawWatchface(dc, now, true, values);
            drawPattern(dc, 0x000000, (now.min % 3));
        } else if (propAodStyle == 1) {
            var clock_color = themeColors[clock];
            if(clock_color == 0x000000) { clock_color = 0x555555; }

            if(propClockOutlineStyle == 0 or propClockOutlineStyle == 2 or propClockOutlineStyle == 5) {
                // Draw Clock
                dc.setColor(clock_color, Graphics.COLOR_TRANSPARENT);
                dc.drawText(baseX, baseY, fontClock, values[:dataClock], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }

            if(propClockOutlineStyle == 1 or propClockOutlineStyle == 2 or propClockOutlineStyle == 3) {
                dc.setColor(themeColors[outline], Graphics.COLOR_TRANSPARENT);
                dc.drawText(baseX, baseY, fontClockOutline, values[:dataClock], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }

            if(propClockOutlineStyle == 4) {
                // Filled clock but outline color
                dc.setColor(themeColors[outline], Graphics.COLOR_TRANSPARENT);
                dc.drawText(baseX, baseY, fontClock, values[:dataClock], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }

            // Draw clock gradient
            dc.drawBitmap(centerX - halfClockWidth - (now.min % 2), baseY - halfClockHeight, drawAODPattern);

            // Draw Line below clock
            var y1 = baseY + halfClockHeight + marginY;
            dc.setColor(themeColors[dateDim], Graphics.COLOR_TRANSPARENT);
            if(propAodAlignment == 0) {
                dc.drawText(baseX - halfClockWidth + textSideAdj - (now.min % 3), y1, fontAODData, values[:dataAODLeft], Graphics.TEXT_JUSTIFY_LEFT);
            } else {
                dc.drawText(baseX - (now.min % 3), y1, fontAODData, values[:dataAODLeft], Graphics.TEXT_JUSTIFY_CENTER);
            }
            dc.drawText(baseX + halfClockWidth - textSideAdj - 2 - (now.min % 3), y1, fontAODData, values[:dataAODRight], Graphics.TEXT_JUSTIFY_RIGHT);
        }
    }

    (:AMOLED)
    hidden var patternText as String = "";
    (:AMOLED)
    hidden var patternRows as Number = 0;

    (:AMOLED)
    hidden function drawPattern(dc as Dc, color as ColorType, offset as Number) as Void {
        if(patternText.length() == 0) {
            var cols = (screenWidth / 20) + 1;
            var text = "";
            for(var i = 0; i < cols; i++) { text += "S"; }
            patternText = text;
            patternRows = (screenHeight / 20) + 1;
        }

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var i = 0;
        while(i < patternRows) {
            dc.drawText(0, i*20 + offset, fontIcons, patternText, Graphics.TEXT_JUSTIFY_LEFT);
            i++;
        }
    }

    hidden function getFieldWidths() as Array<Number> {
        var propFieldLayout = (propBitmapB >> 23) & 0xF;
        if(propFieldLayout == 0) { // Auto
            return bottomFieldWidths;
        } else if(propFieldLayout == 1) {
            return [3, 3, 3, 0];
        } else if(propFieldLayout == 2) {
            return [3, 4, 3, 0];
        } else if(propFieldLayout == 3) {
            return [3, 3, 4, 0];
        } else if(propFieldLayout == 4) {
            return [4, 3, 3, 0];
        } else if(propFieldLayout == 5) {
            return [4, 3, 4, 0];
        } else if(propFieldLayout == 6) {
            return [3, 4, 4, 0];
        } else if(propFieldLayout == 7) {
            return [4, 4, 3, 0];
        } else if(propFieldLayout == 8) {
            return [4, 4, 4, 0];
        } else if(propFieldLayout == 9) {
            return [3, 3, 3, 3];
        } else if(propFieldLayout == 10) {
            return [3, 3, 3, 4];
        } else if(propFieldLayout == 11) {
            return [4, 3, 3, 3];
        } else if(propFieldLayout == 12) {
            return [4, 4, 0, 0];
        } else if(propFieldLayout == 14) {
            return [4, 4, 2, 3];
        } else {
            return [5, 3, 3, 0];
        }
    }

    hidden function getCachedDeviceSettings() {
        if(!(refreshCache has :deviceSettingsLoaded)) {
            refreshCache[:deviceSettings] = System.getDeviceSettings();
            refreshCache[:deviceSettingsLoaded] = true;
        }
        return refreshCache.get(:deviceSettings);
    }

    hidden function getCachedActivityDetails() {
        if(!(refreshCache has :activityDetailsLoaded)) {
            refreshCache[:activityDetails] = Activity.getActivityInfo();
            refreshCache[:activityDetailsLoaded] = true;
        }
        return refreshCache.get(:activityDetails);
    }

    hidden function getCachedUserProfile() {
        if(!(refreshCache has :userProfileLoaded)) {
            refreshCache[:userProfile] = UserProfile.getProfile();
            refreshCache[:userProfileLoaded] = true;
        }
        return refreshCache.get(:userProfile);
    }

    hidden function getCachedSunEvents(time as Time.Moment, cacheKey as String) as Array? {
        if(cacheKey.equals("today")) {
            if(refreshCache has :sunEventsTodayLoaded) { return (refreshCache as Dictionary).get(:sunEventsToday) as Array?; }
            refreshCache[:sunEventsTodayLoaded] = true;
        } else {
            if(refreshCache has :sunEventsTomorrowLoaded) { return (refreshCache as Dictionary).get(:sunEventsTomorrow) as Array?; }
            refreshCache[:sunEventsTomorrowLoaded] = true;
        }

        var events = null;
        var activeWeather = getActiveWeatherCondition();
        if (activeWeather != null) {
            var loc = activeWeather.observationLocationPosition;
            if (loc != null) {
                var sunrise = Weather.getSunrise(loc, time);
                var sunset = Weather.getSunset(loc, time);
                if (sunrise != null && sunset != null) {
                    events = [sunrise, sunset];
                }
            }
        }

        if(cacheKey.equals("today")) {
            refreshCache[:sunEventsToday] = events;
        } else {
            refreshCache[:sunEventsTomorrow] = events;
        }
        return events;
    }

    hidden function drawFieldLabel(dc as Dc, x as Number, y as Number, adjX as Number, label as String?, bgwidth as Number) as Void {
        var propBottomFieldLabelAlignment = (propBitmapA >> 21) & 0x3;
        if(label == null || label.length() == 0) { return; }

        var half_bg_width = Math.round(bgwidth / 2);
        dc.setColor(themeColors[fieldLbl], Graphics.COLOR_TRANSPARENT);
        if(propBottomFieldLabelAlignment == 0) {
            dc.drawText(x - half_bg_width + adjX, y, fontLabel, label, Graphics.TEXT_JUSTIFY_LEFT);
        } else if(propBottomFieldLabelAlignment == 2) {
            dc.drawText(x + half_bg_width - 1 + adjX, y, fontLabel, label, Graphics.TEXT_JUSTIFY_RIGHT);
        } else {
            dc.drawText(x + adjX, y, fontLabel, label, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    hidden function drawDataField(dc as Dc, x as Number, y as Number, adjX as Number, label as String?, value as String, width as Number, font as FontResource, bgwidth as Number) as Number {
        var propLabelVisibility = (propBitmapB >> 11) & 0x3;
        var propShowDataBg = ((propBitmapA >> 14) & 0x1) == 1;
        var propBottomFieldAlignment = (propBitmapA >> 19) & 0x3;
        if(value.length() == 0 and (label == null or label.length() == 0)) { return 0; }
        if(width == 0) { return 0; }
        var valueBg;
        if(screenHeight == 360 and width == 5 and label == null) {
            valueBg = bgStringsAlt[width];
        } else {
            valueBg = bgStrings[width];
        }

        var value_bg_width = bgwidth;//dc.getTextWidthInPixels(valueBg, font);
        var half_bg_width = Math.round(value_bg_width / 2);
        var data_y = y;

        if((propLabelVisibility == 0 or propLabelVisibility == 2) and !(label == null)) {
            drawFieldLabel(dc, x, y, adjX, label, value_bg_width);
            data_y += labelHeight + labelMargin;
        }

        if(propShowDataBg) {
            dc.setColor(themeColors[fieldBg], Graphics.COLOR_TRANSPARENT);
            dc.drawText(x - half_bg_width + adjX, data_y, font, valueBg, Graphics.TEXT_JUSTIFY_LEFT);
        }

        dc.setColor(themeColors[dataVal], Graphics.COLOR_TRANSPARENT);
        if(propBottomFieldAlignment == 0) {
            dc.drawText(x - half_bg_width + adjX, data_y, font, value, Graphics.TEXT_JUSTIFY_LEFT);
        } else if (propBottomFieldAlignment == 1) {
            dc.drawText(x + adjX, data_y, font, value, Graphics.TEXT_JUSTIFY_CENTER);
        } else if (propBottomFieldAlignment == 2) {
            dc.drawText(x + half_bg_width - 1 + adjX, data_y, font, value, Graphics.TEXT_JUSTIFY_RIGHT);
        } else if (propBottomFieldAlignment == 3 and width != 5) {
            dc.drawText(x - half_bg_width + adjX, data_y, font, value, Graphics.TEXT_JUSTIFY_LEFT);
        } else if (propBottomFieldAlignment == 3 and width == 5) {
            dc.drawText(x + adjX, data_y, font, value, Graphics.TEXT_JUSTIFY_CENTER);
        }

        return value_bg_width;
    }

    hidden function drawSideBars(dc as Dc, values as Dictionary) as Void {
        var propStressDynamicColor = ((propBitmapB >> 15) & 0x1) == 1;
        var barVal;
        var barHeight;
        var barColor;

        if (values[:dataLeftBar] != null) {
            barVal = values[:dataLeftBar];
            barHeight = Math.round(barVal * (clockHeight / 100.0));
            if (propLeftBarShows == 1 && propStressDynamicColor) {
                barColor = getStressColor(barVal);
            } else {
                barColor = themeColors[stress]; 
            }
            dc.setColor(barColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(
                centerX - halfClockWidth - barWidth - barWidth, baseY + halfClockHeight - barHeight + barBottomAdj, barWidth, barHeight
            );

            if(propLeftBarShows == 6) {
                drawMoveBarTicks(dc, centerX - halfClockWidth - barWidth - barWidth, centerX - halfClockWidth);
            }
        }

        if (values[:dataRightBar] != null) {
            barVal = values[:dataRightBar];
            barHeight = Math.round(barVal * (clockHeight / 100.0));
            if (propRightBarShows == 1 && propStressDynamicColor) {
                barColor = getStressColor(barVal);
            } else {
                barColor = themeColors[bodybatt]; 
            }
            dc.setColor(barColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(
                centerX + halfClockWidth + barWidth, baseY + halfClockHeight - barHeight + barBottomAdj, barWidth, barHeight
            );
            
            if(propRightBarShows == 6) {
                drawMoveBarTicks(dc, centerX + halfClockWidth + barWidth + barWidth, centerX + halfClockWidth);
            }
        }
    }

    hidden function drawMoveBarTicks(dc as Dc, x1, x2) as Void {
        dc.setColor(themeColors[bg], Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(x1, baseY + halfClockHeight - (40 * (clockHeight / 100.0)), x2, baseY + halfClockHeight - (40 * (clockHeight / 100.0)));
        dc.drawLine(x1, baseY + halfClockHeight - (55 * (clockHeight / 100.0)), x2, baseY + halfClockHeight - (55 * (clockHeight / 100.0)));
        dc.drawLine(x1, baseY + halfClockHeight - (70 * (clockHeight / 100.0)), x2, baseY + halfClockHeight - (70 * (clockHeight / 100.0)));
        dc.drawLine(x1, baseY + halfClockHeight - (85 * (clockHeight / 100.0)), x2, baseY + halfClockHeight - (85 * (clockHeight / 100.0)));
        dc.setPenWidth(1);
    }

    hidden function getBatteryDisplayVariant(sysStats as System.Stats?) as Number {
        if(sysStats != null && sysStats.battery < 20) {
            return 1;
        }
        return 3;
    }

    (:AMOLED)
    hidden function drawBatteryIcon(dc as Dc, x as Number?, y as Number?, values as Dictionary) {
        var batteryVariant = getBatteryDisplayVariant(cachedSysStats);
        if(x == null) { x = centerX; }
        if(y == null) { y =  screenHeight - 23; }

        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, fontIcons, "C", Graphics.TEXT_JUSTIFY_CENTER);
        if(cachedSysStats != null && cachedSysStats.battery <= 15) {
            dc.setColor(0xFF0000, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(themeColors[dataVal], Graphics.COLOR_TRANSPARENT);
        }
        if(batteryVariant == 3) {
            dc.drawText(x - 19, y + 4, fontBattery, values[:dataBattery], Graphics.TEXT_JUSTIFY_LEFT);
        } else { // centered when not a bar
            dc.drawText(x - 1, y + 4, fontBattery, values[:dataBattery], Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    (:MIP)
    hidden function drawBatteryIcon(dc as Dc, x as Number?, y as Number?, values as Dictionary) {
        var batteryVariant = getBatteryDisplayVariant(cachedSysStats);
        if(x == null) { x = centerX; }
        if(y == null) { y =  screenHeight - 20; }

        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, fontIcons, "B", Graphics.TEXT_JUSTIFY_CENTER);
        if(cachedSysStats != null && cachedSysStats.battery <= 15) {
            dc.setColor(0xFF0000, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(themeColors[dataVal], Graphics.COLOR_TRANSPARENT);
        }
        if(batteryVariant == 3) {
            dc.drawText(x - 11, y + 3, fontBattery, values[:dataBattery], Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.drawText(x - 1, y + 3, fontBattery, values[:dataBattery], Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    hidden function setColorTheme(theme as Number) as Array<Graphics.ColorType> {
        var themeRes = [
            Rez.Strings.theme_0, Rez.Strings.theme_1, Rez.Strings.theme_2, Rez.Strings.theme_3,
            Rez.Strings.theme_4, Rez.Strings.theme_5, Rez.Strings.theme_6, Rez.Strings.theme_7,
            Rez.Strings.theme_8, Rez.Strings.theme_9, Rez.Strings.theme_10, Rez.Strings.theme_11,
            Rez.Strings.theme_12, Rez.Strings.theme_13, Rez.Strings.theme_14, Rez.Strings.theme_15,
            Rez.Strings.theme_16, Rez.Strings.theme_17, Rez.Strings.theme_18, Rez.Strings.theme_19,
            Rez.Strings.theme_20, Rez.Strings.theme_21, Rez.Strings.theme_22, Rez.Strings.theme_23,
            Rez.Strings.theme_24
        ];

        var str = "";
        if(theme >= 0 and theme < themeRes.size()) {
            str = WatchUi.loadResource(themeRes[theme]);
        } else {
            str = WatchUi.loadResource(Rez.Strings.theme_0);
        }

        return parseThemeString(str);
    }

    hidden function parseThemeString(csv as String) as Array<Graphics.ColorType> {
        var res = new [13]; 
        var comma = 0;
        for(var i=0; i<13; i++) {
            comma = csv.find(",");
            var hex = "";
            if(comma != null) {
                hex = csv.substring(0, comma);
                csv = csv.substring(comma + 1, csv.length());
            } else {
                hex = csv;
            }
            
            if(hex.equals("FFFFFFFF")) {
                res[i] = Graphics.COLOR_TRANSPARENT; 
            } else {
                res[i] = hex.toNumberWithBase(16);
            }
        }
        return res;
    }

    hidden function getValueOrDefault(propName as String, defaultVal as PropertyValueType) as PropertyValueType {
        var val = Application.Properties.getValue(propName);
        if(val == null) {
            return defaultVal;
        }
        return val;
    }

    hidden function updateProperties() as Void {
        propBitmapA = 0;
        propBitmapA |= (getValueOrDefault("colorTheme", 0) as Number) & 0x1F;
        propBitmapA |= ((getValueOrDefault("clockOutlineStyle", 0) as Number) & 0x7) << 5;
        propBitmapA |= ((getValueOrDefault("clockFont", 0) as Number) & 0x1) << 8;
        // Bits 9:10 are intentionally unused after removing the battery display setting.
        propBitmapA |= (((getValueOrDefault("showSeconds", true) as Boolean) ? 1 : 0) << 11);
        propBitmapA |= (((getValueOrDefault("alwaysShowSeconds", false) as Boolean) ? 1 : 0) << 12);
        propBitmapA |= (((getValueOrDefault("showClockBg", true) as Boolean) ? 1 : 0) << 13);
        propBitmapA |= (((getValueOrDefault("showDataBg", true) as Boolean) ? 1 : 0) << 14);
        propBitmapA |= ((getValueOrDefault("aodStyle", 0) as Number) & 0x3) << 15;
        propBitmapA |= ((getValueOrDefault("aodAlignment", 0) as Number) & 0x1) << 17;
        propBitmapA |= ((getValueOrDefault("dateAlignment", 0) as Number) & 0x1) << 18;
        propBitmapA |= ((getValueOrDefault("bottomFieldAlignment", 2) as Number) & 0x3) << 19;
        propBitmapA |= ((getValueOrDefault("bottomFieldLabelAlignment", 0) as Number) & 0x3) << 21;
        propBitmapA |= ((getValueOrDefault("hemisphere", 0) as Number) & 0x1) << 23;
        propBitmapA |= ((getValueOrDefault("hourFormat", 0) as Number) & 0x3) << 24;
        propBitmapA |= (((getValueOrDefault("zeropadHour", true) as Boolean) ? 1 : 0) << 26);
        propBitmapA |= ((getValueOrDefault("timeSeparator", 0) as Number) & 0x3) << 27;
        propBitmapA |= ((getValueOrDefault("tempUnit", 0) as Number) & 0x3) << 29;

        propBitmapB = 0;
        propBitmapB |= ((getValueOrDefault("showTempUnit", true) as Boolean) ? 1 : 0);
        propBitmapB |= ((getValueOrDefault("windUnit", 0) as Number) & 0x7) << 1;
        propBitmapB |= ((getValueOrDefault("pressureUnit", 0) as Number) & 0x3) << 4;
        propBitmapB |= ((getValueOrDefault("topPartShows", 0) as Number) & 0x1) << 6;
        propBitmapB |= ((getValueOrDefault("dateFormat", 0) as Number) & 0xF) << 7;
        propBitmapB |= ((getValueOrDefault("labelVisibility", 0) as Number) & 0x3) << 11;
        propBitmapB |= ((getValueOrDefault("smallFontVariant", 2) as Number) & 0x3) << 13;
        propBitmapB |= (((getValueOrDefault("stressDynamicColor", true) as Boolean) ? 1 : 0) << 15);
        propBitmapB |= ((System.getDeviceSettings().is24Hour ? 1 : 0) << 16);
        propBitmapB |= ((getValueOrDefault("fieldLayout", 11) as Number) & 0xF) << 23;

        propSunriseFieldShows = getValueOrDefault("sunriseFieldShows", 39) as Number;
        propSunsetFieldShows = getValueOrDefault("sunsetFieldShows", 40) as Number;
        propWeatherLine1Shows = getValueOrDefault("weatherLine1Shows", 49) as Number;
        propWeatherLine2Shows = getValueOrDefault("weatherLine2Shows", 79) as Number;
        propDateFieldShows = getValueOrDefault("dateFieldShows", -1) as Number;
        propLeftValueShows = getValueOrDefault("leftValueShows", 11) as Number;
        propMiddleValueShows = getValueOrDefault("middleValueShows", 29) as Number;
        propRightValueShows = getValueOrDefault("rightValueShows", 6) as Number;
        propFourthValueShows = getValueOrDefault("fourthValueShows", 10) as Number;
        propBottomFieldShows = getValueOrDefault("bottomFieldShows", 17) as Number;
        loadBottomField2Property();
        propLeftBarShows = getValueOrDefault("leftBarShows", 1) as Number;
        propRightBarShows = getValueOrDefault("rightBarShows", 2) as Number;
        propIcon1 = getValueOrDefault("icon1", 1) as Number;
        propIcon2 = getValueOrDefault("icon2", 2) as Number;
        propAodFieldShows = getValueOrDefault("aodFieldShows", -1) as Number;
        propAodRightFieldShows = getValueOrDefault("aodRightFieldShows", -2) as Number;
        propNotificationCountShows = getValueOrDefault("notificationCountShows", 14) as Number;
        propWeekOffset = getValueOrDefault("weekOffset", 0) as Number;

        var propTheme = propBitmapA & 0x1F;
        themeColors = setColorTheme(propTheme);
        updateActiveLabels();

        isWeatherRequired = false;

        var weatherFields = [
            propSunriseFieldShows, propSunsetFieldShows,
            propWeatherLine1Shows, propWeatherLine2Shows,
            propDateFieldShows,
            propLeftValueShows, propMiddleValueShows, 
            propRightValueShows, propFourthValueShows,
            propBottomFieldShows,
            propAodFieldShows, propAodRightFieldShows,
            getBottomField2Shows()
        ];

        for(var i=0; i<weatherFields.size(); i++) {
            if (isWeatherSource(weatherFields[i])) {
                isWeatherRequired = true;
                break;
            }
        }

        initializeWeatherData();

        var propTimeSeparator = (propBitmapA >> 27) & 0x3;
        if(propTimeSeparator == 2) { clockBgText = "####"; } else { clockBgText = "#####"; }
    }

    hidden function getAltitudeValue() as Float? {
        if(refreshCache has :altitudeValueLoaded) {
            return (refreshCache as Dictionary).get(:altitudeValue) as Float?;
        }

        var altitude = null;

        // 1. Best: Complications (Modern approach)
        if (hasComplications) {
            try {
                var comp = Complications.getComplication(new Id(Complications.COMPLICATION_TYPE_ALTITUDE));
                if (comp != null && comp.value != null) {
                    altitude = comp.value.toFloat();
                }
            } catch(e) {}
        }

        // 2. From Sensor History
        if (altitude == null && (Toybox has :SensorHistory) && (Toybox.SensorHistory has :getElevationHistory)) {
            var elv_iterator = Toybox.SensorHistory.getElevationHistory({:period => 1});
            if (elv_iterator != null) {
                var sample = elv_iterator.next();
                if (sample != null && sample.data != null) {
                    altitude = sample.data.toFloat();
                }
            }
        }

        // 3. Fallback: Activity Info
        if (altitude == null) {
            var info = getCachedActivityDetails();
            if (info != null && info.altitude != null) {
                altitude = info.altitude.toFloat();
            }
        }

        refreshCache[:altitudeValueLoaded] = true;
        refreshCache[:altitudeValue] = altitude;
        return altitude;
    }

    hidden function getClockData(now as Gregorian.Info) as String {
        var propTimeSeparator = (propBitmapA >> 27) & 0x3;
        var propZeropadHour = ((propBitmapA >> 26) & 0x1) == 1;
        var separator = ":";
        if(propTimeSeparator == 1) { separator = " "; }
        if(propTimeSeparator == 2) { separator = ""; }

        if(propZeropadHour) {
            return formatHour(now.hour).format("%02d") + separator + now.min.format("%02d");
        } else {
            return formatHour(now.hour).format("%2d") + separator + now.min.format("%02d");
        }
    }

    hidden function getIconState(setting as Number, activityInfo) as String {
        var deviceSettings = getCachedDeviceSettings();
        if (deviceSettings == null) { return ""; }

        if(setting == 1) { // Alarm
            var alarms = (deviceSettings has :alarmCount) ? deviceSettings.alarmCount : null;
            if(alarms > 0) {
                return "A";
            } else {
                return "";
            }
        } else if(setting == 2) { // DND
            var dnd = (deviceSettings has :doNotDisturb) ? deviceSettings.doNotDisturb : false;
            if(dnd) {
                return "D";
            } else {
                return "";
            }
        } else if(setting == 3) { // Bluetooth (on / off)
            var bl = (deviceSettings has :phoneConnected) ? deviceSettings.phoneConnected : false;
            if(bl) {
                return "L";
            } else {
                return "M";
            }
        } else if(setting == 4) { // Bluetooth (just off)
            var bl = (deviceSettings has :phoneConnected) ? deviceSettings.phoneConnected : false;
            if(bl) {
                return "";
            } else {
                return "M";
            }
        } else if(setting == 5) { // Move bar
            var mov = 0;
            if(activityInfo != null && activityInfo has :moveBarLevel) {
                if(activityInfo.moveBarLevel != null) {
                    mov = activityInfo.moveBarLevel;
                }
            }
            if(mov == 0) { return ""; }
            if(mov == 1) { return "N"; }
            if(mov == 2) { return "O"; }
            if(mov == 3) { return "P"; }
            if(mov == 4) { return "Q"; }
            if(mov == 5) { return "R"; }
        }
        return "";
    }

    hidden function getBarData(data_source as Number, activityInfo) as Number? {
        if(data_source == 1) {
            return getStressData();
        } else if (data_source == 2) {
            return getBBData();
        } else if (data_source == 3) {
            return getStepGoalProgress(activityInfo);
        } else if (data_source == 4) {
            return getFloorGoalProgress(activityInfo);
        } else if (data_source == 5) {
            return getActMinGoalProgress(activityInfo);
        } else if (data_source == 6) {
            return getMoveBar(activityInfo);
        }
        return null;
    }

    hidden function getStressData() as Number? {
        if (cachedStressDataValid) { return cachedStressData; }

        var result = null;
        if (hasComplications) {
            try {
                var complication_stress = Complications.getComplication(new Id(Complications.COMPLICATION_TYPE_STRESS));
                if (complication_stress != null && complication_stress.value != null) {
                    result = complication_stress.value;
                }
            } catch(e) {
                // Complication not found
            }
        }

        if (result == null && (Toybox has :SensorHistory) && (Toybox.SensorHistory has :getBodyBatteryHistory) && (Toybox.SensorHistory has :getStressHistory)) {
            var st_iterator = Toybox.SensorHistory.getStressHistory({:period => 1});
            if (st_iterator != null) {
                var st = st_iterator.next();

                if(st != null) {
                    result = st.data;
                }
            }
        }

        cachedStressData = result;
        cachedStressDataValid = true;
        return result;
    }

    hidden function getStressColor(val as Number) as Graphics.ColorType {
        if (val <= 25) { return 0x00AAFF; } // Rest (Blue)
        if (val <= 50) { return 0xFFAA00; } // Low (Yellow/Orange)
        if (val <= 75) { return 0xFF5500; } // Medium (Orange)
        return 0xAA0000;                   // High (Red)
    }

    hidden function getBBData() as Number? {
        if (cachedBBDataValid) { return cachedBBData; }

        var result = null;
        if (hasComplications) {
            try {
                var complication_bb = Complications.getComplication(new Id(Complications.COMPLICATION_TYPE_BODY_BATTERY));
                if (complication_bb != null && complication_bb.value != null) {
                    result = complication_bb.value;
                }
            } catch(e) {
                // Complication not found
            }
        }

        if (result == null && (Toybox has :SensorHistory) && (Toybox.SensorHistory has :getBodyBatteryHistory) && (Toybox.SensorHistory has :getStressHistory)) {
            var bb_iterator = Toybox.SensorHistory.getBodyBatteryHistory({:period => 1});
            if (bb_iterator != null) {
                var bb = bb_iterator.next();

                if(bb != null) {
                    result = bb.data;
                }
            }
        }

        cachedBBData = result;
        cachedBBDataValid = true;
        return result;
    }

    hidden function getStepGoalProgress(activityInfo) as Number? {
        if (activityInfo == null) { return null; }
        if(activityInfo.steps != null and activityInfo.stepGoal != null) {
            var steps = activityInfo.steps;
            var goal = activityInfo.stepGoal;
            if(goal == null or goal == 0) { return 0; }
            if(steps == null or steps == 0) { return 0; }
            return Math.round(steps.toFloat() / goal.toFloat() * 100.0);
        }
        return null;
    }

    hidden function getFloorGoalProgress(activityInfo) as Number? {
        if (activityInfo == null) { return null; }
        if(activityInfo has :floorsClimbed and activityInfo has :floorsClimbedGoal) {
            if(activityInfo.floorsClimbed != null and activityInfo.floorsClimbedGoal != null) {
                var floors = activityInfo.floorsClimbed;
                var goal = activityInfo.floorsClimbedGoal;
                if(goal == null or goal == 0) { return 0; }
                if(floors == null or floors == 0) { return 0; }
                return Math.round(floors.toFloat() / goal.toFloat() * 100.0);
            }
        }
        return null;
    }

    hidden function getActMinGoalProgress(activityInfo) as Number? {
        if (activityInfo == null) { return null; }
        if(activityInfo.activeMinutesWeek != null and activityInfo.activeMinutesWeekGoal != null) {
            var actmin = activityInfo.activeMinutesWeek;
            var val = actmin.total;
            var goal = activityInfo.activeMinutesWeekGoal;
            if(goal == null or goal == 0) { return 0; }
            if(val == null or val == 0) { return 0; }
            return Math.round(val.toFloat() / goal.toFloat() * 100.0);
        }
        return null;
    }

    hidden function getMoveBar(activityInfo) as Number? {
        if (activityInfo == null) { return null; }
        if(activityInfo has :moveBarLevel) {
            if(activityInfo.moveBarLevel != null) {
                var mov = activityInfo.moveBarLevel;
                if(mov == 1) { return 40; }
                if(mov == 2) { return 55; }
                if(mov == 3) { return 70; }
                if(mov == 4) { return 85; }
                if(mov == 5) { return 100; }
            }
        }
        return null;
    }

    hidden function getBattData(sysStats as System.Stats) as String {
        var value = "";
        var batteryVariant = getBatteryDisplayVariant(sysStats);

        if(batteryVariant == 1) {
            var sample = sysStats.battery;
            if(sample < 100) {
                value = sample.format("%d") + "%";
            } else {
                value = sample.format("%d");
            }
        } else {
            var sample = 0;
            var max = 0;
            var batLevel = sysStats.battery;

            if(screenHeight > 280) {
                sample = Math.round(batLevel / 100.0 * 35).toNumber();
                max = 35;
            } else {
                sample = Math.round(batLevel / 100.0 * 20).toNumber();
                max = 20;
            }
            if(sample > 0) {
                value += battFull.substring(0, sample);
            }

            if(sample < max) {
                value += battEmpty.substring(0, max - sample);
            }
        }

        return value;
    }

    hidden function formatHour(hour as Number) as Number {
        var propIs24H = ((propBitmapB >> 16) & 0x1) == 1;
        var propHourFormat = (propBitmapA >> 24) & 0x3;
        if((!propIs24H and propHourFormat == 0) or propHourFormat == 2) {
            hour = hour % 12;
            if(hour == 0) { hour = 12; }
        }
        return hour;
    }

    hidden function getActiveWeatherCondition() {
        if (weatherConditionOverride != null) {
            return weatherConditionOverride;
        }
        return weatherCondition;
    }

    hidden function getActiveForecastChange() as Array? {
        if (weatherConditionOverride != null) {
            return forecastChangeOverride;
        }
        return cachedForecastChange;
    }

    hidden function getActiveForecastWorse() as Array? {
        if (weatherConditionOverride != null) {
            return forecastWorseOverride;
        }
        return cachedForecastWorse;
    }

    hidden function toNumberOrNull(value) as Number? {
        if (value == null) { return null; }
        return value.toNumber();
    }

    hidden function toFloatOrNull(value) as Float? {
        if (value == null) { return null; }
        return value.toFloat();
    }

    hidden function copyWeatherToSnapshot(snapshot as ForecastWeather, weather) as Void {
        if (weather == null) { return; }

        if (weather.observationLocationPosition != null) { snapshot.observationLocationPosition = weather.observationLocationPosition; }
        if (weather.precipitationChance != null) { snapshot.precipitationChance = weather.precipitationChance; }
        if (weather.temperature != null) { snapshot.temperature = weather.temperature.toNumber(); }
        if (weather.windBearing != null) { snapshot.windBearing = weather.windBearing.toNumber(); }
        if (weather.windSpeed != null) { snapshot.windSpeed = weather.windSpeed.toFloat(); }
        if (weather.highTemperature != null) { snapshot.highTemperature = weather.highTemperature.toNumber(); }
        if (weather.lowTemperature != null) { snapshot.lowTemperature = weather.lowTemperature.toNumber(); }
        if (weather.feelsLikeTemperature != null) { snapshot.feelsLikeTemperature = weather.feelsLikeTemperature.toFloat(); }
        if (weather.relativeHumidity != null) { snapshot.relativeHumidity = weather.relativeHumidity.toNumber(); }
        if (weather.condition != null) { snapshot.condition = weather.condition.toNumber(); }
        if (weather has :uvIndex && weather.uvIndex != null && weather.uvIndex.toFloat() >= 0.0f) {
            snapshot.uvIndex = weather.uvIndex.toFloat();
        }
        if (weather has :forecastTime && weather.forecastTime != null) {
            snapshot.forecastTime = weather.forecastTime.toNumber();
        }
        if (weather has :forecastHour && weather.forecastHour != null) {
            snapshot.forecastHour = weather.forecastHour.toNumber();
        }
    }

    hidden function buildMergedForecastWeather(forecast as ForecastWeather or Null) as ForecastWeather {
        var snapshot = new ForecastWeather();
        copyWeatherToSnapshot(snapshot, weatherCondition);
        copyWeatherToSnapshot(snapshot, forecast);
        return snapshot;
    }

    hidden function buildForecastWeatherFromLive(entry) as ForecastWeather {
        var forecast = new ForecastWeather();
        if (entry == null) { return forecast; }

        if (entry.forecastTime != null) {
            forecast.forecastTime = entry.forecastTime.value();
            forecast.forecastHour = Time.Gregorian.info(entry.forecastTime, Time.FORMAT_SHORT).hour;
        }

        forecast.condition = toNumberOrNull(entry.condition);
        forecast.temperature = toNumberOrNull(entry.temperature);
        forecast.windBearing = toNumberOrNull(entry.windBearing);
        forecast.windSpeed = toFloatOrNull(entry.windSpeed);
        forecast.precipitationChance = toNumberOrNull(entry.precipitationChance);

        if (entry has :highTemperature) { forecast.highTemperature = toNumberOrNull(entry.highTemperature); }
        if (entry has :lowTemperature) { forecast.lowTemperature = toNumberOrNull(entry.lowTemperature); }
        if (entry has :feelsLikeTemperature) { forecast.feelsLikeTemperature = toFloatOrNull(entry.feelsLikeTemperature); }
        if (entry has :relativeHumidity) { forecast.relativeHumidity = toNumberOrNull(entry.relativeHumidity); }
        if (entry has :uvIndex) {
            var uv = toFloatOrNull(entry.uvIndex);
            if (uv != null && uv >= 0.0f) { forecast.uvIndex = uv; }
        }

        return forecast;
    }

    (:WeatherCache)
    hidden function buildForecastWeatherFromStored(entry) as ForecastWeather {
        var forecast = new ForecastWeather();
        if (entry == null) { return forecast; }

        forecast.forecastTime = toNumberOrNull(entry.get("forecastTime"));
        forecast.forecastHour = toNumberOrNull(entry.get("forecastHour"));
        forecast.condition = toNumberOrNull(entry.get("condition"));
        forecast.temperature = toNumberOrNull(entry.get("temperature"));
        forecast.windBearing = toNumberOrNull(entry.get("windBearing"));
        forecast.windSpeed = toFloatOrNull(entry.get("windSpeed"));
        forecast.precipitationChance = toNumberOrNull(entry.get("precipitationChance"));
        forecast.highTemperature = toNumberOrNull(entry.get("highTemperature"));
        forecast.lowTemperature = toNumberOrNull(entry.get("lowTemperature"));
        forecast.feelsLikeTemperature = toFloatOrNull(entry.get("feelsLikeTemperature"));
        forecast.relativeHumidity = toNumberOrNull(entry.get("relativeHumidity"));

        var uv = toFloatOrNull(entry.get("uvIndex"));
        if (uv != null && uv >= 0.0f) {
            forecast.uvIndex = uv;
        }

        return forecast;
    }

    (:WeatherCache)
    hidden function initializeWeatherData() as Void {
        if (isWeatherRequired && weatherCondition == null) {
            try { weatherCondition = readWeatherData(); } catch(e) {}
            if (weatherCondition == null) {
                if(Toybox has :Weather && Weather has :getCurrentConditions) {
                    weatherCondition = Weather.getCurrentConditions();
                }
            }
        }
        cachedTempUnit = getTempUnit();
        updateHourlyForecastData(null);
        updateForecastChanges();
    }

    (:NoWeatherCache)
    hidden function initializeWeatherData() as Void {
        if (isWeatherRequired && weatherCondition == null) {
            if(Toybox has :Weather && Weather has :getCurrentConditions) {
                weatherCondition = Weather.getCurrentConditions();
            }
        }
        cachedTempUnit = getTempUnit();
        updateHourlyForecastData(null);
        updateForecastChanges();
    }

    (:WeatherCache)
    hidden function updateWeather() as Void {
        if (!isWeatherRequired) { return; }
        if(!(Toybox has :Weather) or !(Weather has :getCurrentConditions)) { return; }

        var cc = Weather.getCurrentConditions();
        var hf = null;
        if (Weather has :getHourlyForecast) {
            hf = Weather.getHourlyForecast();
        }
        if(cc != null) {
            weatherCondition = cc;
            try { storeWeatherData(cc, hf); } catch(e) {}
        } else {
            try { weatherCondition = readWeatherData(); } catch(e) {}
        }
        cachedTempUnit = getTempUnit();
        updateHourlyForecastData(hf);
        updateForecastChanges();
    }

    (:NoWeatherCache)
    hidden function updateWeather() as Void {
        if (!isWeatherRequired) { return; }
        if(!(Toybox has :Weather) or !(Weather has :getCurrentConditions)) { return; }
        var cc = Weather.getCurrentConditions();
        var hf = null;
        if (Weather has :getHourlyForecast) {
            hf = Weather.getHourlyForecast();
        }
        weatherCondition = cc;
        cachedTempUnit = getTempUnit();
        updateHourlyForecastData(hf);
        updateForecastChanges();
    }

    (:WeatherCache)
    hidden function updateHourlyForecastData(hfOverride as Array?) as Void {
        cachedHourlyForecast = [];
        var hf = hfOverride;

        if (hf == null && Toybox has :Weather && Weather has :getHourlyForecast) {
            hf = Weather.getHourlyForecast();
        }

        if (hf != null) {
            if (hf != null && hf.size() > 0) {
                for (var i = 0; i < hf.size(); i++) {
                    cachedHourlyForecast.add(buildForecastWeatherFromLive(hf[i]));
                }
                return;
            }
        }

        var hfData = Application.Storage.getValue("hourly_forecast") as Array?;
        if (hfData == null) { return; }

        for (var i = 0; i < hfData.size(); i++) {
            cachedHourlyForecast.add(buildForecastWeatherFromStored(hfData[i]));
        }
    }

    (:NoWeatherCache)
    hidden function updateHourlyForecastData(hfOverride as Array?) as Void {
        cachedHourlyForecast = [];
        var hf = hfOverride;

        if (hf == null) {
            if (!(Toybox has :Weather) || !(Weather has :getHourlyForecast)) { return; }
            hf = Weather.getHourlyForecast();
        }

        if (hf == null || hf.size() == 0) { return; }

        for (var i = 0; i < hf.size(); i++) {
            cachedHourlyForecast.add(buildForecastWeatherFromLive(hf[i]));
        }
    }

    hidden function isWeatherSource(id as Number) as Boolean {
        if (id == 20 || id == 39 || id == 40 || (id >= 43 && id <= 55) || (id >= 63 && id <= 79)) {
            return true;
        }
        return false;
    }

    (:WeatherCache)
    hidden function computeCcHash(cc) as Number {
        if (cc == null) { return 0; }
        
        var h = 17;

        var t = (cc.temperature != null) ? cc.temperature : -127;
        h = 31 * h + t;
        var c = (cc.condition != null) ? cc.condition : -1;
        h = 31 * h + c;
        var w = (cc.windSpeed != null) ? cc.windSpeed.toNumber() : -1;
        h = 31 * h + w;
        var b = (cc.windBearing != null) ? cc.windBearing : -1;
        h = 31 * h + b;

        return h;
    }

    (:WeatherCache)
    hidden function storeWeatherData(cc, hf as Array?) as Void {
        var now = Time.now().value();
        var sysStats = System.getSystemStats();

        if (!isLowMem && sysStats.freeMemory < 15000) {
            isLowMem = true;
            Application.Storage.setValue("hourly_forecast", []); 
            lastHfTime = null; 
        } else if (isLowMem && sysStats.freeMemory > 17000) {
            isLowMem = false;
        }

        var newCcHash = computeCcHash(cc);

        if (lastCcHash == null || lastCcHash != newCcHash) {
            var cc_data = {};
            if(cc != null) {
                if(cc.observationLocationPosition != null) {
                    cc_data["observationLocationPosition"] = cc.observationLocationPosition.toDegrees();
                }
                if(cc.condition != null) { cc_data["condition"] = cc.condition; }
                if(cc.highTemperature != null) { cc_data["highTemperature"] = cc.highTemperature; }
                if(cc.lowTemperature != null) { cc_data["lowTemperature"] = cc.lowTemperature; }
                if(cc.precipitationChance != null) { cc_data["precipitationChance"] = cc.precipitationChance; }
                if(cc.relativeHumidity != null) { cc_data["relativeHumidity"] = cc.relativeHumidity; }
                if(cc.temperature != null) { cc_data["temperature"] = cc.temperature; }
                if(cc.feelsLikeTemperature != null) { cc_data["feelsLikeTemperature"] = cc.feelsLikeTemperature; }
                if(cc.windBearing != null) { cc_data["windBearing"] = cc.windBearing; }
                if(cc.windSpeed != null) { cc_data["windSpeed"] = cc.windSpeed; }
                if (cc has :uvIndex && cc.uvIndex != null) {
                    cc_data["uvIndex"] = cc.uvIndex;
                } else {
                    cc_data["uvIndex"] = -1;
                }
            }

            cc_data["timestamp"] = now;
            Application.Storage.setValue("current_conditions", cc_data);
            
            lastCcHash = newCcHash;
        }

        if (isLowMem) { return; }

        if (hf == null || hf.size() == 0) { return; }

        var firstForecastTime = hf[0].forecastTime.value();

        if (lastHfTime == null || lastHfTime != firstForecastTime) {
            var hf_data = [];
            
            for(var i=0; i<hf.size(); i++) {
                var tmp = {
                    "forecastTime" => hf[i].forecastTime.value(),
                    "forecastHour" => Time.Gregorian.info(hf[i].forecastTime, Time.FORMAT_SHORT).hour,
                    "condition" => hf[i].condition,
                    "temperature" => hf[i].temperature,
                    "windBearing" => hf[i].windBearing,
                    "windSpeed" => hf[i].windSpeed
                };
                if(hf[i].precipitationChance != null) { tmp["precipitationChance"] = hf[i].precipitationChance; }
                if(hf[i] has :highTemperature && hf[i].highTemperature != null) { tmp["highTemperature"] = hf[i].highTemperature; }
                if(hf[i] has :lowTemperature && hf[i].lowTemperature != null) { tmp["lowTemperature"] = hf[i].lowTemperature; }
                if(hf[i] has :feelsLikeTemperature && hf[i].feelsLikeTemperature != null) { tmp["feelsLikeTemperature"] = hf[i].feelsLikeTemperature; }
                if(hf[i] has :relativeHumidity && hf[i].relativeHumidity != null) { tmp["relativeHumidity"] = hf[i].relativeHumidity; }
                if(hf[i] has :uvIndex && hf[i].uvIndex != null) { 
                    tmp["uvIndex"] = hf[i].uvIndex; 
                } else {
                    tmp["uvIndex"] = -1;
                }
                
                hf_data.add(tmp);
            }

            Application.Storage.setValue("hourly_forecast", hf_data);
            lastHfTime = firstForecastTime;
        }
    }

    (:WeatherCache)
    hidden function readWeatherData() as StoredWeather {
        var ret = new StoredWeather();
        var now = Time.now().value();
        var cc_data = Application.Storage.getValue("current_conditions") as Dictionary<String, Application.PropertyValueType>?;
        if(cc_data == null) { return ret; }
        
        var data_age_s = now - (cc_data.get("timestamp") as Number);
        var pos = cc_data.get("observationLocationPosition") as Array?;
        if (pos != null) {
            ret.observationLocationPosition = new Position.Location({:latitude => pos[0], :longitude => pos[1], :format => :degrees});
        }
        if(data_age_s > 0 and data_age_s < 3600) {
            ret.condition = cc_data.get("condition") as Number;
            ret.highTemperature = cc_data.get("highTemperature") as Number;
            ret.lowTemperature = cc_data.get("lowTemperature") as Number;
            ret.precipitationChance = cc_data.get("precipitationChance") as Number;
            ret.relativeHumidity = cc_data.get("relativeHumidity") as Number;
            ret.temperature = cc_data.get("temperature") as Number;
            ret.feelsLikeTemperature = cc_data.get("feelsLikeTemperature") as Float;
            ret.windBearing = cc_data.get("windBearing") as Number;
            ret.windSpeed = cc_data.get("windSpeed") as Float;
            var currentUv = cc_data.get("uvIndex") as Float;
            if (currentUv != null && currentUv >= 0.0f) {
                ret.uvIndex = currentUv;
            }
        } else {
            var hf_data = Application.Storage.getValue("hourly_forecast") as Array?;
            if(hf_data == null) { return ret; }
            for(var i=0; i<hf_data.size(); i++) {
                var forecast_age = now - (hf_data[i].get("forecastTime") as Number);
                if(forecast_age > 0 and forecast_age < 3600) {
                    ret.condition = hf_data[i].get("condition") as Number;
                    ret.temperature = hf_data[i].get("temperature") as Number;
                    ret.highTemperature = hf_data[i].get("highTemperature") as Number;
                    ret.lowTemperature = hf_data[i].get("lowTemperature") as Number;
                    ret.precipitationChance = hf_data[i].get("precipitationChance") as Number;
                    ret.relativeHumidity = hf_data[i].get("relativeHumidity") as Number;
                    ret.feelsLikeTemperature = hf_data[i].get("feelsLikeTemperature") as Float;
                    ret.windBearing = hf_data[i].get("windBearing") as Number;
                    ret.windSpeed = hf_data[i].get("windSpeed") as Float;
                    var forecastUv = hf_data[i].get("uvIndex") as Float;
                    if (forecastUv != null && forecastUv >= 0.0f) {
                        ret.uvIndex = forecastUv;
                    }
                }
            }
        }
        
        return ret;
    }

    hidden function getValueByTypeWithUnit(complicationType as Number, width as Number, now as Gregorian.Info, activityInfo, sysStats as System.Stats) as String {
        var unit = getUnitByType(complicationType);
        if (unit.length() > 0) {
            unit = " " + unit;
        }
        return getValueByType(complicationType, width, now, activityInfo, sysStats) + unit;
    }

    hidden function getValueByTypeWithUnitWithWeather(complicationType as Number, width as Number, now as Gregorian.Info, activityInfo, sysStats as System.Stats, weatherOverride as ForecastWeather or Null, changeOverride as Array?, worseOverride as Array?) as String {
        var previousWeather = weatherConditionOverride;
        var previousChange = forecastChangeOverride;
        var previousWorse = forecastWorseOverride;

        weatherConditionOverride = weatherOverride;
        forecastChangeOverride = changeOverride;
        forecastWorseOverride = worseOverride;

        var value = getValueByTypeWithUnit(complicationType, width, now, activityInfo, sysStats);

        weatherConditionOverride = previousWeather;
        forecastChangeOverride = previousChange;
        forecastWorseOverride = previousWorse;

        return value;
    }

    hidden function getWeatherLineValue(complicationType as Number, width as Number, now as Gregorian.Info, activityInfo, sysStats as System.Stats) as String {
        if (lineWeatherCondition == null || !isWeatherSource(complicationType)) {
            return getValueByTypeWithUnit(complicationType, width, now, activityInfo, sysStats);
        }

        if (complicationType == 79) {
            return formatWeatherCycleValue(lineWeatherCondition, cachedLineForecastChange, cachedLineForecastWorse);
        }

        return getValueByTypeWithUnitWithWeather(complicationType, width, now, activityInfo, sysStats, lineWeatherCondition, null, null);
    }

    hidden function getUnitByType(complicationType) as String {
        if(complicationType == 11 or complicationType == 29 or complicationType == 58) { // Calories
            return cachedUnitKcal;
        } else if(complicationType == 12) { // Altitude (m)
            return cachedUnitM;
        } else if(complicationType == 15) { // Altitude (ft)
            return cachedUnitFt;
        } else if(complicationType == 17) { // Steps / day
            return cachedUnitSteps;
        } else if(complicationType == 19) { // Wheelchair pushes
            return cachedUnitPushes;
        }
        return "";
    }

    hidden function getValueByType(complicationType as Number, width as Number, now as Gregorian.Info, activityInfo, sysStats as System.Stats) as String {
        var val = "";
        var numberFormat = "%d";

        if(complicationType == -2) { // Hidden
            return "";
        } else if(complicationType == -1) { // Date
            val = formatDate(now);
        } else if(complicationType == 0) { // Active min / week
            if(activityInfo has :activeMinutesWeek) {
                if(activityInfo.activeMinutesWeek != null) {
                    val = activityInfo.activeMinutesWeek.total.format(numberFormat);
                }
            }
        } else if(complicationType == 1) { // Active min / day
            if(activityInfo has :activeMinutesDay) {
                if(activityInfo.activeMinutesDay != null) {
                    val = activityInfo.activeMinutesDay.total.format(numberFormat);
                }
            }
        } else if(complicationType == 2) { // distance (km) / day
            if(activityInfo has :distance) {
                if(activityInfo.distance != null) {
                    var distance_km = activityInfo.distance / 100000.0;
                    val = formatDistanceByWidth(distance_km, width);
                }
            }
        } else if(complicationType == 3) { // distance (miles) / day
            if(activityInfo has :distance) {
                if(activityInfo.distance != null) {
                    var distance_miles = activityInfo.distance / 160900.0;
                    val = formatDistanceByWidth(distance_miles, width);
                }
            }
        } else if(complicationType == 4) { // floors climbed / day
            if(activityInfo has :floorsClimbed) {
                if(activityInfo.floorsClimbed != null) {
                    val = activityInfo.floorsClimbed.format(numberFormat);
                }
            }
        } else if(complicationType == 5) { // meters climbed / day
            if(activityInfo has :metersClimbed) {
                if(activityInfo.metersClimbed != null) {
                    val = activityInfo.metersClimbed.format(numberFormat);
                }
            }
        } else if(complicationType == 6) { // Time to Recovery (h)
            if (hasComplications) {
                try {
                    var complication = Complications.getComplication(new Id(Complications.COMPLICATION_TYPE_RECOVERY_TIME));
                    if (complication != null && complication.value != null) {
                        var recovery_h = complication.value / 60.0;
                        if(recovery_h > 60) {
                            val = Math.round(recovery_h / 24.0).format(numberFormat) + "d";
                        } else { val = Math.round(recovery_h).format(numberFormat); }
                    }
                } catch(e) {}
            } else {
                    if(activityInfo has :timeToRecovery) {
                    if(activityInfo.timeToRecovery != null) {
                        var recovery_h = activityInfo.timeToRecovery;
                        if(recovery_h > 60) {
                            val = Math.round(recovery_h / 24.0).format(numberFormat) + "d";
                        } else {
                            val = Math.round(recovery_h).format(numberFormat);
                        }
                    }
                }
            }
            
        } else if(complicationType == 7) { // VO2 Max Running
            var profile = getCachedUserProfile();
            if(profile has :vo2maxRunning) {
                if(profile.vo2maxRunning != null) {
                    val = profile.vo2maxRunning.format(numberFormat);
                }
            }
        } else if(complicationType == 8) { // VO2 Max Cycling
            var profile = getCachedUserProfile();
            if(profile has :vo2maxCycling) {
                if(profile.vo2maxCycling != null) {
                    val = profile.vo2maxCycling.format(numberFormat);
                }
            }
        } else if(complicationType == 9) { // Respiration rate
            if(activityInfo has :respirationRate) {
                var resp_rate = activityInfo.respirationRate;
                if(resp_rate != null) {
                    val = resp_rate.format(numberFormat);
                }
            }
        } else if(complicationType == 10) {
            // Try to retrieve live HR from Activity::Info
            var activity_info = getCachedActivityDetails();
            var sample = activity_info != null ? activity_info.currentHeartRate : null;
            if(sample != null) {
                val = sample.format("%01d");
            } else if (ActivityMonitor has :getHeartRateHistory) {
                // Falling back to historical HR from ActivityMonitor
                var history = ActivityMonitor.getHeartRateHistory(1, /* newestFirst */ true);
                if (history != null) {
                    var hist = history.next();
                    if ((hist != null) && (hist.heartRate != ActivityMonitor.INVALID_HR_SAMPLE)) {
                        val = hist.heartRate.format("%01d");
                    }
                }
            }
        } else if(complicationType == 11) { // Calories
            if (activityInfo has :calories) {
                if(activityInfo.calories != null) {
                    val = activityInfo.calories.format(numberFormat);
                }
            }
        } else if(complicationType == 12) { // Altitude (m)
                var alt = getAltitudeValue();
                if (alt != null) {
                    val = alt.format(numberFormat);
            }
        } else if(complicationType == 13) { // Stress
        var st = getStressData();
            if(st != null) {
                val = st.format(numberFormat);
            }
        } else if(complicationType == 14) { // Body battery
            var bb = getBBData();
            if(bb != null) {
                val = bb.format(numberFormat);
            }
        } else if(complicationType == 15) { // Altitude (ft)
            var alt = getAltitudeValue();
            if (alt != null) {
                val = (alt * 3.28084).format(numberFormat);
            }
        } else if(complicationType == 17) { // Steps / day
            if(activityInfo.steps != null) {
                if(width >= 5) {
                    val = activityInfo.steps.format(numberFormat);
                } else {
                    var steps_k = activityInfo.steps / 1000.0;
                    if(steps_k < 10 and width == 4) {
                        val = steps_k.format("%.1f") + "K";
                    } else {
                        val = steps_k.format("%d") + "K";
                    }
                }

            }
        } else if(complicationType == 18) { // Distance (m) / day
            if(activityInfo.distance != null) {
                val = (activityInfo.distance / 100).format(numberFormat);
            }
        } else if(complicationType == 19) { // Wheelchair pushes
            if(activityInfo has :pushes) {
                if(activityInfo.pushes != null) {
                    val = activityInfo.pushes.format(numberFormat);
                }
            }
        } else if(complicationType == 20) { // Weather condition
            val = getWeatherCondition(true);
        } else if(complicationType == 21) { // Weekly run distance (km)
            val = getWeeklyDistanceFromComplication(true, 0.001, width);
        } else if(complicationType == 22) { // Weekly run distance (miles)
            val = getWeeklyDistanceFromComplication(true, 0.000621371, width);
        } else if(complicationType == 23) { // Weekly bike distance (km)
            val = getWeeklyDistanceFromComplication(false, 0.001, width);
        } else if(complicationType == 24) { // Weekly bike distance (miles)
            val = getWeeklyDistanceFromComplication(false, 0.000621371, width);
        } else if(complicationType == 25) { // Training status
            if (hasComplications) {
                try {
                    var complication = Complications.getComplication(new Id(Complications.COMPLICATION_TYPE_TRAINING_STATUS));
                    if (complication != null && complication.value != null) {
                        val = complication.value.toUpper();
                    }
                } catch(e) {
                    // Complication not found
                }
            }
        } else if(complicationType == 26) { // Raw Barometric pressure (hPA)
            var info = getCachedActivityDetails();
            if (info has :rawAmbientPressure && info.rawAmbientPressure != null) {
                val = formatPressure(info.rawAmbientPressure / 100.0, width);
            }
        } else if(complicationType == 27) { // Weight kg
            var profile = getCachedUserProfile();
            if(profile has :weight) {
                if(profile.weight != null) {
                    var weight_kg = profile.weight / 1000.0;
                    if (width == 3) {
                        val = weight_kg.format(numberFormat);
                    } else {
                        val = weight_kg.format("%.1f");
                    }
                }
            }
        } else if(complicationType == 28) { // Weight lbs
            var profile = getCachedUserProfile();
            if(profile has :weight) {
                if(profile.weight != null) {
                    val = (profile.weight * 0.00220462).format(numberFormat);
                }
            }
        } else if(complicationType == 29) { // Act Calories
            var rest_calories = getRestCalories();
            // Get total calories and subtract rest calories
            if (activityInfo has :calories && activityInfo.calories != null && rest_calories > 0) {
                var active_calories = activityInfo.calories - rest_calories;
                if (active_calories > 0) {
                    val = active_calories.format(numberFormat);
                } else { val = "0"; }
            }
        } else if(complicationType == 30) { // Sea level pressure (hPA)
            var info = getCachedActivityDetails();
            if (info has :meanSeaLevelPressure && info.meanSeaLevelPressure != null) {
                val = formatPressure(info.meanSeaLevelPressure / 100.0, width);
            }
        } else if(complicationType == 31) { // Week number
            var week_number = isoWeekNumber(now.year, now.month, now.day);
            val = week_number.format(numberFormat);
        } else if(complicationType == 32) { // Weekly distance (km)
            var weekly_distance = getWeeklyDistance(activityInfo) / 100000.0;  // Convert to km
            val = formatDistanceByWidth(weekly_distance, width);
        } else if(complicationType == 33) { // Weekly distance (miles)
            var weekly_distance = getWeeklyDistance(activityInfo) * 0.00000621371;  // Convert to miles
            val = formatDistanceByWidth(weekly_distance, width);
        } else if(complicationType == 34) { // Battery percentage
            var battery = sysStats.battery;
            val = battery.format("%d");
        } else if(complicationType == 35) { // Battery days remaining
            if(sysStats has :batteryInDays) {
                if (sysStats.batteryInDays != null){
                    var sample = Math.round(sysStats.batteryInDays);
                    val = sample.format(numberFormat);
                }
            }
        } else if(complicationType == 36) { // Notification count
            var deviceSettings = getCachedDeviceSettings();
            var notif_count = (deviceSettings != null && deviceSettings has :notificationCount) ? deviceSettings.notificationCount : null;
            if(notif_count != null) {
                if(width == 2 and notif_count == 0) {
                    val = ""; // Hide when shown in the notification field and is zero
                } else {
                    val = notif_count.format(numberFormat);
                }
            }
        } else if(complicationType == 37) { // Solar intensity
            if(sysStats has :solarIntensity and sysStats.solarIntensity != null) {
                val = sysStats.solarIntensity.format(numberFormat);
            }
        } else if(complicationType == 38) { // Sensor temperature
            if ((Toybox has :SensorHistory) and (Toybox.SensorHistory has :getTemperatureHistory)) {
                var tempIterator = Toybox.SensorHistory.getTemperatureHistory({:period => 1});
                if (tempIterator != null) {
                    var temp = tempIterator.next();
                    if(temp != null and temp.data != null) {
                        val = formatTemperature(convertTemperature(temp.data, cachedTempUnit));
                    }
                }
            }
        } else if(complicationType == 39) { // Sunrise
            var todaySunEvents = getCachedSunEvents(Time.now(), "today");
            if(todaySunEvents != null && todaySunEvents.size() == 2) {
                var sunrise = Time.Gregorian.info(todaySunEvents[0], Time.FORMAT_SHORT);
                var sunriseHour = formatHour(sunrise.hour);
                if(width < 5) {
                    val = sunriseHour.format("%02d") + sunrise.min.format("%02d");
                } else {
                    val = sunriseHour.format("%02d") + ":" + sunrise.min.format("%02d");
                }
            } else {
                val = cachedLabelNa;
            }
        } else if(complicationType == 40) { // Sunset
            var todaySunEvents = getCachedSunEvents(Time.now(), "today");
            if(todaySunEvents != null && todaySunEvents.size() == 2) {
                var sunset = Time.Gregorian.info(todaySunEvents[1], Time.FORMAT_SHORT);
                var sunsetHour = formatHour(sunset.hour);
                if(width < 5) {
                    val = sunsetHour.format("%02d") + sunset.min.format("%02d");
                } else {
                    val = sunsetHour.format("%02d") + ":" + sunset.min.format("%02d");
                }
            } else {
                val = cachedLabelNa;
            }
        } else if(complicationType == 42) { // Alarms
            var deviceSettings = getCachedDeviceSettings();
            if (deviceSettings != null && deviceSettings has :alarmCount && deviceSettings.alarmCount != null) {
                val = deviceSettings.alarmCount.format(numberFormat);
            }
        } else if(complicationType == 43) { // High temp
            var activeWeather = getActiveWeatherCondition();
            if(activeWeather != null and activeWeather.highTemperature != null) {
                var tempVal = activeWeather.highTemperature;
                val = formatTemperature(convertTemperature(tempVal, cachedTempUnit));
            }
        } else if(complicationType == 44) { // Low temp
            var activeWeather = getActiveWeatherCondition();
            if(activeWeather != null and activeWeather.lowTemperature != null) {
                var tempVal = activeWeather.lowTemperature;
                val = formatTemperature(convertTemperature(tempVal, cachedTempUnit));
            }
        } else if(complicationType == 45) { // Temperature, Wind, Feels like
            var temp = getTemperature();
            var wind = getWind();
            var feelsLike = getFeelsLike(true);
            val = join([temp, wind, feelsLike]);
        } else if(complicationType == 46) { // Temperature, Wind
            var temp = getTemperature();
            var wind = getWind();
            val = join([temp, wind]);
        } else if(complicationType == 47) { // Temperature, Wind, Humidity
            var temp = getTemperature();
            var wind = getWind();
            var humidity = getHumidity();
            val = join([temp, wind, humidity]);
        } else if(complicationType == 48) { // Temperature, Wind, High/Low
            var temp = getTemperature();
            var wind = getWind();
            var highlow = getHighLow();
            val = join([temp, wind, highlow]);
        } else if(complicationType == 49) { // Temperature, Wind, Precipitation chance
            var temp = getTemperature();
            var wind = getWind();
            var precip = getPrecip();
            val = join([temp, wind, precip]);
        } else if(complicationType == 50) { // Weather condition without precipitation
            val = getWeatherCondition(false);
        } else if(complicationType == 51) { // Temperature, Humidity, High/Low
            var temp = getTemperature();
            var humidity = getHumidity();
            var highlow = getHighLow();
            val = join([temp, humidity, highlow]);
        } else if(complicationType == 52) { // Temperature, Percipitation chance, High/Low
            var temp = getTemperature();
            var precip = getPrecip();
            var highlow = getHighLow();
            val = join([temp, precip, highlow]);
        } else if(complicationType == 53) { // Temperature
            val = getTemperature();
        } else if(complicationType == 54) { // Precipitation chance
            val = getPrecip();
            if(width == 3 and val.equals("\u26C6100%")) { val = "\u26C6100"; }
        } else if(complicationType == 55) { // Next Sun Event
            var nextSunEventArray = getNextSunEvent();
            if(nextSunEventArray != null && nextSunEventArray.size() == 2) { 
                var nextSunEvent = Time.Gregorian.info(nextSunEventArray[0], Time.FORMAT_SHORT);
                var nextSunEventHour = formatHour(nextSunEvent.hour);
                if(width < 5) {
                    val = nextSunEventHour.format("%02d") + nextSunEvent.min.format("%02d");
                } else {
                    val = nextSunEventHour.format("%02d") + ":" + nextSunEvent.min.format("%02d");
                }
            }
        } else if(complicationType == 56) { // Millitary Date Time Group
            val = getDateTimeGroup();
        } else if(complicationType == 57) { // Time of the next Calendar Event
            if (hasComplications) {
                try {
                    var complication = Complications.getComplication(new Id(Complications.COMPLICATION_TYPE_CALENDAR_EVENTS));
                    var colon_index = null;
                    if (complication != null && complication.value != null) {
                        val = complication.value;
                        colon_index = val.find(":");
                        if (colon_index != null && colon_index < 2) {
                            val = "0" + val;
                        }
                    } else {
                        val = "--:--";
                    }
                    if (width < 5 and colon_index != null) {
                        val = val.substring(0, 2) + val.substring(3, 5);
                    }
                } catch(e) {
                    // Complication not found
                }
            }
        } else if(complicationType == 58) { // Active / Total calories
            var rest_calories = getRestCalories();
            var total_calories = 0;
            // Get total calories and subtract rest calories
            if (activityInfo has :calories && activityInfo.calories != null) {
                total_calories = activityInfo.calories;
            }
            var active_calories = total_calories - rest_calories;
            active_calories = (active_calories > 0) ? active_calories : 0; // Ensure active calories is not negative
            val = active_calories.format(numberFormat) + "/" + total_calories.format(numberFormat);
        } else if(complicationType == 59) { // PulseOx
            if (hasComplications) {
                try {
                    var complication = Complications.getComplication(new Id(Complications.COMPLICATION_TYPE_PULSE_OX));
                    if (complication != null && complication.value != null) {
                        val = complication.value.format(numberFormat);
                    }
                } catch(e) {
                    // Complication not found
                }
            } else {
                if ((Toybox has :SensorHistory) and (Toybox.SensorHistory has :getOxygenSaturationHistory)) {
                    var it = Toybox.SensorHistory.getOxygenSaturationHistory({:period => 1});
                    if (it != null) {
                        var ox = it.next();
                        if(ox != null and ox.data != null) {
                            val = ox.data.format("%d");
                        }
                    }
                }
            }
        } else if(complicationType == 60) { // Location Long Lat dec deg
            var activityDetails = getCachedActivityDetails();
            var pos = activityDetails != null ? activityDetails.currentLocation : null;
            if(pos != null) {
                var degrees = pos.toDegrees() as Array;
                val = degrees[0] + " " + degrees[1];
            } else {
                val = cachedLabelPosNa;
            }
            
        } else if(complicationType == 61) { // Location Millitary format
            var activityDetails = getCachedActivityDetails();
            var pos = activityDetails != null ? activityDetails.currentLocation : null;
            if(pos != null) {
                val = pos.toGeoString(Position.GEO_MGRS);
            } else {
                val = cachedLabelPosNa;
            }
            
        } else if(complicationType == 62) { // Location Accuracy
            var activityDetails = getCachedActivityDetails();
            var acc = activityDetails != null ? activityDetails.currentLocationAccuracy : null;
            if(acc != null) {
                if(width < 4) {
                    val = (acc as Number).format("%d");
                } else {
                    if (acc >= 0 && acc < 5) {
                        val = ["N/A", "LAST", "POOR", "USBL", "GOOD"][acc];
                    } else {
                        val = (acc as Number).format("%d");
                    }
                }
            }
        } else if(complicationType == 63) { // Temperature, Wind, Humidity, Precipitation chance
            var temp = getTemperature();
            var wind = getWind();
            var humidity = getHumidity();
            var precip = getPrecip();
            val = join([temp, wind, humidity, precip]);
        } else if(complicationType == 64) { // UV Index
            val = getUVIndex();
        } else if(complicationType == 65) { // Temperature, UV Index, High/Low
            var temp = getTemperature();
            var uv = getUVIndex();
            var highlow = getHighLow();
            val = join([temp, uv, highlow]);
        } else if(complicationType == 66) { // Humidity
            val = getHumidity();
        } else if(complicationType == 67) { // Temperature, Feels like, High/Low
            var temp = getTemperature();
            var fl = getFeelsLike(true);
            var highlow = getHighLow();
            val = join([temp, fl, highlow]);
        } else if(complicationType == 68) { // Temperature, UV, Precip
            var temp = getTemperature();
            var uv = getUVIndex();
            var precip = getPrecip();
            val = join([temp, uv, precip]);
        } else if(complicationType == 69) { // Temperature, UV, Wind
            var temp = getTemperature();
            var uv = getUVIndex();
            var wind = getWind();
            val = join([temp, uv, wind]);
        } else if(complicationType == 70) { // Weather condition, Temperature
            var condition = getWeatherCondition(false);
            var temp = getTemperature();
            val = join([condition, temp]);
        } else if(complicationType == 71) { // CGM Glucose + Trend
            val = getCgmReading();
        } else if(complicationType == 72) { // CGM Age (minutes)
            val = getCgmAge();
        } else if(complicationType == 73) { // Weather condition, Feels like
            val = formatWeatherConditionFeelsLike(getActiveWeatherCondition());
        } else if(complicationType == 79) { // Weather condition, Feels like, Until when
            val = formatWeatherCycleValue(getActiveWeatherCondition(), getActiveForecastChange(), getActiveForecastWorse());
        } else if(complicationType == 74) { // Feels like
            val = getFeelsLike(false);
        } else if(complicationType == 75) { // Hours to next sun event
            val = hoursToNextSunEvent();
        } else if(complicationType == 76) { // Resting Heart Rate
            var profile = getCachedUserProfile();
            if(profile has :restingHeartRate) {
                if(profile.restingHeartRate != null) {
                    val = profile.restingHeartRate.format(numberFormat);
                }
            }
        } else if(complicationType == 77) { // Wind, Precipitation chance, UV Index
            var wind = getWind();
            var precip = getPrecip();
            var uv = getUVIndex();
            val = join([wind, precip, uv]);
        } else if(complicationType == 78) { // Wind, Precipitation chance, UV Index, Humidity
            var wind = getWind();
            var precip = getPrecip();
            var uv = getUVIndex();
            var humidity = getHumidity();
            val = join([wind, precip, uv, humidity]);
        }

        return val;
    }

    hidden function getLabelByType(complicationType as Number, labelSize as Number) as String {
        // labelSize 1 = short, 2 = mid, 3 = long

        switch(complicationType) {
            case 0: return formatLabel(Rez.Strings.LABEL_WMIN_1, Rez.Strings.LABEL_WMIN_2, Rez.Strings.LABEL_WMIN_3, labelSize);
            case 1: return formatLabel(Rez.Strings.LABEL_DMIN_1, Rez.Strings.LABEL_DMIN_2, Rez.Strings.LABEL_DMIN_3, labelSize);
            case 2: return formatLabel(Rez.Strings.LABEL_DKM_1, Rez.Strings.LABEL_DKM_2, Rez.Strings.LABEL_DKM_2, labelSize);
            case 3: return formatLabel(Rez.Strings.LABEL_DMI_1, Rez.Strings.LABEL_DMI_2, Rez.Strings.LABEL_DMI_3, labelSize);
            case 4: return Application.loadResource(Rez.Strings.LABEL_FLOORS);
            case 5: return formatLabel(Rez.Strings.LABEL_CLIMB_1, Rez.Strings.LABEL_CLIMB_2, Rez.Strings.LABEL_CLIMB_2, labelSize);
            case 6: return formatLabel(Rez.Strings.LABEL_RECOV_1, Rez.Strings.LABEL_RECOV_2, Rez.Strings.LABEL_RECOV_3, labelSize);
            case 7: return formatLabel(Rez.Strings.LABEL_VO2_1, Rez.Strings.LABEL_VO2_2, Rez.Strings.LABEL_VO2RUN_3, labelSize);
            case 8: return formatLabel(Rez.Strings.LABEL_VO2_1, Rez.Strings.LABEL_VO2_2, Rez.Strings.LABEL_VO2BIKE_3, labelSize);
            case 9: return formatLabel(Rez.Strings.LABEL_RESP_1, Rez.Strings.LABEL_RESP_2, Rez.Strings.LABEL_RESP_3, labelSize);
            case 10: return Application.loadResource(Rez.Strings.LABEL_HR);
            case 11: return formatLabel(Rez.Strings.LABEL_CAL_1, Rez.Strings.LABEL_CAL_2, Rez.Strings.LABEL_CAL_3, labelSize);
            case 12: return formatLabel(Rez.Strings.LABEL_ALT_1, Rez.Strings.LABEL_ALT_2, Rez.Strings.LABEL_ALTM_3, labelSize);
            case 13: return Application.loadResource(Rez.Strings.LABEL_STRESS);
            case 14: return formatLabel(Rez.Strings.LABEL_BBAT_1, Rez.Strings.LABEL_BBAT_2, Rez.Strings.LABEL_BBAT_3, labelSize);
            case 15: return formatLabel(Rez.Strings.LABEL_ALT_1, Rez.Strings.LABEL_ALT_2, Rez.Strings.LABEL_ALTFT_3, labelSize);
            case 17: return Application.loadResource(Rez.Strings.LABEL_STEPS);
            case 18: return formatLabel(Rez.Strings.LABEL_DIST_1, Rez.Strings.LABEL_DIST_2, Rez.Strings.LABEL_DIST_3, labelSize);
            case 19: return Application.loadResource(Rez.Strings.LABEL_PUSHES);
            case 20: return "";
            case 21: return formatLabel(Rez.Strings.LABEL_WKM_1, Rez.Strings.LABEL_WRUNM_2, Rez.Strings.LABEL_WRUNM_3, labelSize);
            case 22: return formatLabel(Rez.Strings.LABEL_WMI_1, Rez.Strings.LABEL_WRUNMI_2, Rez.Strings.LABEL_WRUNMI_3, labelSize);
            case 23: return formatLabel(Rez.Strings.LABEL_WKM_1, Rez.Strings.LABEL_WBIKEKM_2, Rez.Strings.LABEL_WBIKEKM_3, labelSize);
            case 24: return formatLabel(Rez.Strings.LABEL_WMI_1, Rez.Strings.LABEL_WBIKEMI_2, Rez.Strings.LABEL_WBIKEMI_3, labelSize);
            case 25: return Application.loadResource(Rez.Strings.LABEL_TRAINING);
            case 26: return Application.loadResource(Rez.Strings.LABEL_PRESSURE);
            case 27: return formatLabel(Rez.Strings.LABEL_KG_1, Rez.Strings.LABEL_WEIGHT_2, Rez.Strings.LABEL_KG_3, labelSize);
            case 28: return formatLabel(Rez.Strings.LABEL_LBS_1, Rez.Strings.LABEL_WEIGHT_2, Rez.Strings.LABEL_LBS_3, labelSize);
            case 29: return formatLabel(Rez.Strings.LABEL_ACAL_1, Rez.Strings.LABEL_ACAL_2, Rez.Strings.LABEL_ACAL_3, labelSize);
            case 30: return Application.loadResource(Rez.Strings.LABEL_PRESSURE);
            case 31: return Application.loadResource(Rez.Strings.LABEL_WEEK);
            case 32: return formatLabel(Rez.Strings.LABEL_WKM_1, Rez.Strings.LABEL_WDISTKM_2, Rez.Strings.LABEL_WDISTKM_3, labelSize);
            case 33: return formatLabel(Rez.Strings.LABEL_WMI_1, Rez.Strings.LABEL_WDISTMI_2, Rez.Strings.LABEL_WDISTMI_3, labelSize);
            case 34: return formatLabel(Rez.Strings.LABEL_BATT_1, Rez.Strings.LABEL_BATT_2, Rez.Strings.LABEL_BATT_3, labelSize);
            case 35: return formatLabel(Rez.Strings.LABEL_BATTD_1, Rez.Strings.LABEL_BATTD_2, Rez.Strings.LABEL_BATTD_3, labelSize);
            case 36: return formatLabel(Rez.Strings.LABEL_NOTIFS_1, Rez.Strings.LABEL_NOTIFS_1, Rez.Strings.LABEL_NOTIFS_3, labelSize);
            case 37: return formatLabel(Rez.Strings.LABEL_SUN_1, Rez.Strings.LABEL_SUNINT_2, Rez.Strings.LABEL_SUNINT_3, labelSize);
            case 38: return formatLabel(Rez.Strings.LABEL_TEMP_1, Rez.Strings.LABEL_TEMP_1, Rez.Strings.LABEL_STEMP_3, labelSize);
            case 39: return formatLabel(Rez.Strings.LABEL_DAWN_1, Rez.Strings.LABEL_DAWN_2, Rez.Strings.LABEL_DAWN_2, labelSize);
            case 40: return formatLabel(Rez.Strings.LABEL_DUSK_1, Rez.Strings.LABEL_DUSK_2, Rez.Strings.LABEL_DUSK_2, labelSize);
            case 42: return formatLabel(Rez.Strings.LABEL_ALARM_1, Rez.Strings.LABEL_ALARM_2, Rez.Strings.LABEL_ALARM_2, labelSize);
            case 43: return formatLabel(Rez.Strings.LABEL_HIGH_1, Rez.Strings.LABEL_HIGH_2, Rez.Strings.LABEL_HIGH_2, labelSize);
            case 44: return formatLabel(Rez.Strings.LABEL_LOW_1, Rez.Strings.LABEL_LOW_2, Rez.Strings.LABEL_LOW_2, labelSize);
            case 53: return formatLabel(Rez.Strings.LABEL_TEMP_1, Rez.Strings.LABEL_TEMP_1, Rez.Strings.LABEL_TEMP_3, labelSize);
            case 54: return formatLabel(Rez.Strings.LABEL_PRECIP_1, Rez.Strings.LABEL_PRECIP_1, Rez.Strings.LABEL_PRECIP_3, labelSize);
            case 55: return formatLabel(Rez.Strings.LABEL_NEXTSUN_1, Rez.Strings.LABEL_NEXTSUN_2, Rez.Strings.LABEL_NEXTSUN_3, labelSize);
            case 57: return formatLabel(Rez.Strings.LABEL_NEXTCAL_1, Rez.Strings.LABEL_NEXTCAL_2, Rez.Strings.LABEL_NEXTCAL_3, labelSize);
            case 59: return formatLabel(Rez.Strings.LABEL_OX_1, Rez.Strings.LABEL_OX_2, Rez.Strings.LABEL_OX_2, labelSize);
            case 62: return formatLabel(Rez.Strings.LABEL_ACC_1, Rez.Strings.LABEL_ACC_2, Rez.Strings.LABEL_ACC_3, labelSize);
            case 64: return formatLabel(Rez.Strings.LABEL_UV_1, Rez.Strings.LABEL_UV_2, Rez.Strings.LABEL_UV_2, labelSize);
            case 66: return formatLabel(Rez.Strings.LABEL_HUM_1, Rez.Strings.LABEL_HUM_2, Rez.Strings.LABEL_HUM_2, labelSize);
            case 71: return WatchUi.loadResource(Rez.Strings.LABEL_CGM) as String;
            case 72: return WatchUi.loadResource(Rez.Strings.LABEL_CGMAGE) as String;
            case 74: return formatLabel(Rez.Strings.LABEL_FL, Rez.Strings.LABEL_FL, Rez.Strings.LABEL_FL_3, labelSize);
            case 75: return formatLabel(Rez.Strings.LABEL_HRS_NEXT_SUN_EVENT_1, Rez.Strings.LABEL_HRS_NEXT_SUN_EVENT_1, Rez.Strings.LABEL_HRS_NEXT_SUN_EVENT_3, labelSize);
            case 76: return formatLabel(Rez.Strings.LABEL_RHR_1, Rez.Strings.LABEL_RHR_2, Rez.Strings.LABEL_RHR_3, labelSize);
        }

        return "";
    }

    hidden function formatLabel(short as ResourceId, mid as ResourceId, long as ResourceId, size as Number) as String {
        if(size == 1) { return Application.loadResource(short) + ":"; }
        if(size == 2) { return Application.loadResource(mid) + ":"; }
        return Application.loadResource(long) + ":";
    }

    hidden function formatDate(today as Gregorian.Info) as String {
        var propDateFormat = (propBitmapB >> 7) & 0xF;
        var value = "";

        switch(propDateFormat) {
            case 0: // Default: THU, 14 MAR 2024
                value = dayName(today.day_of_week) + ", " + today.day + " " + monthName(today.month) + " " + today.year;
                break;
            case 1: // ISO: 2024-03-14
                value = today.year + "-" + today.month.format("%02d") + "-" + today.day.format("%02d");
                break;
            case 2: // US: 03/14/2024
                value = today.month.format("%02d") + "/" + today.day.format("%02d") + "/" + today.year;
                break;
            case 3: // EU: 14.03.2024
                value = today.day.format("%02d") + "." + today.month.format("%02d") + "." + today.year;
                break;
            case 4: // THU, 14 MAR (Week number)
                value = dayName(today.day_of_week) + ", " + today.day + " " + monthName(today.month) + " (W" + isoWeekNumber(today.year, today.month, today.day) + ")";
                break;
            case 5: // THU, 14 MAR 2024 (Week number)
                value = dayName(today.day_of_week) + ", " + today.day + " " + monthName(today.month) + " " + today.year + " (W" + isoWeekNumber(today.year, today.month, today.day) + ")";
                break;
            case 6: // WEEKDAY, DD MONTH
                value = dayName(today.day_of_week) + ", " + today.day + " " + monthName(today.month);
                break;
            case 7: // WEEKDAY, YYYY-MM-DD
                value = dayName(today.day_of_week) + ", " + today.year + "-" + today.month.format("%02d") + "-" + today.day.format("%02d");
                break;
            case 8: // WEEKDAY, MM/DD/YYYY
                value = dayName(today.day_of_week) + ", " + today.month.format("%02d") + "/" + today.day.format("%02d") + "/" + today.year;
                break;
            case 9: // WEEKDAY, DD.MM.YYYY
                value = dayName(today.day_of_week) + ", " + today.day.format("%02d") + "." + today.month.format("%02d") + "." + today.year;
                break;
        }

        return value;
    }

    hidden function join(array as Array<String>) as String {
        var ret = "";
        for(var i=0; i<array.size(); i++) {
            if(array[i].length() == 0) {
                continue;
            }
            if(ret.length() == 0) {
                ret = array[i];
            } else {
                ret = ret + "  " + array[i];
            }
        }
        return ret;
    }

    hidden function getDateTimeGroup() as String {
        // 052125ZMAR25
        // DDHHMMZmmmYY
        var now = Time.now();
        var utc = Time.Gregorian.utcInfo(now, Time.FORMAT_SHORT);
        var value = utc.day.format("%02d") + utc.hour.format("%02d") + utc.min.format("%02d") + "Z" + monthName(utc.month) + utc.year.toString().substring(2,4);

        return value;
    }

    hidden function formatPressure(pressureHpa as Float, width as Number) as String {
        var propPressureUnit = (propBitmapB >> 4) & 0x3;
        var val = "";
        var nf = "%d";

        if (propPressureUnit == 0) { // hPA
            val = pressureHpa.format(nf);
        } else if (propPressureUnit == 1) { // mmHG
            val = (pressureHpa * 0.750062).format(nf);
        } else if (propPressureUnit == 2) { // inHG
            if(width == 5) {
                val = (pressureHpa * 0.02953).format("%.2f");
            } else {
                val = (pressureHpa * 0.02953).format("%.1f");
            }
        }

        return val;
    }

    hidden function moonPhase(time) as String {
        var jd = julianDay(time.year, time.month, time.day);

        var days_since_new_moon = jd - 2459966;
        var lunar_cycle = 29.53;
        var phase = ((days_since_new_moon / lunar_cycle) * 100).toNumber() % 100;
        var into_cycle = (phase / 100.0) * lunar_cycle;

        if(time.month == 5 and time.day == 4) {
            return "8"; // That's no moon!
        }

        var moonPhase;
        if (into_cycle < 3) { // 2+1
            moonPhase = 0;
        } else if (into_cycle < 6) { // 4
            moonPhase = 1;
        } else if (into_cycle < 10) { // 4
            moonPhase = 2;
        } else if (into_cycle < 14) { // 4
            moonPhase = 3;
        } else if (into_cycle < 18) { // 4
            moonPhase = 4;
        } else if (into_cycle < 22) { // 4
            moonPhase = 5;
        } else if (into_cycle < 26) { // 4
            moonPhase = 6;
        } else if (into_cycle < 29) { // 3
            moonPhase = 7;
        } else {
            moonPhase = 0;
        }

        var propHemisphere = (propBitmapA >> 23) & 0x1;

        // If hemisphere is 1 (southern), invert the phase index
        if (propHemisphere == 1) {
            moonPhase = (8 - moonPhase) % 8;
        }

        return moonPhase.toString();

    }

    hidden function formatDistanceByWidth(distance as Float, width as Number) as String {
        if (width == 3) {
            return distance < 9.9 ? distance.format("%.1f") : Math.round(distance).format("%d");
        } else if (width == 4) {
            return distance < 100 ? distance.format("%.1f") : distance.format("%d");
        } else {  // width == 5
            return distance < 1000 ? distance.format("%05.1f") : distance.format("%05d");
        }
    }

    hidden function getWeatherPhase(hasWorse as Boolean) as Number {
        var elapsed = Time.now().value() - wakeTimestamp;
        var phaseCount = hasWorse ? 3 : 2;
        return ((elapsed / 4).toNumber() % phaseCount);
    }

    hidden function getWeatherTier(condition as Number) as Number {
        if (condition == 0 || condition == 1 || condition == 22 || condition == 23 || condition == 40 || condition == 52) { return 0; }
        if (condition == 2 || condition == 5 || condition == 8 || condition == 9 || condition == 11 || condition == 20 || condition == 27 || condition == 29 || condition == 30 || condition == 33 || condition == 35 || condition == 39 || condition == 43 || condition == 44 || condition == 45 || condition == 46 || condition == 47) { return 1; }
        if (condition == 3 || condition == 4 || condition == 7 || condition == 13 || condition == 14 || condition == 15 || condition == 16 || condition == 17 || condition == 18 || condition == 19 || condition == 21 || condition == 24 || condition == 25 || condition == 26 || condition == 31 || condition == 48 || condition == 50 || condition == 51) { return 2; }
        if (condition == 6 || condition == 10 || condition == 12 || condition == 28 || condition == 32 || condition == 34 || condition == 36) { return 3; }
        if (condition == 37 || condition == 38 || condition == 41 || condition == 42 || condition == 49) { return 4; }
        return 1;
    }

    hidden function getForecastEventHour(forecast as ForecastWeather or Null) as Number {
        if (forecast == null || forecast.forecastHour == null) { return -1; }
        return forecast.forecastHour;
    }

    hidden function buildForecastEvent(forecast as ForecastWeather or Null) as Array? {
        if (forecast == null) { return null; }
        return [buildMergedForecastWeather(forecast), getForecastEventHour(forecast), -1];
    }

    hidden function findHourlyForecastIndex(secondsAhead as Number) as Number {
        if (cachedHourlyForecast.size() == 0) { return -1; }

        var now = Time.now().value();
        var target = now + secondsAhead;
        var beforeIdx = -1;
        var afterIdx = -1;

        for (var i = 0; i < cachedHourlyForecast.size(); i++) {
            var forecastTime = cachedHourlyForecast[i].forecastTime;
            if (forecastTime == null || forecastTime <= now) { continue; }

            if (forecastTime < target) {
                beforeIdx = i;
                continue;
            }

            afterIdx = i;
            break;
        }

        if (afterIdx < 0) { return beforeIdx; }
        if (beforeIdx < 0) { return afterIdx; }

        var beforeDiff = target - (cachedHourlyForecast[beforeIdx].forecastTime as Number);
        var afterDiff = (cachedHourlyForecast[afterIdx].forecastTime as Number) - target;
        return (afterDiff <= beforeDiff) ? afterIdx : beforeIdx;
    }

    hidden function buildForecastTimeline(baseCondition as Number, startIdx as Number) as Array {
        var change = null;
        var worse = null;
        var changeIdx = -1;
        var worseIdx = -1;
        var baseTier = getWeatherTier(baseCondition);
        var changeTier = -1;
        var worseTier = -1;

        for (var i = startIdx + 1; i < cachedHourlyForecast.size(); i++) {
            var forecast = cachedHourlyForecast[i];
            if (forecast.condition == null) { continue; }

            var tier = getWeatherTier(forecast.condition);
            if (tier != baseTier) {
                change = buildForecastEvent(forecast);
                changeIdx = i;
                changeTier = tier;
                break;
            }
        }

        if (change == null) {
            return [null, null];
        }

        for (var i = changeIdx + 1; i < cachedHourlyForecast.size(); i++) {
            var forecast = cachedHourlyForecast[i];
            if (forecast.condition == null) { continue; }

            var tier = getWeatherTier(forecast.condition);
            if ((change[2] as Number) < 0 && tier != changeTier) {
                change[2] = getForecastEventHour(forecast);
            }
            if (worse == null && tier > changeTier) {
                worse = buildForecastEvent(forecast);
                worseIdx = i;
                worseTier = tier;
            }
            if (worse != null && (change[2] as Number) >= 0) {
                break;
            }
        }

        if (worse != null) {
            for (var i = worseIdx + 1; i < cachedHourlyForecast.size(); i++) {
                var forecast = cachedHourlyForecast[i];
                if (forecast.condition == null) { continue; }

                if (getWeatherTier(forecast.condition) != worseTier) {
                    worse[2] = getForecastEventHour(forecast);
                    break;
                }
            }
        }

        return [change, worse];
    }

    hidden function updateForecastChanges() as Void {
        cachedForecastChange = null;
        cachedForecastWorse = null;
        cachedLineForecastChange = null;
        cachedLineForecastWorse = null;
        lineWeatherCondition = null;

        if (cachedHourlyForecast.size() == 0) { return; }

        var lineForecastIdx = findHourlyForecastIndex(3600);
        if (lineForecastIdx >= 0) {
            lineWeatherCondition = buildMergedForecastWeather(cachedHourlyForecast[lineForecastIdx]);
            if (cachedHourlyForecast[lineForecastIdx].condition != null) {
                var lineTimeline = buildForecastTimeline(cachedHourlyForecast[lineForecastIdx].condition as Number, lineForecastIdx);
                cachedLineForecastChange = lineTimeline[0];
                cachedLineForecastWorse = lineTimeline[1];
            }
        }

        if (weatherCondition == null || weatherCondition.condition == null) { return; }

        var timeline = buildForecastTimeline(weatherCondition.condition.toNumber(), -1);
        cachedForecastChange = timeline[0];
        cachedForecastWorse = timeline[1];
    }

    hidden function formatForecastPointer(hour as Number?) as String {
        if (hour == null || hour < 0) { return ""; }
        return "  c" + formatHour(hour) + "H";
    }

    hidden function getForecastEventWeather(event as Array?) as ForecastWeather or Null {
        if (event == null || event.size() == 0) { return null; }
        if (event[0] == null) { return null; }
        return event[0] as ForecastWeather;
    }

    hidden function getForecastEventPointer(event as Array?, pointerIndex as Number) as Number? {
        if (event == null || event.size() <= pointerIndex) { return null; }
        if (event[pointerIndex] == null) { return null; }
        return event[pointerIndex] as Number;
    }

    hidden function formatWeatherConditionForWeather(activeWeather as ForecastWeather or Null, includePrecipitation as Boolean) as String {
        if (activeWeather == null || activeWeather.condition == null) {
            return "";
        }

        var perp = "";
        if(includePrecipitation &&
            activeWeather has :precipitationChance &&
            activeWeather.precipitationChance != null &&
            activeWeather.precipitationChance instanceof Number &&
            activeWeather.precipitationChance > 0) {
            perp = " (" + activeWeather.precipitationChance.format("%02d") + "%)";
        }

        var idx = activeWeather.condition.toNumber();
        if (idx < 0 || idx >= cachedWeatherResIds.size()) { idx = 53; }

        return Application.loadResource(cachedWeatherResIds[idx]) + perp;
    }

    hidden function formatFeelsLikeForWeather(activeWeather as ForecastWeather or Null, includeLabel as Boolean) as String {
        if(activeWeather == null || activeWeather.feelsLikeTemperature == null) {
            return "";
        }

        var fltemp = convertTemperatureFloat(activeWeather.feelsLikeTemperature, cachedTempUnit);
        if(includeLabel) {
            return cachedLabelFl + formatTemperature(fltemp);
        }
        return formatTemperature(fltemp);
    }

    hidden function formatWeatherConditionFeelsLike(activeWeather as ForecastWeather or Null) as String {
        return join([
            formatWeatherConditionForWeather(activeWeather, false),
            formatFeelsLikeForWeather(activeWeather, false)
        ]);
    }

    hidden function formatWeatherCycleValue(activeWeather as ForecastWeather or Null, activeChange as Array?, activeWorse as Array?) as String {
        if (activeWeather == null || activeWeather.condition == null) {
            return "";
        }

        var phase = getWeatherPhase(activeWorse != null);
        if (phase == 0 || activeChange == null) {
            return formatWeatherConditionFeelsLike(activeWeather) + formatForecastPointer(getForecastEventPointer(activeChange, 1));
        }
        if (phase == 1 || activeWorse == null) {
            return formatWeatherConditionFeelsLike(getForecastEventWeather(activeChange)) + formatForecastPointer(getForecastEventPointer(activeChange, 2));
        }
        return formatWeatherConditionFeelsLike(getForecastEventWeather(activeWorse)) + formatForecastPointer(getForecastEventPointer(activeWorse, 2));
    }

    hidden function getWeatherCondition(includePrecipitation as Boolean) as String {
        return formatWeatherConditionForWeather(getActiveWeatherCondition(), includePrecipitation);
    }

    hidden function getTemperature() as String {
        var activeWeather = getActiveWeatherCondition();
        if(activeWeather != null and activeWeather.temperature != null) {
            var temp_val = activeWeather.temperature;
            return formatTemperature(convertTemperature(temp_val, cachedTempUnit));
        }
        return "";
    }

    hidden function getTempUnit() as String {
        var deviceSettings = getCachedDeviceSettings();
        var temp_unit_setting = (deviceSettings != null && deviceSettings has :temperatureUnits) ? deviceSettings.temperatureUnits : System.UNIT_METRIC;
        var propTempUnit = (propBitmapA >> 29) & 0x3;
        if((temp_unit_setting == System.UNIT_METRIC and (propTempUnit == 0 or propTempUnit == 3)) or propTempUnit == 1) {
            return "C";
        } else {
            return "F";
        }
    }

    hidden function formatTemperature(temp) as String {
        var propShowTempUnit = (propBitmapB & 0x1) == 1;
        var propTempUnit = (propBitmapA >> 29) & 0x3;
        if(propShowTempUnit) {
            if(propTempUnit == 3 or (propTempUnit == 0 and cachedTempUnit.equals("C"))) {
                return temp.format("%d") + "\u00B0";
            }
            return temp.format("%d") + cachedTempUnit;
        }
        return temp.format("%d");
    }

    hidden function convertTemperature(temp as Number, unit as String) as Number {
        if(unit.equals("C")) {
            return temp;
        } else {
            return ((temp * 9/5) + 32);
        }
    }

    hidden function convertTemperatureFloat(temp as Float, unit as String) as Float {
        if(unit.equals("C")) {
            return temp;
        } else {
            return ((temp * 9/5) + 32);
        }
    }

    hidden function getWind() as String {
        var windspeed = "";
        var bearing = "";
        var activeWeather = getActiveWeatherCondition();
        var propWindUnit = (propBitmapB >> 1) & 0x7;

        if(activeWeather != null and activeWeather.windSpeed != null) {
            var windspeed_mps = activeWeather.windSpeed;
            if(propWindUnit == 0) { // m/s
                windspeed = Math.round(windspeed_mps).format("%01d");
            } else if (propWindUnit == 1) { // km/h
                var windspeed_kmh = Math.round(windspeed_mps * 3.6);
                windspeed = windspeed_kmh.format("%01d");
            } else if (propWindUnit == 2) { // mph
                var windspeed_mph = Math.round(windspeed_mps * 2.237);
                windspeed = windspeed_mph.format("%01d");
            } else if (propWindUnit == 3) { // knots
                var windspeed_kt = Math.round(windspeed_mps * 1.944);
                windspeed = windspeed_kt.format("%01d");
            } else if(propWindUnit == 4) { // beufort
                if (windspeed_mps < 0.5f) {
                    windspeed = "0";  // Calm
                } else if (windspeed_mps < 1.5f) {
                    windspeed = "1";  // Light air
                } else if (windspeed_mps < 3.3f) {
                    windspeed = "2";  // Light breeze
                } else if (windspeed_mps < 5.5f) {
                    windspeed = "3";  // Gentle breeze
                } else if (windspeed_mps < 7.9f) {
                    windspeed = "4";  // Moderate breeze
                } else if (windspeed_mps < 10.7f) {
                    windspeed = "5";  // Fresh breeze
                } else if (windspeed_mps < 13.8f) {
                    windspeed = "6";  // Strong breeze
                } else if (windspeed_mps < 17.1f) {
                    windspeed = "7";  // Near gale
                } else if (windspeed_mps < 20.7f) {
                    windspeed = "8";  // Gale
                } else if (windspeed_mps < 24.4f) {
                    windspeed = "9";  // Strong gale
                } else if (windspeed_mps < 28.4f) {
                    windspeed = "10";  // Storm
                } else if (windspeed_mps < 32.6f) {
                    windspeed = "11";  // Violent storm
                } else {
                    windspeed = "12";  // Hurricane force
                }
            }
        }

        if(activeWeather != null and activeWeather.windBearing != null) {
            bearing = ((Math.round((activeWeather.windBearing.toFloat() + 180) / 45.0).toNumber() % 8) + 97).toChar().toString();
        }

        if (windspeed.equals("0")) {
            bearing = "\u2248"; // Calm / no meaningful direction
        }
        return bearing + windspeed;
    }

    hidden function getFeelsLike(include_label as Boolean) as String {
        return formatFeelsLikeForWeather(getActiveWeatherCondition(), include_label);
    }

    hidden function getHumidity() as String {
        var ret = "";
        var activeWeather = getActiveWeatherCondition();
        if(activeWeather != null and activeWeather.relativeHumidity != null) {
            ret = "\u25CF" + activeWeather.relativeHumidity.format("%d") + "%";
        }
        return ret;
    }

    hidden function getUVIndex() as String {
        var ret = "";
        var activeWeather = getActiveWeatherCondition();
        if(activeWeather != null and activeWeather has :uvIndex and activeWeather.uvIndex != null) {
            ret = "\u2600" + activeWeather.uvIndex.format("%d");
        }
        return ret;
    }

    hidden function getHighLow() as String {
        var ret = "";
        var activeWeather = getActiveWeatherCondition();
        if(activeWeather != null) {
            if(activeWeather.highTemperature != null or activeWeather.lowTemperature != null) {
                var high = (activeWeather.highTemperature != null) ? formatTemperature(convertTemperature(activeWeather.highTemperature, cachedTempUnit)) : "";
                var low = (activeWeather.lowTemperature != null) ? formatTemperature(convertTemperature(activeWeather.lowTemperature, cachedTempUnit)) : "";
                if (high.length() > 0 && low.length() > 0) {
                    ret = high + "/" + low;
                } else {
                    ret = high + low;
                }
            }
        }
        return ret;
    }

    hidden function getPrecip() as String {
        var ret = "";
        var activeWeather = getActiveWeatherCondition();
        if(activeWeather != null and activeWeather.precipitationChance != null) {
            ret = "\u26C6" + activeWeather.precipitationChance.format("%d") + "%";
        }
        return ret;
    }

    hidden function hoursToNextSunEvent() as String {
        var nextSunEventArray = getNextSunEvent();
        if(nextSunEventArray != null && nextSunEventArray.size() == 2) {
            var nextSunEvent = nextSunEventArray[0] as Time.Moment;
            var now = Time.now();
            // Converting seconds to hours
            var diff = (nextSunEvent.subtract(now)).value();
            if(diff >= 36000) { // No decimals if 10+ hours
                return (diff / 3600.0).format("%d");
            }
            return (diff / 3600.0).format("%.1f");
        }
        return "";
    }

    hidden function getNextSunEvent() as Array {
        if(refreshCache has :nextSunEventLoaded) {
            return (refreshCache as Dictionary).get(:nextSunEvent) as Array;
        }

        var result = [];
        var now = Time.now();
        var todaySunEvents = getCachedSunEvents(now, "today");
        if (todaySunEvents != null && todaySunEvents.size() == 2) {
            var sunrise = todaySunEvents[0] as Time.Moment;
            var sunset = todaySunEvents[1] as Time.Moment;
            if (sunrise.lessThan(now)) {
                var tomorrowSunEvents = getCachedSunEvents(Time.today().add(new Time.Duration(86401)), "tomorrow");
                if (tomorrowSunEvents != null && tomorrowSunEvents.size() == 2) {
                    sunrise = tomorrowSunEvents[0] as Time.Moment;
                }
            }
            if (sunset.lessThan(now)) {
                var tomorrowSunEvents = getCachedSunEvents(Time.today().add(new Time.Duration(86401)), "tomorrow");
                if (tomorrowSunEvents != null && tomorrowSunEvents.size() == 2) {
                    sunset = tomorrowSunEvents[1] as Time.Moment;
                }
            }
            if (sunrise != null && sunset != null) {
                result = sunrise.lessThan(sunset) ? [sunrise, true] : [sunset, false];
            }
        }

        refreshCache[:nextSunEventLoaded] = true;
        refreshCache[:nextSunEvent] = result;
        return result;
    }

    hidden function getRestCalories() as Number {
        if(refreshCache has :restCaloriesLoaded) {
            return (refreshCache as Dictionary).get(:restCalories) as Number;
        }

        var today = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var profile = getCachedUserProfile();
        var restCalories = -1;

        if (profile has :weight && profile has :height && profile has :birthYear) {
            var age = today.year - profile.birthYear;
            var weight = profile.weight / 1000.0;
            restCalories = 0;

            if (profile has :gender && profile.gender == UserProfile.GENDER_MALE) {
                restCalories = 5.2 - 6.116 * age + 7.628 * profile.height + 12.2 * weight;
            } else {
                restCalories = -197.6 - 6.116 * age + 7.628 * profile.height + 12.2 * weight;
            }

            // Calculate rest calories for the current time of day
            restCalories = Math.round((today.hour * 60 + today.min) * restCalories / 1440).toNumber();
        }

        refreshCache[:restCaloriesLoaded] = true;
        refreshCache[:restCalories] = restCalories;
        return restCalories;
    }

    hidden function getWeeklyDistance(activityInfo) as Number {
        if(refreshCache has :weeklyDistanceLoaded) {
            return (refreshCache as Dictionary).get(:weeklyDistance) as Number;
        }

        var weekly_distance = 0;
        if(activityInfo != null && activityInfo has :distance) {
            var history = ActivityMonitor.getHistory();
            if (history != null) {
                // Only take up to 6 previous days from history
                var daysToCount = history.size() < 6 ? history.size() : 6;
                for (var i = 0; i < daysToCount; i++) {
                    if (history[i].distance != null) {
                        weekly_distance += history[i].distance;
                    }
                }
            }
            // Add today's distance
            if(activityInfo.distance != null) {
                weekly_distance += activityInfo.distance;
            }
        }

        refreshCache[:weeklyDistanceLoaded] = true;
        refreshCache[:weeklyDistance] = weekly_distance;
        return weekly_distance;
    }

    hidden function getWeeklyDistanceFromComplication(isRun as Boolean, conversionFactor as Float, width as Number) as String {
        var val = "";
        if (hasComplications) {
            try {
                var compType = isRun ? Complications.COMPLICATION_TYPE_WEEKLY_RUN_DISTANCE : Complications.COMPLICATION_TYPE_WEEKLY_BIKE_DISTANCE;
                var complication = Complications.getComplication(new Id(compType));
                if (complication != null && complication.value != null) {
                    var distance = complication.value * conversionFactor;
                    val = formatDistanceByWidth(distance, width);
                }
            } catch(e) {
                // Complication not found or type not supported on this device
            }
        }
        return val;
    }

    // CGM Connect Widget helper functions
    hidden function getCgmComplicationByLabel(targetLabel as String) as Complications.Id? {
        if (!hasComplications) { return null; }
        try {
            var iter = Complications.getComplications();
            var comp = iter.next();
            while (comp != null) {
                var compType = comp.getType();
                var compLabel = comp.shortLabel;
                if (compType == Complications.COMPLICATION_TYPE_INVALID && compLabel != null) {
                    if (compLabel.equals(targetLabel)) {
                        Complications.subscribeToUpdates(comp.complicationId);
                        return comp.complicationId;
                    }
                }
                comp = iter.next();
            }
        } catch (e) {}
        return null;
    }

    hidden function convertCgmTrendToArrow(trend as String) as String {
        if (trend.equals("R")) { return "a"; }  // Rapidly rising ↑
        if (trend.equals("r")) { return "b"; }  // Rising ↗
        if (trend.equals("n")) { return "c"; }  // Neutral →
        if (trend.equals("d")) { return "d"; }  // Falling ↘
        if (trend.equals("D")) { return "e"; }  // Rapidly falling ↓
        return "";
    }

    hidden function getCgmReading() as String {
        if (!hasComplications) { return ""; }
        try {
            if (cgmComplicationId == null) {
                cgmComplicationId = getCgmComplicationByLabel("CGM");
            }
            if (cgmComplicationId == null) { return ""; }

            var comp = Complications.getComplication(cgmComplicationId);
            if (comp == null || comp.value == null) { return ""; }

            var valueStr = comp.value.toString();
            if (valueStr.equals("---")) { return "---"; }

            var spaceIndex = valueStr.find(" ");
            if (spaceIndex == null) { return valueStr; }

            var reading = valueStr.substring(0, spaceIndex);
            var trend = valueStr.substring(spaceIndex + 1, valueStr.length());
            var arrow = convertCgmTrendToArrow(trend);
            return reading + arrow;
        } catch (e) {}
        return "";
    }

    hidden function getCgmAge() as String {
        if (!hasComplications) { return ""; }
        try {
            if (cgmAgeComplicationId == null) {
                cgmAgeComplicationId = getCgmComplicationByLabel("CGM Age");
            }
            if (cgmAgeComplicationId == null) { return ""; }
            var comp = Complications.getComplication(cgmAgeComplicationId);
            if (comp == null || comp.value == null) { return ""; }
            var timestamp = comp.value.toString().toLong();
            if (timestamp == null || timestamp < 0) { return "---"; }
            var ageMin = (Time.now().value() - timestamp) / 60;
            if (ageMin < 0) { return "---"; }
            return ageMin.format("%d");
        } catch (e) {}
        return "";
    }


    hidden function dayName(day_of_week as Number) as String {
        if(weekNames == null) { init_week_month_names(); }
        return weekNames[day_of_week - 1];
    }

    hidden function monthName(month as Number) as String {
        if(monthNames == null) { init_week_month_names(); }
        return monthNames[month - 1];
    }

    hidden function init_week_month_names() as Void {
        weekNames = [Application.loadResource(Rez.Strings.DAY_OF_WEEK_SUN), Application.loadResource(Rez.Strings.DAY_OF_WEEK_MON),
                     Application.loadResource(Rez.Strings.DAY_OF_WEEK_TUE), Application.loadResource(Rez.Strings.DAY_OF_WEEK_WED),
                     Application.loadResource(Rez.Strings.DAY_OF_WEEK_THU), Application.loadResource(Rez.Strings.DAY_OF_WEEK_FRI),
                     Application.loadResource(Rez.Strings.DAY_OF_WEEK_SAT)];
        monthNames = [Application.loadResource(Rez.Strings.MONTH_JAN), Application.loadResource(Rez.Strings.MONTH_FEB), Application.loadResource(Rez.Strings.MONTH_MAR),
                      Application.loadResource(Rez.Strings.MONTH_APR), Application.loadResource(Rez.Strings.MONTH_MAY), Application.loadResource(Rez.Strings.MONTH_JUN),
                      Application.loadResource(Rez.Strings.MONTH_JUL), Application.loadResource(Rez.Strings.MONTH_AUG), Application.loadResource(Rez.Strings.MONTH_SEP),
                      Application.loadResource(Rez.Strings.MONTH_OCT), Application.loadResource(Rez.Strings.MONTH_NOV), Application.loadResource(Rez.Strings.MONTH_DEC)];
    }

    hidden function isoWeekNumber(year as Number, month as Number, day as Number) as Number {
        var first_day_of_year = julianDay(year, 1, 1);
        var given_day_of_year = julianDay(year, month, day);
        var day_of_week = (first_day_of_year + 3) % 7;
        var week_of_year = (given_day_of_year - first_day_of_year + day_of_week + 4) / 7;
        var ret = 0;
        if (week_of_year == 53) {
            if (day_of_week == 6) {
                ret = week_of_year;
            } else if (day_of_week == 5 && isLeapYear(year)) {
                ret = week_of_year;
            } else {
                ret = 1;
            }
        } else if (week_of_year == 0) {
            first_day_of_year = julianDay(year - 1, 1, 1);
            day_of_week = (first_day_of_year + 3) % 7;
            ret = (given_day_of_year - first_day_of_year + day_of_week + 4) / 7;
        } else {
            ret = week_of_year;
        }
        if(propWeekOffset != 0) {
            ret = ret + propWeekOffset;
        }
        return ret;
    }

    hidden function julianDay(year as Number, month as Number, day as Number) as Number {
        var a = (14 - month) / 12;
        var y = (year + 4800 - a);
        var m = (month + 12 * a - 3);
        return day + ((153 * m + 2) / 5) + (365 * y) + (y / 4) - (y / 100) + (y / 400) - 32045;
    }

    hidden function isLeapYear(year as Number) as Boolean {
        if (year % 4 != 0) {
            return false;
           } else if (year % 100 != 0) {
            return true;
        } else if (year % 400 == 0) {
            return true;
        }
        return false;
    }

    // Square helper functions - only compiled for square devices
    (:Square)
    hidden function loadBottomField2Property() as Void {
        propBottomField2Shows = getValueOrDefault("bottomField2Shows", -2) as Number;
    }

    (:Square)
    hidden function getBottomField2Shows() as Number {
        return propBottomField2Shows;
    }

    (:Square)
    hidden function computeBottomField2Values(values as Dictionary, now as Gregorian.Info, activityInfo, sysStats as System.Stats) as Void {
        values[:dataBottom2] = getValueByType(propBottomField2Shows, 5, now, activityInfo, sysStats);
        if (propBottomFieldShows != -2 and propBottomField2Shows != -2) {
            values[:dataLabelBottom] = getLabelByType(propBottomFieldShows, 2);
            values[:dataLabelBottom2] = getLabelByType(propBottomField2Shows, 2);
        }
    }

    (:Square)
    hidden function calculateSquareLayout() as Void {
        var propLabelVisibility = (propBitmapB >> 11) & 0x3;
        dualBottomFieldActive = (propBottomFieldShows != -2 and propBottomField2Shows != -2);
        bottomFiveYOriginal = bottomFiveY;

        if (dualBottomFieldActive) {
            // Position two 5-digit fields with 40px gap between them, centered
            var fieldWidth = bottomDataWidth * 5;
            var gap = 20;

            bottomFive1X = centerX - (gap / 2) - (fieldWidth / 2);
            bottomFive2X = centerX + (gap / 2) + (fieldWidth / 2);

            // Shift the entire row DOWN to make room for labels above (only if labels visible)
            if (propLabelVisibility == 0 or propLabelVisibility == 2) {
                bottomFiveY = bottomFiveY + labelHeight + labelMargin;
            }
        } else {
            // Single field mode - center position
            bottomFive1X = centerX;
            bottomFive2X = centerX;
        }
    }

    (:Square)
    hidden function drawSquares(dc as Dc, values as Dictionary) as Void {
        var propLabelVisibility = (propBitmapB >> 11) & 0x3;
        if (dualBottomFieldActive) {
            var field1Width = bottomDataWidth * 5;
            var field2Width = bottomDataWidth * 5;
            var field1Left = bottomFive1X - (field1Width / 2);
            var field2Left = bottomFive2X - (field2Width / 2);

            // Draw labels above fields using the same alignment rules as the standard fields.
            if (propLabelVisibility == 0 or propLabelVisibility == 2) {
                drawFieldLabel(dc, bottomFive1X, bottomFiveYOriginal, 0, values[:dataLabelBottom], field1Width);
                drawFieldLabel(dc, bottomFive2X, bottomFiveYOriginal, 0, values[:dataLabelBottom2], field2Width);
            }

            // Draw both fields
            drawDataField(dc, bottomFive1X, bottomFiveY, 0,
                null, values[:dataBottom], 5,
                fontBottomData, field1Width);

            drawDataField(dc, bottomFive2X, bottomFiveY, 0,
                null, values[:dataBottom2], 5,
                fontBottomData, field2Width);

            // Icons on outer edges
            dc.setColor(themeColors[dataVal], Graphics.COLOR_TRANSPARENT);
            dc.drawText(field1Left - (marginX / 2),
                bottomFiveY + (largeDataHeight / 2) + iconYAdj,
                fontIcons, values[:dataIcon1],
                Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(field2Left + field2Width + (marginX / 2) - 2,
                bottomFiveY + (largeDataHeight / 2) + iconYAdj,
                fontIcons, values[:dataIcon2],
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            // Single field - original behavior
            var step_width = drawDataField(dc, centerX, bottomFiveY, 0, null,
                values[:dataBottom], 5, fontBottomData, bottomDataWidth * 5);

            dc.setColor(themeColors[dataVal], Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX - (step_width / 2) - (marginX / 2),
                bottomFiveY + (largeDataHeight / 2) + iconYAdj,
                fontIcons, values[:dataIcon1],
                Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(centerX + (step_width / 2) + (marginX / 2) - 2,
                bottomFiveY + (largeDataHeight / 2) + iconYAdj,
                fontIcons, values[:dataIcon2],
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // Non-Square stubs for other devices
    (:Round)
    hidden function calculateSquareLayout() as Void {
        // No-op for non-square devices
    }

    (:Round)
    hidden function loadBottomField2Property() as Void {
        // No-op for non-square devices devices
    }

    (:Round)
    hidden function getBottomField2Shows() as Number {
        return -2; // Hidden by default for non-square devices devices
    }

    (:Round)
    hidden function computeBottomField2Values(values as Dictionary, now as Gregorian.Info, activityInfo, sysStats as System.Stats) as Void {
        // No-op for non-square devices devices
    }

    (:Square)
    hidden function drawBottomFieldsWithIcons(dc as Dc, values as Dictionary) as Void {
        drawSquares(dc, values);
    }

    (:Round)
    hidden function drawBottomFieldsWithIcons(dc as Dc, values as Dictionary) as Void {
        // Original single field behavior
        var step_width = 0;
        if(screenHeight == 240) {
            step_width = drawDataField(dc, centerX - 19, bottomFiveY + 3, 0, null, values[:dataBottom], 5, fontBottomData, bottomDataWidth * 5);
        } else {
            step_width = drawDataField(dc, centerX, bottomFiveY, 0, null, values[:dataBottom], 5, fontBottomData, bottomDataWidth * 5);
        }

        // Draw icons
        dc.setColor(themeColors[dataVal], Graphics.COLOR_TRANSPARENT);
        if(screenHeight == 240) { step_width += 30; }
        dc.drawText(centerX - (step_width / 2) - (marginX / 2), bottomFiveY + (largeDataHeight / 2) + iconYAdj, fontIcons, values[:dataIcon1], Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX + (step_width / 2) + (marginX / 2) - 2, bottomFiveY + (largeDataHeight / 2) + iconYAdj, fontIcons, values[:dataIcon2], Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

}

class Segment34Delegate extends WatchUi.WatchFaceDelegate {
    var screenW = null;
    var screenH = null;
    var view as Segment34View;

    public function initialize(v as Segment34View) {
        WatchFaceDelegate.initialize();
        screenW = System.getDeviceSettings().screenWidth;
        screenH = System.getDeviceSettings().screenHeight;
        view = v;
    }

    public function onPress(clickEvent as WatchUi.ClickEvent) {
        var coords = clickEvent.getCoordinates();
        var x = coords[0];
        var y = coords[1];

        if(y < screenH / 3) {
            handlePress("pressToOpenTop");
        } else if (y < (screenH / 3) * 2) {
            handlePress("pressToOpenMiddle");
        } else if (x < screenW / 3) {
            handlePress("pressToOpenBottomLeft");
        } else if (x < (screenW / 3) * 2) {
            handlePress("pressToOpenBottomCenter");
        } else {
            handlePress("pressToOpenBottomRight");
        }

        return true;
    }

    function handlePress(areaSetting as String) {
        var cID = Application.Properties.getValue(areaSetting) as Complications.Type;

        if(cID != null and cID > 0) {
            try {
                Complications.exitTo(new Id(cID));
            } catch (e) {}
        }
    }

}

class ForecastWeather {
    public var observationLocationPosition as Position.Location or Null;
    public var precipitationChance as Lang.Number or Null;
    public var temperature as Lang.Number or Null;
    public var windBearing as Lang.Number or Null;
    public var windSpeed as Lang.Float or Null;
    public var highTemperature as Lang.Number or Null;
    public var lowTemperature as Lang.Number or Null;
    public var feelsLikeTemperature as Lang.Float or Null;
    public var relativeHumidity as Lang.Number or Null;
    public var condition as Lang.Number or Null;
    public var uvIndex as Lang.Float or Null;
    public var forecastTime as Lang.Number or Null;
    public var forecastHour as Lang.Number or Null;
}

(:WeatherCache)
class StoredWeather {
    public var observationLocationPosition as Position.Location or Null;
    public var precipitationChance as Lang.Number or Null;
    public var temperature as Lang.Numeric or Null;
    public var windBearing as Lang.Number or Null;
    public var windSpeed as Lang.Float or Null;
    public var highTemperature as Lang.Numeric or Null;
    public var lowTemperature as Lang.Numeric or Null;
    public var feelsLikeTemperature as Lang.Float or Null;
    public var relativeHumidity as Lang.Number or Null;
    public var condition as Lang.Number or Null;
    public var uvIndex as Lang.Float or Null;
}
