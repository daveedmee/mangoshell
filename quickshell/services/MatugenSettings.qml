pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Singleton {
    id: root

    property string scheme: "scheme-tonal-spot"
    property real contrast: 0
    property string mode: "auto"
    property string prefer: "saturation"
    property string sourceColor: ""
    property string textColor: ""
    property string activeColor: ""
    property string backgroundColor: ""
    property real lightness: 0

    property bool loaded: false
    property bool applying: false
    property bool pending: false
    property string error: ""

    function load() {
        if (loadProcess.running)
            return;
        loadProcess.running = true;
    }

    function scheduleApply() {
        if (!root.loaded)
            return;
        debounce.restart();
    }

    function applyNow() {
        if (!root.loaded)
            return;
        if (applyProcess.running) {
            root.pending = true;
            return;
        }

        root.applying = true;
        root.error = "";
        applyProcess.command = [
            "bash", Settings.paths.shellScripts + "/matugen-settings.sh", "apply",
            "--scheme", root.scheme,
            "--contrast", "" + root.contrast,
            "--mode", root.mode,
            "--prefer", root.prefer,
            "--source-color", root.sourceColor.length > 0 ? root.sourceColor : "auto",
            "--text-color", root.textColor.length > 0 ? root.textColor : "auto",
            "--active-color", root.activeColor.length > 0 ? root.activeColor : "auto",
            "--background-color", root.backgroundColor.length > 0 ? root.backgroundColor : "auto",
            "--lightness-dark", "" + root.lightness,
            "--lightness-light", "" + root.lightness
        ];
        applyProcess.running = true;
    }

    function setDefaults() {
        root.scheme = "scheme-tonal-spot";
        root.contrast = 0;
        root.mode = "auto";
        root.prefer = "saturation";
        root.sourceColor = "";
        root.textColor = "";
        root.activeColor = "";
        root.backgroundColor = "";
        root.lightness = 0;
        root.scheduleApply();
    }

    Process {
        id: loadProcess
        command: ["bash", Settings.paths.shellScripts + "/matugen-settings.sh", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text || "{}");
                    root.scheme = data.scheme || "scheme-tonal-spot";
                    root.contrast = Number(data.contrast || 0);
                    root.mode = data.mode || "auto";
                    root.prefer = data.prefer || "saturation";
                    root.sourceColor = data.sourceColor || "";
                    root.textColor = data.textColor || "";
                    root.activeColor = data.activeColor || "";
                    root.backgroundColor = data.backgroundColor || "";
                    root.lightness = Number(data.lightnessDark || 0);
                    root.loaded = true;
                } catch (e) {
                    root.error = "Could not read Matugen settings";
                }
            }
        }
    }

    Process {
        id: applyProcess
        onExited: function(code) {
            root.applying = false;
            if (code !== 0)
                root.error = "Matugen could not regenerate the theme";
            if (root.pending) {
                root.pending = false;
                root.applyNow();
            }
        }
    }

    Timer {
        id: debounce
        interval: 320
        repeat: false
        onTriggered: root.applyNow()
    }

    Component.onCompleted: root.load()
}
