pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Singleton {
    id: root

    property var events: []
    property bool loaded: false
    property string error: ""

    readonly property string script: Settings.paths.shellScripts + "/calendar-events.sh"

    function refresh() {
        if (!listProcess.running)
            listProcess.running = true;
    }

    function add(date, time, title) {
        if (!date || !title || title.trim().length === 0)
            return;
        if (addProcess.running)
            return;

        addProcess.command = ["bash", root.script, "add", date, time || "", title.trim()];
        addProcess.running = true;
    }

    function remove(id) {
        if (!id || removeProcess.running)
            return;

        removeProcess.command = ["bash", root.script, "remove", id];
        removeProcess.running = true;
    }

    function parse(text) {
        try {
            const data = JSON.parse(text || "{}");
            root.events = Array.isArray(data.events) ? data.events : [];
            root.loaded = true;
            root.error = "";
        } catch (e) {
            root.events = [];
            root.error = "Could not read calendar entries";
            root.loaded = true;
        }
    }

    function eventsForDate(key) {
        const out = [];
        const list = root.events || [];
        for (let i = 0; i < list.length; i++) {
            if (list[i] && list[i].date === key)
                out.push(list[i]);
        }
        out.sort(function(a, b) {
            const at = (a.time || "").length > 0 ? a.time : "99:99";
            const bt = (b.time || "").length > 0 ? b.time : "99:99";
            if (at !== bt)
                return at < bt ? -1 : 1;
            return Number(a.created || 0) - Number(b.created || 0);
        });
        return out;
    }

    function countForDate(key) {
        let count = 0;
        const list = root.events || [];
        for (let i = 0; i < list.length; i++) {
            if (list[i] && list[i].date === key)
                count += 1;
        }
        return count;
    }

    Process {
        id: listProcess
        command: ["bash", root.script, "list"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Process {
        id: addProcess
        stdout: StdioCollector {}
        onExited: root.refresh()
    }

    Process {
        id: removeProcess
        stdout: StdioCollector {}
        onExited: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
