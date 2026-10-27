pragma ComponentBehavior: Bound
import QtQuick
import QtMultimedia

// Short UI sound effects. Loaded through a Loader in Main.qml, so a missing
// QtMultimedia module or audio device never breaks the greeter – the theme
// simply stays silent.
//
// Files are looked up in sounds/<pack>/<name>.wav. If a file of the selected
// pack is missing or unreadable, the synthetic fallback pack is used.
Item {
    id: player

    property string pack: "portal"
    property real volume: 0.6
    property bool ambience: false

    readonly property string fallbackPack: "synth"
    readonly property var names: [
        "boot_start", "system_ready", "ui_focus", "ui_click", "ui_error",
        "portal_activate", "login_success", "login_failure"
    ]
    // Per-sound gain relative to `volume` (UI ticks should stay very quiet).
    readonly property var gain: ({ "ui_focus": 0.45, "ui_click": 0.6 })

    function urlFor(packName, name) {
        return Qt.resolvedUrl("../sounds/" + packName + "/" + name + ".wav")
    }

    function play(name) {
        for (let i = 0; i < effects.count; ++i) {
            const fx = effects.objectAt(i)
            if (fx && fx.soundName === name) {
                if (fx.status === SoundEffect.Ready)
                    fx.play()
                return
            }
        }
    }

    function stopAll() {
        for (let i = 0; i < effects.count; ++i) {
            const fx = effects.objectAt(i)
            if (fx)
                fx.stop()
        }
        ambienceLoop.stop()
    }

    Instantiator {
        id: effects
        model: player.names

        delegate: SoundEffect {
            required property string modelData
            readonly property string soundName: modelData

            source: player.urlFor(player.pack, modelData)
            volume: player.volume * (player.gain[modelData] !== undefined ? player.gain[modelData] : 1.0)

            onStatusChanged: {
                if (status === SoundEffect.Error && player.pack !== player.fallbackPack
                        && String(source).indexOf("/" + player.fallbackPack + "/") < 0)
                    source = player.urlFor(player.fallbackPack, modelData)
            }
        }
    }

    // Optional, very quiet facility hum. Off by default (theme.conf: ambience).
    SoundEffect {
        id: ambienceLoop
        source: player.urlFor(player.pack, "ambience_loop")
        loops: SoundEffect.Infinite
        volume: player.volume * 0.5

        onStatusChanged: {
            if (status === SoundEffect.Error && String(source).indexOf("/" + player.fallbackPack + "/") < 0)
                source = player.urlFor(player.fallbackPack, "ambience_loop")
            else if (status === SoundEffect.Ready && player.ambience)
                play()
        }
    }

    onAmbienceChanged: ambience && ambienceLoop.status === SoundEffect.Ready ? ambienceLoop.play() : ambienceLoop.stop()
}
