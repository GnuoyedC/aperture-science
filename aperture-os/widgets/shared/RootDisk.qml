import QtQuick
import org.kde.plasma.plasma5support as P5Support

// Resolves the KSystemStats sensor prefix of the root file system.
// KSystemStats names partitions by file system UUID: ask findmnt once for the
// UUID of "/" and fall back to the "all disks" aggregate ("disk/all").
// Call markFailed() when a sensor below `base` reports an error.
Item {
    id: disk

    property bool active: true
    property string uuid: ""
    property bool failed: false
    readonly property bool isRoot: uuid.length > 0 && !failed
    readonly property string base: isRoot ? "disk/" + uuid : "disk/all"

    function markFailed() {
        if (isRoot)
            failed = true
    }

    visible: false

    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, data) => {
            const out = String(data["stdout"] || "").trim()
            if (/^[0-9A-Za-z-]+$/.test(out))
                disk.uuid = out
            exec.disconnectSource(source)
        }
    }
    function probe() {
        if (active && uuid.length === 0)
            exec.connectSource("findmnt -no UUID /")
    }
    onActiveChanged: probe()
    Component.onCompleted: probe()
}
