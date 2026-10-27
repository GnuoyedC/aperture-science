pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import "components"

// Aperture Laboratories – SDDM greeter (Qt 6 / SDDM theme API 2.0)
//
// SDDM context objects used: sddm, userModel, sessionModel, keyboard,
// config, primaryScreen (optional).
//
// Greeter phases:
//   boot     initialisation sequence (skippable)
//   login    idle console, waiting for input
//   auth     credentials sent to SDDM, waiting for loginSucceeded/Failed
//   success  confirmation, UI fades out until SDDM starts the session
//   error    short glitch + error banner, falls back to "login" by itself
// `standby` is an independent flag that dims the UI after inactivity.
Rectangle {
    id: root

    width: 1920
    height: 1080
    color: theme.base

    LayoutMirroring.enabled: Qt.locale().textDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    // SDDM creates one greeter per screen; only the primary one gets the
    // login console, sounds and the boot sequence.
    readonly property bool isPrimary: typeof primaryScreen === "undefined" || primaryScreen

    property string phase: theme.bootSequence && isPrimary ? "boot" : "login"
    property bool standby: false
    property string message: ""
    property bool messageIsError: true

    // Bundled fonts (assets/fonts): SDDM runs as its own user and cannot see the
    // fonts installed in the user's home. Missing files are simply ignored.
    Repeater {
        model: ["Inter-Regular", "Inter-Medium", "Inter-SemiBold", "JetBrainsMono-Regular",
                "JetBrainsMono-Bold", "BarlowSemiCondensed-Medium", "BarlowSemiCondensed-SemiBold"]
        delegate: Item {
            required property string modelData
            FontLoader { source: Qt.resolvedUrl("assets/fonts/" + modelData + ".ttf") }
        }
    }

    Theme {
        id: theme
        screenWidth: root.width
        screenHeight: root.height
    }

    Strings {
        id: strings
        language: theme.language
    }

    // ---- sound -------------------------------------------------------------
    // Loaded dynamically: without QtMultimedia or an audio device the Loader
    // simply fails and audio.play() becomes a no-op.
    Loader {
        id: soundLoader
        active: theme.soundEnabled && root.isPrimary
        source: "components/SoundPlayer.qml"
        onLoaded: {
            item.pack = Qt.binding(() => theme.soundPack)
            item.volume = Qt.binding(() => theme.soundVolume)
            item.ambience = Qt.binding(() => theme.ambience && !root.standby && root.phase !== "success")
        }
    }

    QtObject {
        id: audio
        function play(name) {
            // After success only the confirmation sound may still play.
            if (soundLoader.status !== Loader.Ready || (root.phase === "success" && name !== "login_success"))
                return
            soundLoader.item.play(name)
        }
        function stopAll() {
            if (soundLoader.item)
                soundLoader.item.stopAll()
        }
    }

    // ---- SDDM signals ------------------------------------------------------
    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        ignoreUnknownSignals: true

        function onLoginFailed() {
            authTimeout.stop()
            panel.clearPassword()
            root.showError(strings.tr("failed"))
        }

        function onLoginSucceeded() {
            authTimeout.stop()
            root.message = ""
            root.phase = "success"
            audio.play("login_success")
            successSequence.restart()
        }

        function onInformationMessage(message) {
            // e.g. PAM messages ("password expired"). Shown as a hint.
            root.showHint(message)
        }
    }

    // ---- state helpers -------------------------------------------------------
    function attemptLogin(user, password, sessionIndex) {
        if (phase === "auth" || phase === "success")
            return
        if (user.length === 0) {
            showHint(strings.tr("noUser"))
            audio.play("ui_error")
            panel.focusUser()
            return
        }
        message = ""
        errorReset.stop()
        resetGlitch()
        phase = "auth"
        authTimeout.restart()
        sddm.login(user, password, sessionIndex)
    }

    function showError(text) {
        message = text
        messageIsError = true
        phase = "error"
        audio.play("login_failure")
        resetGlitch()
        glitch.start()
        errorReset.restart()
        panel.focusPassword()
    }

    function showHint(text) {
        message = text
        messageIsError = false
        if (phase === "error")
            phase = "login"
    }

    function resetGlitch() {
        glitch.stop()
        shake.x = 0
        glitchBars.opacity = 0
        flash.opacity = 0
    }

    function finishBoot() {
        if (phase !== "boot")
            return
        phase = "login"
        intro.restart()
        audio.play("ui_click")
    }

    // Any user input: leave standby, restart idle countdown, clear hints.
    function noteActivity() {
        if (standby) {
            standby = false
            panel.focusInitial()
        }
        idleTimer.restart()
    }

    function enterStandby() {
        if (phase !== "login" && phase !== "error")
            return
        if (powerMenu.opened)
            return
        resetGlitch()
        phase = "login"
        message = ""
        if (theme.clearPasswordOnStandby)
            panel.clearPassword()
        standby = true
    }

    function runPowerAction(action) {
        audio.stopAll()
        switch (action) {
        case "powerOff": sddm.powerOff(); break
        case "reboot": sddm.reboot(); break
        case "suspend": sddm.suspend(); break
        case "hibernate": sddm.hibernate(); break
        }
    }

    // ---- timers --------------------------------------------------------------
    Timer {
        id: idleTimer
        interval: Math.max(5000, theme.idleTimeout)
        running: theme.idleTimeout > 0 && root.isPrimary && !root.standby
                 && (root.phase === "login" || root.phase === "error")
        onTriggered: root.enterStandby()
    }

    // Never hang in "auth": SDDM normally answers within a second.
    Timer {
        id: authTimeout
        interval: Math.max(5000, theme.authTimeout)
        onTriggered: if (root.phase === "auth") root.showError(strings.tr("timeout"))
    }

    // Back to the normal console after the error banner was visible a while.
    Timer {
        id: errorReset
        interval: 4500
        onTriggered: {
            if (root.phase === "error") {
                root.phase = "login"
                root.message = ""
            }
        }
    }

    // Safety net: if SDDM keeps the greeter alive after success (e.g. the
    // session failed to start), return to a usable console.
    Timer {
        id: successFallback
        interval: 15000
        onTriggered: {
            if (root.phase === "success") {
                ui.opacity = 1
                root.phase = "login"
                panel.focusInitial()
            }
        }
    }

    // ---- scene ---------------------------------------------------------------
    ChamberBackground {
        id: background
        anchors.fill: parent
        theme: theme
        animated: theme.animate
        extraDim: root.standby ? 1 : 0
        coreMode: root.phase === "error" ? "error" : root.phase === "success" ? "success" : "idle"
    }

    // Full-screen colour flash (red on error, blue on success).
    Rectangle {
        id: flash
        anchors.fill: parent
        color: root.phase === "success" ? theme.blue : theme.error
        opacity: 0
    }

    // ---- main UI layer ---------------------------------------------------------
    Item {
        id: ui
        anchors.fill: parent
        opacity: root.phase === "boot" ? 0 : 1
        transform: Translate { id: shake }

        // Brand, top left.
        Row {
            id: brand
            x: theme.px(56)
            y: theme.px(44)
            spacing: theme.px(14)
            opacity: root.standby ? 0.45 : 1
            Behavior on opacity { NumberAnimation { duration: theme.slow } }

            Image {
                width: theme.px(70); height: width
                sourceSize: Qt.size(width * 2, height * 2)
                source: "assets/aperture-logo.svg"
                opacity: 0.9
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: strings.tr("brand.top")
                    color: theme.text
                    opacity: 0.9
                    font.family: theme.display
                    font.pixelSize: theme.px(46)
                    font.weight: Font.DemiBold
                    font.letterSpacing: theme.px(3)
                }
                Text {
                    text: strings.tr("brand.bottom")
                    color: theme.text
                    opacity: 0.75
                    font.family: theme.font
                    font.pixelSize: theme.px(15)
                    font.letterSpacing: theme.px(9.5)
                    leftPadding: theme.px(30)
                }
            }
        }

        HudStatus {
            id: hud
            visible: root.isPrimary
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: theme.px(48)
            anchors.topMargin: theme.px(44)
            width: theme.px(270)
            theme: theme
            strings: strings
            animated: theme.animate
            compact: root.standby
        }

        // Central console: emblem, login panel, power buttons. Scaled down
        // further if the screen is too short so nothing leaves the screen.
        Column {
            id: consoleColumn
            visible: root.isPrimary
            anchors.horizontalCenter: parent.horizontalCenter
            y: (root.height - height * scale) / 2 + introOffset - height * (1 - scale) / 2
            spacing: theme.px(26)
            scale: Math.min(1, (root.height - theme.px(40)) / Math.max(1, implicitHeight))
            transformOrigin: Item.Top
            opacity: root.standby ? 0 : 1
            enabled: !root.standby
            Behavior on opacity { NumberAnimation { duration: theme.slow; easing.type: Easing.InOutQuad } }

            property real introOffset: 0

            ApertureRing {
                id: emblem
                anchors.horizontalCenter: parent.horizontalCenter
                width: theme.px(210)
                height: width
                theme: theme
                animated: theme.animate && !root.standby
                mode: root.phase === "auth" ? "active"
                    : root.phase === "success" ? "success"
                    : root.phase === "error" ? "error" : "idle"
            }

            LoginPanel {
                id: panel
                anchors.horizontalCenter: parent.horizontalCenter
                width: theme.px(460)
                theme: theme
                strings: strings
                audio: audio
                phase: root.phase === "boot" ? "login" : root.phase
                message: root.message
                messageIsError: root.messageIsError
                onLoginRequested: (user, password, sessionIndex) => root.attemptLogin(user, password, sessionIndex)
                onActivity: {
                    root.noteActivity()
                    if (!root.messageIsError)
                        root.message = ""
                }
            }

            Row {
                id: powerRow
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: theme.px(56)
                visible: powerMenu.actions.length > 0

                Repeater {
                    model: powerMenu.actions
                    PowerButton {
                        required property var modelData
                        iconName: modelData.icon
                        label: strings.tr(modelData.id)
                        onClicked: powerMenu.openFor(modelData.id)
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: theme.px(16)
            text: strings.tr("footer")
            color: theme.muted
            opacity: 0.45
            font.family: theme.mono
            font.pixelSize: theme.px(10)
            font.letterSpacing: theme.px(2)
        }

        // Horizontal glitch bars, only visible for a few frames on error.
        Item {
            id: glitchBars
            anchors.fill: parent
            opacity: 0
            visible: opacity > 0
            Repeater {
                model: [0.31, 0.47, 0.52, 0.68]
                Rectangle {
                    required property real modelData
                    required property int index
                    y: root.height * modelData
                    x: index % 2 === 0 ? theme.px(12) : -theme.px(10)
                    width: root.width
                    height: theme.px(index % 2 === 0 ? 3 : 7)
                    color: theme.alpha(theme.error, 0.35)
                }
            }
        }
    }

    StandbyScreen {
        anchors.fill: parent
        visible: opacity > 0
        opacity: root.standby || !root.isPrimary ? 1 : 0
        theme: theme
        strings: strings
        animated: theme.animate
        Behavior on opacity { NumberAnimation { duration: theme.slow; easing.type: Easing.InOutQuad } }
    }

    Loader {
        id: bootLoader
        anchors.fill: parent
        active: root.phase === "boot"
        sourceComponent: BootSequence {
            theme: theme
            strings: strings
            audio: audio
            duration: theme.bootDuration
            onFinished: root.finishBoot()
            Component.onCompleted: start()
        }
    }

    PowerMenu {
        id: powerMenu
        theme: theme
        strings: strings
        audio: audio
        onActionTriggered: action => root.runPowerAction(action)
        onClosed: if (root.phase !== "boot") panel.focusInitial()
    }

    // ---- activity tracking -----------------------------------------------------
    // Pointer handlers are passive: they observe input without stealing it
    // from the controls underneath.
    // Qt re-sends hover events whenever animated items move under a resting
    // cursor, so only a real change of the pointer position counts.
    HoverHandler {
        property point last: Qt.point(-1, -1)
        onPointChanged: {
            const p = point.scenePosition
            if (Math.abs(p.x - last.x) + Math.abs(p.y - last.y) > 2) {
                const first = last.x < 0
                last = p
                if (!first)
                    root.noteActivity()
            }
        }
    }
    PointHandler {
        acceptedButtons: Qt.AllButtons
        onActiveChanged: if (active) root.noteActivity()
    }
    // Keys not consumed by a focused control (Shift, arrows, …) bubble up here.
    Keys.onPressed: function(event) {
        root.noteActivity()
        event.accepted = false
    }

    // ---- animations ------------------------------------------------------------

    // Login console slides in after the boot sequence.
    ParallelAnimation {
        id: intro
        NumberAnimation { target: ui; property: "opacity"; from: 0; to: 1; duration: 650; easing.type: Easing.OutCubic }
        NumberAnimation { target: consoleColumn; property: "introOffset"; from: theme.px(36); to: 0; duration: 750; easing.type: Easing.OutCubic }
        NumberAnimation { target: emblem; property: "scale"; from: 0.88; to: 1; duration: 900; easing.type: Easing.OutBack }
        NumberAnimation { target: emblem; property: "rotation"; from: -60; to: 0; duration: 1100; easing.type: Easing.OutCubic }
        onFinished: panel.focusInitial()
    }

    // Error: a few frames of horizontal jitter + red flash + glitch bars.
    SequentialAnimation {
        id: glitch
        ParallelAnimation {
            NumberAnimation { target: flash; property: "opacity"; to: 0.16; duration: 50 }
            NumberAnimation { target: glitchBars; property: "opacity"; to: 1; duration: 30 }
            NumberAnimation { target: shake; property: "x"; to: -theme.px(9); duration: 40 }
        }
        NumberAnimation { target: shake; property: "x"; to: theme.px(7); duration: 45 }
        PropertyAction { target: glitchBars; property: "opacity"; value: 0 }
        NumberAnimation { target: shake; property: "x"; to: -theme.px(4); duration: 45 }
        PropertyAction { target: glitchBars; property: "opacity"; value: 0.7 }
        NumberAnimation { target: shake; property: "x"; to: theme.px(2); duration: 40 }
        PropertyAction { target: glitchBars; property: "opacity"; value: 0 }
        ParallelAnimation {
            NumberAnimation { target: shake; property: "x"; to: 0; duration: 60 }
            NumberAnimation { target: flash; property: "opacity"; to: 0; duration: 420; easing.type: Easing.OutQuad }
        }
    }

    // Success: blue flash, short hold on "TEST SEQUENCE INITIALIZED", fade out.
    // Kept under one second so the session start is not delayed noticeably.
    SequentialAnimation {
        id: successSequence
        NumberAnimation { target: flash; property: "opacity"; to: 0.12; duration: 120 }
        NumberAnimation { target: flash; property: "opacity"; to: 0; duration: 380 }
        PauseAnimation { duration: 150 }
        NumberAnimation { target: ui; property: "opacity"; to: 0; duration: 450; easing.type: Easing.InQuad }
        ScriptAction { script: successFallback.restart() }
    }

    // ---- inline components -----------------------------------------------------

    component PowerButton: AbstractButton {
        id: pbtn
        property string iconName
        property string label

        width: theme.px(96)
        height: theme.px(76)
        hoverEnabled: true
        focusPolicy: Qt.TabFocus
        onClicked: audio.play("ui_click")
        Keys.onReturnPressed: clicked()
        Keys.onEnterPressed: clicked()

        contentItem: Column {
            spacing: theme.px(8)
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: theme.px(42); height: width; radius: width / 2
                color: pbtn.hovered || pbtn.activeFocus ? theme.alpha(theme.orange, 0.15) : theme.alpha(theme.base, 0.45)
                border.width: 1
                border.color: pbtn.hovered || pbtn.activeFocus ? theme.orange : theme.alpha(theme.text, 0.35)
                Behavior on border.color { ColorAnimation { duration: theme.fast } }
                Image {
                    anchors.centerIn: parent
                    width: theme.px(22); height: width
                    sourceSize: Qt.size(width * 2, height * 2)
                    source: "assets/icons/" + pbtn.iconName
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: pbtn.label
                color: pbtn.hovered || pbtn.activeFocus ? theme.text : theme.alpha(theme.text, 0.8)
                font.family: theme.font
                font.pixelSize: theme.px(13)
            }
        }
        background: null
    }

    Component.onCompleted: {
        if (phase === "login") {
            intro.restart()
            panel.focusInitial()
        }
    }
}
