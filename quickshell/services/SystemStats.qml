pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Singleton {
    id: root

    property int cpu: 0
    property int ram: 0
    property string ramUsed: "—"
    property int swap: 0
    property int gpu: 0
    property bool gpuAvailable: false
    property int temp: 0
    property string rx: "0 B/s"
    property string tx: "0 B/s"
    property string network: ""
    // Sampling is only useful while the Controls panel is visible. Keeping
    // the sampler alive for the rest of the session wastes CPU on a 2 s loop.
    property bool active: false

    function apply(line) {
        if (!line || line.trim().length === 0)
            return;
        try {
            const data = JSON.parse(line);
            root.cpu = data.cpu || 0;
            root.ram = data.ram || 0;
            root.ramUsed = data.ramUsed || "—";
            root.swap = data.swap || 0;
            root.gpu = data.gpu || 0;
            root.gpuAvailable = data.gpuAvailable === true;
            root.temp = data.temp || 0;
            root.rx = data.rx || "0 B/s";
            root.tx = data.tx || "0 B/s";
            root.network = data.network || "";
        } catch (e) {
            console.warn("SystemStats: bad sample:", e);
        }
    }

    Process {
        id: sampler
        command: ["bash", Settings.paths.shellScripts + "/system-stats.sh"]
        running: root.active
        stdout: SplitParser {
            onRead: function(line) { root.apply(line); }
        }
        onExited: {
            if (root.active)
                restartTimer.restart();
        }
    }

    Timer {
        id: restartTimer
        interval: 2000
        repeat: false
        onTriggered: {
            if (root.active && !sampler.running)
                sampler.running = true;
        }
    }
}
