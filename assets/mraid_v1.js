/* eslint-disable */
function getPlatform() {
    var ua = navigator.userAgent
    if (ua.indexOf('Android') > -1 || ua.indexOf('Adr') > -1) {
        return 'Android'
    } else if (ua.match(/\(i[^;]+;( U;)? CPU.+Mac OS X/)) {
        return 'iOS'
    } else {
        return 'web'
    }
}

var platform = getPlatform()
if (platform !== 'web') {
    // console = {};
    console.debug = console.log;
    console.info = console.log;
    console.warn = console.log;
    console.error = console.log;
    console.log = function(log) {
        MASTMRAIDWebView.nativeInvoke("console://localhost?" + log);
    };
}

window.mraid_init = function() {
    console.log("mraid_init");

    var mraid = window.mraid = {};

    // MAST SDK
    mraid.returnResult = function(call) {
        return call().toString();
    };

    // MAST SDK
    mraid.returnInfo = function(call) {
        var info = '';

        var result = call();
        for (property in result) {
            if (info) {
                info += '&';
            }

            info += encodeURIComponent(property) + '=' + encodeURIComponent(result[property]);
        }

        return info;
    };

    // MAST SDK
    mraid.nativeInvoke = function(call) {
        if (platform !== 'web') {
            MASTMRAIDWebView.nativeInvoke(call);
        }
    };
    // MAST SDK
    mraid.vpaidInvoke = function(call) {
        if (platform !== 'web') {
            MASTMRAIDWebView.vpaidInvoke(call);
        }
    };
    /////////
    //
    // events
    //

    var EVENTS = mraid.EVENTS = {
        READY: "ready",
        ERROR: "error",
        STATE_CHANGE: "stateChange",
        VIEWABLE_CHANGE: "viewableChange",
        SIZE_CHANGE: "sizeChange",
        EXPOSURE_CHANGE: "exposureChange",
        AUDIO_VOLUME_CHANGE: "audioVolumeChange"
    };

    var listeners = {};

    // MRAID
    mraid.addEventListener = function(event, listener) {
        console.log("addEventListener event:"+event);

        var handlers = listeners[event];

        // Create the listeners for the event if not already created
        if (!handlers) {
            listeners[event] = [];
            handlers = listeners[event];
        }

        // Don't add the same listener twice
        for (var i = 0; i < handlers.length; ++i) {
            if (listener === handlers[i]) {
                return;
            }
        }

        // Add the new listener
        handlers.push(listener);
    };

    // MRAID
    mraid.removeEventListener = function(event, listener) {
        console.log("removeEventListener event:"+event);

        var handlers = listeners[event];
        if (handlers) {
            if (listener) {
                var index = handlers.indexOf(listener);
                if (index !== -1) {
                    handlers.splice(index, 1); // Use splice to remove the element from the array
                }
            } else {
                listeners[event] = null;
            }
        }
    };

    // MAST SDK
    mraid.fireChangeEvent = function(event, newValue) {
        console.log("fireChangeEvent handler:" + event + " with:" + newValue);

        var handlers = listeners[event];
        if (handlers) {
            for (var i = 0; i < handlers.length; ++i) {
                console.log("fireChangeEvent invoked handler");

                handlers[i](newValue);
            }
        }
    };

    // MAST SDK
    mraid.fireErrorEvent = function(message, action) {
        console.log("fireErrorEvent handler:" + message + " action:" + action);

        var handlers = listeners[EVENTS.ERROR];
        if (handlers) {
            for (var i = 0; i < handlers.length; ++i) {
                handlers[i](message, action);
            }
        }
    };

    // MAST SDK
    mraid.fireEvent = function(event) {
        console.log("fireEvent handler:" + event);

        var handlers = listeners[event];
        if (handlers) {
            for (var i = 0; i < handlers.length; ++i) {
                handlers[i]();
            }
        }
    };



    /////////
    //
    // version
    //

    // MRAID
    mraid.getVersion = function() {
        console.log("getVersion");

        return ("3.0");
    };


    //////////
    //
    // supports
    //

    var FEATURES = mraid.FEATURES = {
        SMS: "sms",
        TEL: "tel",
        CALENDAR: "calendar",
        STORE_PICTURE: "storePicture",
        INLINE_VIDEO: "inlineVideo",
        VPAID: "vpaid"
    };

    var supportedFeatures = {};

    // MAST SDK
    mraid.setSupports = function(feature, supported) {
        supportedFeatures[feature] = supported;
    };

    // MRAID
    mraid.supports = function(feature) {
        console.log("supports");

        return supportedFeatures[feature];
    };


    /////////
    //
    // state
    //

    var STATES = mraid.STATES = {
        LOADING: "loading",
        DEFAULT: "default",
        EXPANDED: "expanded",
        RESIZED: "resized",
        HIDDEN: "hidden"
    };

    var state = STATES.LOADING;

    // MAST SDK
    mraid.setState = function(newState) {
        var diff = state != newState;

        state = newState;

        if (diff) {
            mraid.fireChangeEvent(EVENTS.STATE_CHANGE, state);
        } else if (state === STATES.RESIZED) {
            // spec says resized -> resized fires an event
            mraid.fireChangeEvent(EVENTS.STATE_CHANGE, state);
        }
    };

    // MRAID
    mraid.getState = function() {
        console.log("getState");

        return state;
    };


    /////////
    //
    // placementType
    //

    var PLACEMENT_TYPES = mraid.PLACEMENT_TYPES = {
        INLINE: "inline",
        INTERSTITIAL: "interstitial"
    };

    var placementType = PLACEMENT_TYPES.INLINE;

    // MAST SDK
    mraid.setPlacementType = function(newPlacementType) {
        placementType = newPlacementType;
    };

    // MRAID
    mraid.getPlacementType = function() {
        console.log("getPlacementType");

        return placementType;
    };


    //////////
    //
    // isViewable
    //

    var isViewable = false;

    // MAST SDK
    mraid.setViewable = function(viewable) {
        var diff = isViewable != viewable;

        isViewable = viewable;

        if (diff) {
            mraid.fireChangeEvent(EVENTS.VIEWABLE_CHANGE, isViewable);
        }
    };

    // MRAID
    mraid.isViewable = function() {
        console.log("isViewable");

        return isViewable;
    };


    //////////
    //
    // open
    //

    // MRAID
    mraid.open = function(url, params) {
        var invoke = "mraid://open?url=" + encodeURIComponent(url)
        if (params) {
            invoke = invoke + encodeURIComponent(params)
        }

        mraid.nativeInvoke(invoke)
    };


    //////////
    //
    // close
    //

    // MRAID
    mraid.close = function() {
        console.log("close");

        var invoke = "mraid://close";
        mraid.nativeInvoke(invoke);
    };


    //////////
    //
    // video
    //

    // MRAID
    mraid.playVideo = function(url) {
        console.log("playVideo");

        var invoke = "mraid://playVideo?url=" + encodeURIComponent(url);
        mraid.nativeInvoke(invoke);
    };


    //////////
    //
    // expand
    //

    var expandProperties = {
        width: 0,
        height: 0,
        useCustomClose: false,
        isModal: true
    };

    // MRAID
    mraid.setExpandProperties = function(properties) {
        console.log("setExpandProperties");

        var writableFields = ["width", "height", "useCustomClose"];

        for (wf in writableFields) {
            var field = writableFields[wf];
            if (properties !== undefined && properties[field] !== undefined) {
                expandProperties[field] = properties[field];
            }
        }

        var invoke = "mraid://setExpandProperties?" + mraid.returnInfo(mraid.getExpandProperties);
        mraid.nativeInvoke(invoke);
    };

    // MRAID
    mraid.getExpandProperties = function() {
        console.log("getExpandProperties");

        return expandProperties;
    };

    // MRAID
    mraid.useCustomClose = function(useCustomClose) {
        console.log("useCustomClose");

        var property = {
            useCustomClose: useCustomClose
        };

        mraid.setExpandProperties(property);
    };

    // MRAID
    mraid.expand = function(url, params) {
        console.log("expand");

        var invoke = "mraid://expand";

        if (url) {
            invoke += "?url=" + encodeURIComponent(url);
        }

        if (params) {
            invoke += encodeURIComponent(params);
        }
        mraid.nativeInvoke(invoke);
    };


    //////////
    //
    // resize
    //

    var RESIZE_PROPERTIES_CUSTOM_CLOSE_POSITION = mraid.RESIZE_PROPERTIES_CUSTOM_CLOSE_POSITION = {
        TOP_LEFT: "top-left",
        TOP_RIGHT: "top-right",
        CENTER: "center",
        BOTTOM_LEFT: "bottom-left",
        BOTTOM_RIGHT: "bottom-right"
    };

    var resizeProperties = {
        width: 0,
        height: 0,
        customClosePosition: RESIZE_PROPERTIES_CUSTOM_CLOSE_POSITION.TOP_RIGHT,
        offsetX: 0,
        offsetY: 0,
        allowOffscreen: false
    };

    // MRAID
    mraid.setResizeProperties = function(properties) {
        console.log("setResizeProperties");

        if (properties === undefined) { //1
            console.log("tjt Entering mraid.setResizeProperties");
            setTimeout("mraid.fireErrorEvent('Calling setResizeProperties with undefined size properties should trigger an error.', 'setResizeProperties')", 20);

            console.log("tjt Exiting mraid.setResizeProperties");
            return;
        }
        if (Object.keys(properties).length === 0) { //2
            setTimeout("mraid.fireErrorEvent('Calling setResizeProperties without actual size properties should trigger an error.', 'setResizeProperties')", 20);
            return;
        }

        var writableFields = ["width", "height", "customClosePosition", "offsetX", "offsetY", "allowOffscreen"];

        var requiredFields = ["width", "height", "offsetX", "offsetY"];
        var maxSize = mraid.getMaxSize();
        var requiredCount = 0;
        var invalidCount = 0;
        var sizeErrorCount = 0;
        var maxErrorCount = 0;
        var offsetX = 0;
        var offsetY = 0;
        var width = 0;
        var height = 0;
        for (wf in writableFields) {
            var field = writableFields[wf];
            if (properties !== undefined && properties[field] !== undefined) {
                var fieldValue = properties[field];
                if (requiredFields.indexOf(field) !== -1) {
                    if (isNaN(fieldValue) || typeof fieldValue !== 'number') {
                        invalidCount++;
                        continue;
                    }
                    if (field === 'width') {
                        requiredCount++;
                        width = fieldValue;
                        if (fieldValue < 50) {
                            sizeErrorCount++;
                            continue;
                        }
                        if (fieldValue > maxSize.width) {
                            maxErrorCount++;
                            continue;
                        }
                    }

                    if (field === 'height') {
                        requiredCount++;
                        height = fieldValue;
                        if (fieldValue < 50) {
                            sizeErrorCount++;
                            continue;
                        }
                        if (fieldValue > maxSize.height) {
                            maxErrorCount++;
                            continue;
                        }
                    }

                    if (field === 'offsetX') {
                        offsetX = fieldValue;
                    }

                    if (field === 'offsetY') {
                        offsetY = fieldValue;
                    }
                }
                if (requiredFields.indexOf('allowOffscreen') !== -1 &&
                    typeof fieldValue !== 'boolean') {
                    invalidCount++;
                    continue;
                }
                resizeProperties[field] = properties[field];
            }
        }

        if (requiredCount < 2) { //3
            setTimeout("mraid.fireErrorEvent('Calling setResizeProperties with incomplete list of required size properties should trigger an error.', 'setResizeProperties')", 20);
            return;
        }

        if (invalidCount > 0) { //4
            setTimeout("mraid.fireErrorEvent('Calling setResizeProperties with invalid size properties should trigger an error.', 'setResizeProperties')", 20);
            return;
        }

        if (sizeErrorCount > 0) { //5
            setTimeout("mraid.fireErrorEvent('Setting ad size less than 50x50 should trigger an error.', 'setResizeProperties')", 20);
            return;
        }

        if (maxErrorCount > 0) { //6
            setTimeout("mraid.fireErrorEvent('Setting size more than the ad max size should trigger an error.', 'setResizeProperties')", 20);
            return;
        }

        var sumWidth = width + offsetX;
        var spillX = sumWidth - maxSize.width;
        if (spillX >= 50) {
            setTimeout("mraid.fireErrorEvent('Setting offsetX that moves close button offscreen should trigger an error.', 'setResizeProperties')", 20);
            return;
        }

        var sumHeight = height - offsetY;

        var spillY = sumHeight - maxSize.height;
        if (spillY >= 50) {
            setTimeout("mraid.fireErrorEvent('Setting offsetY that moves close button offscreen should trigger an error.', 'setResizeProperties')", 20);
            return;
        }

        if (spillX + spillY >= 50) {
            setTimeout("mraid.fireErrorEvent('Setting offsetX and offsetY that moves close button partially offscreen should trigger an error.', 'setResizeProperties')", 20);
            return;
        }

        if (width - maxSize.width >= 50) {
            setTimeout("mraid.fireErrorEvent('Setting width that moves close button offscreen should trigger an error.', 'setResizeProperties')", 20);
            return;
        }

        var invoke = "mraid://setResizeProperties?" + mraid.returnInfo(mraid.getResizeProperties);
        mraid.nativeInvoke(invoke);
    };

    // MRAID
    mraid.getResizeProperties = function() {
        console.log("getResizeProperties");

        return resizeProperties;
    };

    // MRAID
    mraid.resize = function() {
        console.log("resize");

        var invoke = "mraid://resize";
        mraid.nativeInvoke(invoke);
    };


    //////////
    //
    // orientation
    //

    var ORIENTATION_PROPERTIES_FORCE_ORIENTATION = mraid.ORIENTATION_PROPERTIES_FORCE_ORIENTATION = {
        PORTRAIT: "portrait",
        LANDSCAPE: "landscape",
        NONE: "none"
    };

    var orientationProperties = {
        allowOrientationChange: true,
        forceOrientation: ORIENTATION_PROPERTIES_FORCE_ORIENTATION.NONE
    };

    // MRAID
    mraid.setOrientationProperties = function(properties) {
        console.log("setOrientationProperties");

        var writableFields = ["allowOrientationChange", "forceOrientation"];

        for (wf in writableFields) {
            var field = writableFields[wf];
            if (properties !== undefined && properties[field] !== undefined) {
                orientationProperties[field] = properties[field];
            }
        }

        var invoke = "mraid://setOrientationProperties?" + mraid.returnInfo(mraid.getOrientationProperties);
        mraid.nativeInvoke(invoke);
    };

    // MRAID
    mraid.getOrientationProperties = function() {
        console.log("getOrientationProperties");

        return orientationProperties;
    };


    //////////
    //
    // position and size
    //

    var currentPosition = {
        x: 0,
        y: 0,
        width: 0,
        height: 0
    };

    var maxSize = {
        width: 0,
        height: 0
    };

    var defaultPosition = {
        x: 0,
        y: 0,
        width: 0,
        height: 0
    };

    var screenSize = {
        width: 0,
        height: 0
    };

    mraid.setStateAndCurrentPosition = function(newState, position) {
        var diff = state != newState;

        state = newState;

        var previousSize = mraid.getSize();

        currentPosition = position;

        var currentSize = mraid.getSize();

        if (diff) {
            mraid.fireChangeEvent(EVENTS.STATE_CHANGE, state);
        } else if (state === STATES.RESIZED) {
            // spec says resized -> resized fires an event
            mraid.fireChangeEvent(EVENTS.STATE_CHANGE, state);
        }

        if ((previousSize.width != currentSize.width) || (previousSize.height != currentSize.height)) {
            var handlers = listeners[EVENTS.SIZE_CHANGE];
            if (handlers) {
                var width = currentPosition.width;
                var height = currentPosition.height;

                for (var i = 0; i < handlers.length; ++i) {
                    handlers[i](width, height);
                }
            }
        }
    };

    // MAST SDK
    mraid.setCurrentPosition = function(position) {
        var previousSize = mraid.getSize();

        currentPosition = position;

        var currentSize = mraid.getSize();

        // Only send the size changed event if the size in the position
        // was different from the previous position
        if ((previousSize.width === currentSize.width) && (previousSize.height === currentSize.height)) {
            return;
        }

        var handlers = listeners[EVENTS.SIZE_CHANGE];
        if (handlers) {
            var width = currentPosition.width;
            var height = currentPosition.height;

            for (var i = 0; i < handlers.length; ++i) {
                handlers[i](width, height);
            }
        }
    };

    // MRAID
    mraid.getCurrentPosition = function() {
        console.log("getCurrentPosition");

        var invoke = "mraid://updateCurrentPosition";
        mraid.nativeInvoke(invoke);

        return currentPosition;
    };

    // MRAID
    mraid.getSize = function() {
        console.log("getSize");

        var size = {
            width: currentPosition.width,
            height: currentPosition.height
        };

        return size;
    };

    // MAST SDK
    mraid.setMaxSize = function(size) {
        maxSize = size;
    };

    // MRAID
    mraid.getMaxSize = function() {
        console.log("getMaxSize");

        return maxSize;
    };

    // MAST SDK
    mraid.setDefaultPosition = function(position) {
        defaultPosition = position;
    };

    // MRAID
    mraid.getDefaultPosition = function() {
        console.log("getDefaultPosition");

        return defaultPosition;
    };

    // MAST SDK
    mraid.setScreenSize = function(size) {
        screenSize = size;
    };

    // MRAID
    mraid.getScreenSize = function() {
        console.log("getScreenSize");

        return screenSize;
    };


    //////////
    //
    // picture
    //

    // MRAID
    mraid.storePicture = function(url) {
        console.log("storePicture");

        var invoke = "mraid://storePicture?url=" + encodeURIComponent(url);
        mraid.nativeInvoke(invoke);
    };


    //////////
    //
    // calendar
    //

    // MRAID
    mraid.createCalendarEvent = function(parameters) {
        console.log("createCalendarEvent");

        var invoke = "mraid://createCalendarEvent?event=" + encodeURIComponent(JSON.stringify(parameters));
        mraid.nativeInvoke(invoke);
    };

    //////////
    //
    // VPAID
    //
    mraid._vpaidObjcet = {};

    mraid.startAd = function() {
        this._vpaidObjcet.startAd();
    };

    mraid.subscribe = function(eventName) {
        var mraidCallbacks = {
            'AdClickThru': this.onAdClickThru,
            'AdError': this.onAdError,
            'AdImpression': this.onAdImpression,
            'AdPaused': this.onAdPaused,
            'AdPlaying': this.onAdPlaying,
            'AdVideoStart': this.onAdVideoStart,
            'AdVideoFirstQuartile': this.onAdVideoFirstQuartile,
            'AdVideoMidpoint': this.onAdVideoMidpoint,
            'AdVideoThirdQuartile': this.onAdVideoThirdQuartile,
            'AdVideoComplete': this.onAdVideoComplete,
        };
        if (eventName in mraidCallbacks) {
            this._vpaidObjcet.subscribe(mraidCallbacks[eventName], eventName, this);
        }
    };

    mraid.unsubscribe = function(eventName) {
        if (eventName in mraidCallbacks) {
            this._vpaidObjcet.unsubscribe(mraidCallbacks[eventName], eventName, this);
        }
    };

    mraid.getAdDuration = function() {
        return this._vpaidObject.getAdDuration();
    };

    mraid.getAdRemainingTime = function() {
        return this._vpaidObject.getAdRemainingTime();
    };

    //mraid VPAID
    mraid.initVpaid = function(vpaidObject) {
        this._vpaidObjcet = vpaidObject;
        //通知sdk vpaid 初始化完成
        var invoke = "vpaid://initVpaid";
        mraid.vpaidInvoke(invoke);
    };


    mraid.onAdClickThru = function(url, id, playerHandles) {
        var adjustedUrl = url;
        if (adjustedUrl === undefined)
            adjustedUrl = "";
        var invoke = "vpaid://vpaidAdClickThruIdPlayerHandles?url=" + encodeURIComponent(adjustedUrl) +
            "&id=" + encodeURIComponent(id) + "&playerHandles=" + encodeURIComponent(playerHandles);
        mraid.vpaidInvoke(invoke);
        // CTMRAIDVpaidClient.vpaidAdClickThruIdPlayerHandles(adjustedUrl, id, playerHandles);
    };

    mraid.onAdError = function(message) {
        var invoke = "vpaid://vpaidAdError?message=" + encodeURIComponent(message);
        mraid.vpaidInvoke(invoke);
        // CTMRAIDVpaidClient.vpaidAdError(message);
    };

    mraid.onAdImpression = function() {
        var invoke = "vpaid://vpaidAdImpression";
        mraid.vpaidInvoke(invoke);
        // CTMRAIDVpaidClient.vpaidAdImpression();
    };

    mraid.onAdPaused = function() {
        var invoke = "vpaid://vpaidAdPaused";
        mraid.vpaidInvoke(invoke);
        // CTMRAIDVpaidClient.vpaidAdPaused();
    };

    mraid.onAdPlaying = function() {
        var invoke = "vpaid://vpaidAdPlaying";
        mraid.vpaidInvoke(invoke);
        // CTMRAIDVpaidClient.vpaidAdPlaying();
    };

    mraid.onAdVideoStart = function() {
        var invoke = "vpaid://vpaidAdVideoStart";
        mraid.vpaidInvoke(invoke);
        // CTMRAIDVpaidClient.vpaidAdVideoStart();
    };

    mraid.onAdVideoFirstQuartile = function() {
        var invoke = "vpaid://vpaidAdVideoFirstQuartile";
        mraid.vpaidInvoke(invoke);
        // CTMRAIDVpaidClient.vpaidAdVideoFirstQuartile();
    };

    mraid.onAdVideoMidpoint = function() {
        var invoke = "vpaid://vpaidAdVideoMidpoint";
        mraid.vpaidInvoke(invoke);
        // CTMRAIDVpaidClient.vpaidAdVideoMidpoint();
    };

    mraid.onAdVideoThirdQuartile = function() {
        var invoke = "vpaid://vpaidAdVideoThirdQuartile";
        mraid.vpaidInvoke(invoke);
        // CTMRAIDVpaidClient.vpaidAdVideoThirdQuartile();
    };

    mraid.onAdVideoComplete = function() {
        var invoke = "vpaid://vpaidAdVideoComplete";
        mraid.vpaidInvoke(invoke);
        // CTMRAIDVpaidClient.vpaidAdVideoComplete();
    };
    //////////
    //
    // MRAID_ENV
    //
    var MRAID_ENV = {
        version: "",
        sdk: "",
        sdkVersion: "",
        appId: "",
        ifa: "",
        limitAdTracking: false,
        coppa: false,
        androidExpandFixBug: 0
    };
    window.MRAID_ENV = MRAID_ENV;
    window.mraidEnv = MRAID_ENV;
    mraid.setEnv = function(properties) {
        var writableFields = ["version", "sdk", "sdkVersion", "appId", "ifa", "limitAdTracking", "coppa", "androidExpandFixBug"];

        for (wf in writableFields) {
            var field = writableFields[wf];
            if (properties[field] !== undefined) {
                MRAID_ENV[field] = properties[field];
            }
        }
    };

    // Exposure Change Event
    var currentExposure = {
        exposedPercentage: 0,
        viewport: {
            width: 0,
            height: 0
        },
        visibleRectangle: {
            x: 0,
            y: 0,
            width: 0,
            height: 0,
            occlusionRectangle: {
                x: 0,
                y: 0,
                width: 0,
                height: 0
            }
        }
    };

    mraid.setExposureChange = function(exposure) {
        var handlers = listeners[EVENTS.EXPOSURE_CHANGE];
        currentExposure = exposure;
        if (handlers) {
            var exposedPercentage = currentExposure.exposedPercentage;
            var visibleRectangle = currentExposure.visibleRectangle;
            var occlusionRectangle = currentExposure.visibleRectangle.occlusionRectangle;

            for (var i = 0; i < handlers.length; ++i) {
                handlers[i](exposedPercentage, visibleRectangle, occlusionRectangle);
            }
        }
    };

    //Audio Volume Change Event
    mraid.setAudioVolumeChange = function(audioVolume) {
        var handlers = listeners[EVENTS.AUDIO_VOLUME_CHANGE];
        if (handlers) {
            for (var i = 0; i < handlers.length; ++i) {
                handlers[i](audioVolume);
            }
        }
    };

    //App Orientation
    var APP_ORIENTATION_PROPERTIES = mraid.APP_ORIENTATION_PROPERTIES = {
        PORTRAIT: "portrait",
        LANDSCAPE: "landscape"
    };

    var currentOrientation = {
        orientation: APP_ORIENTATION_PROPERTIES.PORTRAIT,
        locked: false
    };

    mraid.setCurrentAppOrientation = function(properties) {
        var writableFields = ["orientation", "locked"];
        for (wf in writableFields) {
            var field = writableFields[wf];
            if (properties !== undefined && properties[field] !== undefined) {
                currentOrientation[field] = properties[field];
            }
        }
    };

    mraid.getCurrentAppOrientation = function() {
        return currentOrientation;
    };

    //location
    var currentLocation = {
        lat: 0,
        lon: 0,
        type: 0,
        accuracy: "",
        lastfix: 0,
        ipservice: ""
    };

    mraid.setLocation = function(properties) {
        var writableFields = ["lat", "lon", "type", "accuracy", "lastfix", "ipservice"];
        for (wf in writableFields) {
            var field = writableFields[wf];
            if (properties[field] !== undefined) {
                currentLocation[field] = properties[field];
            }
        }
    };

    mraid.getLocation = function() {
        if (currentLocation.lat !== 0 && currentLocation.lon !== 0)
            return currentLocation;
        else
            return -1;
    };
    mraid.setCloseCounter = function(parameters) {
        console.log("setCloseCounter");
        var invoke = "mraid://setCloseCounter?seconds=" + encodeURIComponent(JSON.stringify(parameters));
        mraid.nativeInvoke(invoke);
    };

    //unload
    mraid.unload = function() {
        mraid.nativeInvoke("mraid://unload");
    };

    mraid.nativeInvoke("mraid://initialize");
};

if (!window.mraid) {
    window.mraid_init();
}