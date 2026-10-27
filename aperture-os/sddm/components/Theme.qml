import QtQuick

// Central design tokens. Every value can be overridden in theme.conf
// (or theme.conf.user) – see README.md for the full list of keys.
QtObject {
    id: theme

    // Set by Main.qml; drives the resolution-independent scale factor.
    property real screenWidth: 1920
    property real screenHeight: 1080

    // ---- config helpers --------------------------------------------------
    // SDDM exposes theme.conf as the `config` context property. Depending on
    // the SDDM version values arrive as strings or already typed, so every
    // accessor normalises them and falls back to a default.
    function raw(key) {
        if (typeof config === "undefined" || config === null)
            return undefined
        const v = config[key]
        return (v === undefined || v === null || String(v).length === 0) ? undefined : v
    }
    function str(key, fallback) {
        const v = raw(key)
        return v === undefined ? fallback : String(v)
    }
    function num(key, fallback) {
        const v = Number(raw(key))
        return (raw(key) === undefined || isNaN(v)) ? fallback : v
    }
    function bool(key, fallback) {
        const v = raw(key)
        if (v === undefined)
            return fallback
        return v === true || ["true", "1", "yes", "on"].indexOf(String(v).toLowerCase()) >= 0
    }

    // ---- scaling ---------------------------------------------------------
    // Layout is designed for 1920x1080 and scaled uniformly. The lower bound
    // keeps text legible on small screens, `uiScale` allows manual tuning.
    readonly property real uiScale: num("uiScale", 1.0)
    readonly property real s: Math.max(0.62, Math.min(screenWidth / 1920, screenHeight / 1080)) * uiScale
    function px(v) { return Math.round(v * s) }

    // ---- colours -----------------------------------------------------------
    readonly property color base:        str("colorBase", "#0B0F14")
    readonly property color panel:       str("colorPanel", "#0E141B")
    readonly property color field:       str("colorField", "#0A0F15")
    readonly property color line:        str("colorLine", "#2A3846")
    readonly property color text:        str("colorText", "#D9E1E8")
    readonly property color muted:       str("colorMuted", "#7D8D9C")
    readonly property color orange:      str("colorOrange", "#FF8A00")
    readonly property color orangeBright: str("colorOrangeBright", "#FFA640")
    readonly property color blue:        str("colorBlue", "#3BA9FF")
    readonly property color blueBright:  str("colorBlueBright", "#9AD8FF")
    readonly property color error:       str("colorError", "#FF3B30")
    readonly property color success:     str("colorSuccess", "#3BA9FF")
    readonly property color buttonText:  str("colorButtonText", "#141414")

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    // ---- typography --------------------------------------------------------
    readonly property string font: str("fontFamily", "Noto Sans")
    readonly property string mono: str("monoFamily", "Noto Sans Mono")
    // Display face for the wordmark and the clock (Aperture OS: Barlow Semi Condensed)
    readonly property string display: str("displayFamily", font)
    readonly property int fontSize: px(num("fontSize", 15))

    // ---- texts / identity -------------------------------------------------
    readonly property string language: str("language", "de")
    readonly property string chamberId: str("chamberId", "test-chamber-01")
    readonly property string osName: str("osName", "Aperture OS")

    // ---- background ----------------------------------------------------------
    readonly property string backgroundImage: str("background", "assets/background.jpg")
    readonly property real backgroundDim: num("backgroundDim", 0.25)
    // Relative positions (0..1) of the robot eye and the portal inside the
    // background image. Used to place the animated core/portal glows.
    readonly property bool sceneGlows: bool("sceneGlows", true)
    readonly property real coreX: num("coreX", 0.749)
    readonly property real coreY: num("coreY", 0.209)
    readonly property real portalX: num("portalX", 0.972)
    readonly property real portalY: num("portalY", 0.615)
    readonly property bool showGrid: bool("showGrid", true)
    readonly property bool showScanlines: bool("showScanlines", true)

    // ---- behaviour / animation ---------------------------------------------
    // reduceMotion disables every continuous animation (useful on very weak
    // hardware, software rendering or for accessibility).
    readonly property bool reduceMotion: bool("reduceMotion", false)
    readonly property bool animate: !reduceMotion
    readonly property bool bootSequence: bool("bootSequence", true) && !reduceMotion
    readonly property int bootDuration: num("bootDuration", 2600)
    readonly property int idleTimeout: num("idleTimeout", 90) * 1000      // 0 = never
    readonly property int authTimeout: num("authTimeout", 20) * 1000
    readonly property bool showUserList: bool("showUserList", true)
    readonly property bool clearPasswordOnStandby: bool("clearPasswordOnStandby", true)

    // ---- sound -------------------------------------------------------------------
    readonly property bool soundEnabled: bool("sounds", true)
    readonly property string soundPack: str("soundPack", "portal")
    readonly property real soundVolume: Math.max(0, Math.min(1, num("soundVolume", 0.6)))
    readonly property bool ambience: bool("ambience", false)

    // ---- durations (ms) ---------------------------------------------------------
    readonly property int fast: 140
    readonly property int normal: 280
    readonly property int slow: 700
}
