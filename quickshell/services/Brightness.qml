pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Singleton {
    id: root

    property int value: 100
    property int maximum: 100
    property bool available: true
    property bool busy: false
    property int pending: -1

    function refresh() {
        if (getProcess.running || setProcess.running || setTimer.running)
            return;
        getProcess.running = true;
    }

    function setValue(next) {
        const v = Math.max(0, Math.min(root.maximum, Math.round(next)));
        root.value = v;
        root.pending = v;
        setTimer.restart();
    }

    function commit() {
        if (root.pending < 0 || setProcess.running)
            return;
        root.busy = true;
        setProcess.command = ["bash", Settings.paths.shellScripts + "/brightness.sh", "set", String(root.pending)];
        setProcess.running = true;
    }

    Process {
        id: getProcess
        command: ["bash", Settings.paths.shellScripts + "/brightness.sh", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseInt(text.trim());
                if (!isNaN(n)) {
                    root.value = n;
                    root.available = true;
                } else {
                    root.available = false;
                }
            }
        }
    }

    Process {
        id: setProcess
        stdout: StdioCollector {}
        onExited: {
            root.busy = false;
            root.pending = -1;
        }
    }

    Timer {
        id: setTimer
        interval: 180
        repeat: false
        onTriggered: root.commit()
    }

    // DDC/CI reads are relatively expensive. Refresh when the Controls panel
    // opens instead of polling the monitor every 12 seconds for the whole
    // session.
    Component.onCompleted: root.refresh()
}
