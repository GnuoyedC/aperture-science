pragma ComponentBehavior: Bound
import QtQuick

// Terminal-style initialisation shown for ~2.6 s when the greeter starts.
// Any key or click skips it. Emits finished() exactly once.
FocusScope {
    id: boot

    property var theme
    property var strings
    property var audio
    property int duration: 2600

    signal finished()

    property int step: 0               // number of revealed lines
    property bool done: false

    // Each entry: text key, whether it gets an " ..... OK" suffix,
    // and an optional sound played when the line appears.
    readonly property var lines: [
        { key: "boot.title1", ok: false, gap: false, sound: "boot_start" },
        { key: "boot.title2", ok: false, gap: false, sound: "" },
        { key: "boot.step1", ok: true, gap: true, sound: "" },
        { key: "boot.step2", ok: true, gap: false, sound: "portal_activate" },
        { key: "boot.step3", ok: true, gap: false, sound: "" },
        { key: "boot.welcome", ok: false, gap: true, sound: "system_ready" }
    ]

    function start() {
        step = 0
        done = false
        forceActiveFocus()
        ticker.start()
    }

    function finish() {
        if (done)
            return
        done = true
        ticker.stop()
        step = lines.length
        finished()
    }

    Keys.onPressed: function(event) { boot.finish(); event.accepted = true }

    MouseArea {
        anchors.fill: parent
        onClicked: boot.finish()
    }

    // Darken the scene while the "machine" boots.
    Rectangle {
        anchors.fill: parent
        color: boot.theme.base
        opacity: 0.55
    }

    Timer {
        id: ticker
        // Lines are spread over ~80 % of the duration; the rest is the hold
        // on "WELCOME" before the login console slides in.
        interval: Math.max(120, boot.duration * 0.8 / boot.lines.length)
        repeat: true
        onTriggered: {
            if (boot.step < boot.lines.length) {
                const snd = boot.lines[boot.step].sound
                if (snd.length > 0)
                    boot.audio.play(snd)
                boot.step++
            } else {
                stop()
                holdTimer.start()
            }
        }
    }
    Timer {
        id: holdTimer
        interval: Math.max(200, boot.duration * 0.2)
        onTriggered: boot.finish()
    }

    Column {
        id: terminal
        x: Math.max(boot.theme.px(48), boot.width * 0.08)
        // Fixed top edge, so the block does not re-centre as lines appear.
        y: boot.height * 0.36
        spacing: boot.theme.px(6)

        Repeater {
            model: boot.lines
            Item {
                required property var modelData
                required property int index
                width: lineText.implicitWidth + okText.implicitWidth
                height: lineText.implicitHeight + (modelData.gap ? boot.theme.px(18) : 0)
                visible: index < boot.step
                // OK suffix appears one tick after the line itself.
                readonly property bool confirmed: index < boot.step - 1 || boot.done

                Text {
                    id: lineText
                    anchors.bottom: parent.bottom
                    text: boot.strings.tr(modelData.key) + (modelData.ok ? " " + ".".repeat(Math.max(3, 30 - boot.strings.tr(modelData.key).length)) + " " : "")
                    color: modelData.key === "boot.welcome" ? boot.theme.blueBright : boot.theme.blue
                    font.family: boot.theme.mono
                    font.pixelSize: boot.theme.px(modelData.key === "boot.welcome" ? 22 : 18)
                    font.bold: modelData.key === "boot.welcome"
                    font.letterSpacing: boot.theme.px(1)
                }
                Text {
                    id: okText
                    anchors.left: lineText.right
                    anchors.bottom: parent.bottom
                    visible: modelData.ok && parent.confirmed
                    text: boot.strings.tr("boot.ok")
                    color: boot.theme.orange
                    font: lineText.font
                }
            }
        }

        // Blinking cursor.
        Rectangle {
            width: boot.theme.px(12)
            height: boot.theme.px(3)
            color: boot.theme.blueBright
            SequentialAnimation on opacity {
                running: boot.visible
                loops: Animation.Infinite
                NumberAnimation { to: 0; duration: 1 }
                PauseAnimation { duration: 380 }
                NumberAnimation { to: 1; duration: 1 }
                PauseAnimation { duration: 380 }
            }
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: boot.theme.px(40)
        text: boot.strings.tr("skipHint")
        color: boot.theme.muted
        opacity: 0.6
        font.family: boot.theme.mono
        font.pixelSize: boot.theme.px(11)
        font.letterSpacing: boot.theme.px(1)
    }
}
