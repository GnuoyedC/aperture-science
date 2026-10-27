// A strip of lamps cut from the photo; each lamp (a horizontal band of the PNG)
// flashes briefly, one after the other from top to bottom, then the strip rests.
import QtQuick
import ".."

Item {
    id: strip
    required property var wp
    required property var r          // { src, x, y, w, h } in source px
    required property var bands      // [[y0, y1], ...] in source px, top to bottom
    property real period: 8          // s between sweeps
    property real offset: 0
    property real step: 0.11         // s between neighbouring lamps
    property real gain: 1.8

    readonly property real sy: wp.dispH / 941

    Repeater {
        model: strip.bands
        delegate: Item {
            required property int index
            required property var modelData
            readonly property real c: (strip.wp.t + strip.offset) % strip.period - index * strip.step
            clip: true
            x: strip.wp.mapX((strip.wp.mirror ? strip.r.x + strip.r.w : strip.r.x) / 1672)
            y: strip.wp.mapY(modelData[0] / 941)
            width: strip.r.w / 1672 * strip.wp.dispW
            height: (modelData[1] - modelData[0]) * strip.sy
            opacity: c < 0 ? 0 : Math.min(1, strip.wp.intensity * strip.gain
                     * (c < 0.07 ? c / 0.07 : Math.exp(-(c - 0.07) / 0.16)))
            Image {
                y: -(parent.modelData[0] - strip.r.y) * strip.sy
                width: strip.r.w / 1672 * strip.wp.dispW
                height: strip.r.h / 941 * strip.wp.dispH
                source: strip.r.src
                mirror: strip.wp.mirror
                smooth: true
            }
        }
    }
}
