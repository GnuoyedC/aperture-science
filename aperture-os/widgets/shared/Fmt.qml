import QtQuick

// Formatting helpers and the level thresholds shared by the widgets.
// Instantiate once per plasmoid (next to Tokens) and pass it around as `fmt`.
QtObject {
    id: fmt

    property Tokens tk
    property real high: 85
    property real crit: 95

    // bytes/s -> "12.3 kB/s" (decimal units, like Plasma's system monitor)
    function rate(bytes) {
        const b = Math.max(0, Number(bytes) || 0)
        if (b < 1000)
            return Math.round(b) + " B/s"
        if (b < 1e6)
            return (b / 1e3).toFixed(b < 1e4 ? 1 : 0) + " kB/s"
        if (b < 1e9)
            return (b / 1e6).toFixed(b < 1e7 ? 1 : 0) + " MB/s"
        return (b / 1e9).toFixed(1) + " GB/s"
    }
    // bytes -> "8.3" (GiB, no unit)
    function gib(bytes) {
        const g = Math.max(0, Number(bytes) || 0) / 1073741824
        return g.toFixed(g < 100 ? 1 : 0)
    }
    // seconds -> "03:12 h" or "2 d  03:12"
    function duration(seconds) {
        const s = Math.max(0, Math.floor(Number(seconds) || 0))
        const d = Math.floor(s / 86400)
        const h = Math.floor((s % 86400) / 3600)
        const m = Math.floor((s % 3600) / 60)
        const hm = (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m
        return d > 0 ? d + " d  " + hm : hm + " h"
    }
    // percent -> OK / HIGH / CRIT and the matching bar / word colours
    function levelState(percent) {
        return percent >= crit ? "CRIT" : percent >= high ? "HIGH" : "OK"
    }
    function levelColor(percent) {
        if (!tk)
            return "white"
        return percent >= crit ? tk.error : percent >= high ? tk.warning : tk.blue
    }
    function stateColor(percent) {
        if (!tk)
            return "gray"
        return percent >= crit ? tk.error : percent >= high ? tk.warning : tk.textDisabled
    }
}
