(function() {
    window.mraid = {};
    mraid.util = {};

    var state = "loading";
    var placementType = "inline";
    var isViewable = false;
    var eventListeners = {};

    // MRAID 3.0 支持的功能列表
    var supportedFeatures = [
        "sms", "tel", "calendar", "storePicture",
        "inlineVideo", "vpaid", "viewable", "audio"
    ];

    // ====================== 版本为 3.0 ======================
    mraid.getVersion = function() {
        return "3.0";
    };

    mraid.getState = function() {
        return state;
    };

    mraid.getPlacementType = function() {
        return placementType;
    };

    mraid.isViewable = function() {
        return isViewable;
    };

    mraid.addEventListener = function(event, cb) {
        if (!eventListeners[event]) eventListeners[event] = [];
        eventListeners[event].push(cb);
    };

    mraid.removeEventListener = function(event, cb) {
        if (!eventListeners[event]) return;
        eventListeners[event] = eventListeners[event].filter(f => f !== cb);
    };

    // ====================== 广告跳转逻辑 ======================
    var h = window.adsurgeOpen ? window.adsurgeOpen : window.open;

    mraid.open = function(url){
        console.log("mraid open trigger", url);
        h("https://f.adsurge.com", "_blank");
    };

    mraid.close = function() {
        state = "closed";
        window.adsurgeFireEvent("close");
    };

    mraid.expand = function(url) {
        state = "expanded";
        window.adsurgeFireEvent("stateChange");
    };

    mraid.resize = function() {};

    // ====================== MRAID 3.0 新增接口 ======================
    mraid.getOrientation = function() {
        return "portrait";
    };

    mraid.setOrientationProperties = function(props) {};

    mraid.getOrientationProperties = function() {
        return {
            allowOrientationChange: true,
            forceOrientation: "auto"
        };
    };

    mraid.getExpandProperties = function() {
        return {
            width: 0,
            height: 0,
            isModal: false
        };
    };

    mraid.setExpandProperties = function(props) {};

    mraid.getResizeProperties = function() {
        return {
            width: 0,
            height: 0,
            offsetX: 0,
            offsetY: 0,
            allowOffscreen: true,
            customClose: true
        };
    };

    mraid.setResizeProperties = function(props) {};

    mraid.supports = function(feature) {
        return supportedFeatures.indexOf(feature) !== -1;
    };

    mraid.getScreenSize = function() {
        return { width: 0, height: 0 };
    };

    mraid.getCurrentPosition = function() {
        return { x: 0, y: 0, width: 0, height: 0 };
    };

    mraid.getDefaultPosition = function() {
        return { x: 0, y: 0, width: 0, height: 0 };
    };

    mraid.getMaxSize = function() {
        return { width: 0, height: 0 };
    };

    mraid.useCustomClose = function(value) {};

    // ====================== 空实现兜底（不报错） ======================
    mraid.enable = function(){};
    mraid.createCalendarEvent = function(){};
    mraid.playVideo = function(){};
    mraid.storePicture = function(){};
    mraid.audioVolumeChange = function(){};

    // ====================== 事件派发 ======================
    window.adsurgeFireEvent = function(event) {
        if (!eventListeners[event]) return;
        eventListeners[event].forEach(cb => {
            try { cb(); } catch (e) {}
        });
    };

    window.adsurgeMaridReady = function() {
        state = "default";
        isViewable = true;
        window.adsurgeFireEvent("ready");
        window.adsurgeFireEvent("viewableChange");
        window.adsurgeFireEvent("stateChange");
    };

    // ====================== 页面加载完成自动初始化 ======================
    window.addEventListener('load', function() {
        window.adsurgeMaridReady();
    });

}).call(this);