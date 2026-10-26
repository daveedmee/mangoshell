import QtQuick
import ".."

Rectangle {
    id: root

    property real hue: 0
    property real saturation: 0
    property real value: 1
    property string hex: "#000000"
    property string title: "Source colour"
    property var presetColors: []

    signal applied(string color)
    signal cancelled()
    signal eyedropperRequested()

    implicitWidth: 312
    implicitHeight: 320
    radius: Theme.radiusPanel
    color: Theme.panel
    border.width: 1
    border.color: Theme.border
    clip: true

    function clamp(value, low, high) {
        return Math.max(low, Math.min(high, value));
    }

    function componentHex(value) {
        const hex = Math.round(root.clamp(value, 0, 1) * 255).toString(16);
        return hex.length < 2 ? "0" + hex : hex;
    }

    function hsvColor(h, s, v) {
        const c = v * s;
        const hp = (h % 360) / 60;
        const x = c * (1 - Math.abs((hp % 2) - 1));
        let r = 0;
        let g = 0;
        let b = 0;
        if (hp < 1) {
            r = c; g = x;
        } else if (hp < 2) {
            r = x; g = c;
        } else if (hp < 3) {
            g = c; b = x;
        } else if (hp < 4) {
            g = x; b = c;
        } else if (hp < 5) {
            r = x; b = c;
        } else {
            r = c; b = x;
        }
        const m = v - c;
        return {
            r: root.clamp(r + m, 0, 1),
            g: root.clamp(g + m, 0, 1),
            b: root.clamp(b + m, 0, 1)
        };
    }

    function updateHex() {
        root.hex = "#" + root.componentHex(current.r)
            + root.componentHex(current.g)
            + root.componentHex(current.b);
    }

    readonly property var current: hsvColor(root.hue, root.saturation, root.value)

    function applyHex(raw) {
        let value = ("" + (raw || "")).trim();
        if (value.charAt(0) === "#")
            value = value.slice(1);
        if (!/^[0-9a-fA-F]{6}$/.test(value))
            return false;

        const r = parseInt(value.slice(0, 2), 16) / 255;
        const g = parseInt(value.slice(2, 4), 16) / 255;
        const b = parseInt(value.slice(4, 6), 16) / 255;
        const max = Math.max(r, g, b);
        const min = Math.min(r, g, b);
        const delta = max - min;
        let h = 0;

        if (delta > 0) {
            if (max === r)
                h = 60 * (((g - b) / delta) % 6);
            else if (max === g)
                h = 60 * ((b - r) / delta + 2);
            else
                h = 60 * ((r - g) / delta + 4);
        }
        if (h < 0)
            h += 360;

        root.hue = h;
        root.saturation = max <= 0 ? 0 : delta / max;
        root.value = max;
        root.updateHex();
        return true;
    }

    function colorHex(value) {
        if (value === null || value === undefined)
            return "";
        if (typeof value === "string")
            return value.toUpperCase();
        const c = Qt.color(value);
        return ("#" + root.componentHex(c.r) + root.componentHex(c.g)
            + root.componentHex(c.b)).toUpperCase();
    }

    function openWith(value, presets) {
        if (presets !== undefined && presets !== null)
            root.presetColors = presets;
        let raw = ("" + (value || "")).trim();
        if (!root.applyHex(raw))
            root.applyHex("#7a8d87");
        root.visible = true;
    }

    onHueChanged: root.updateHex()
    onSaturationChanged: root.updateHex()
    onValueChanged: root.updateHex()
    onHexChanged: hexField.text = root.hex.toUpperCase()

    Label {
        x: 14
        y: 12
        value: root.title
        strong: true
        size: 11
        color: Theme.fg
    }

    IconButton {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.top: parent.top
        anchors.topMargin: 8
        icon: Glyphs.close
        iconSize: 13
        size: 24
        iconColor: Theme.dim
        onClicked: {
            root.visible = false;
            root.cancelled();
        }
    }

    Rectangle {
        id: preview
        x: 14
        y: 40
        width: 70
        height: 38
        radius: Theme.radiusControl
        color: root.hex
        border.width: 1
        border.color: Theme.alpha(Theme.fg, 0.18)
    }

    Rectangle {
        x: 94
        y: 44
        width: 170
        height: 30
        radius: Theme.radiusControl
        color: Theme.input
        border.width: 1
        border.color: hexField.activeFocus
            ? Theme.alpha(Theme.primary, 0.6)
            : Theme.alpha(Theme.fg, 0.10)

        TextInput {
            id: hexField
            anchors.fill: parent
            anchors.leftMargin: 9
            anchors.rightMargin: 9
            text: root.hex.toUpperCase()
            selectByMouse: true
            activeFocusOnPress: true
            color: Theme.fg
            font.family: Theme.fontDemi
            font.pixelSize: 11
            verticalAlignment: TextInput.AlignVCenter
            clip: true

            HoverHandler {
                cursorShape: Qt.IBeamCursor
            }

            onAccepted: {
                if (!root.applyHex(text))
                    text = root.hex.toUpperCase();
            }
            onEditingFinished: {
                if (!root.applyHex(text))
                    text = root.hex.toUpperCase();
            }
        }
    }

    IconButton {
        anchors.right: parent.right
        anchors.rightMargin: 10
        y: 47
        icon: Glyphs.eyedropper
        iconSize: 14
        size: 24
        iconColor: Theme.dim
        onClicked: root.eyedropperRequested()
    }

    Item {
        x: 14
        y: 86
        width: parent.width - 28
        height: 22
        visible: root.presetColors.length > 0

        Label {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            value: "Presets"
            size: 8
            color: Theme.dim
            opacityValue: 0.7
        }

        Row {
            x: 60
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Repeater {
                model: root.presetColors

                delegate: Rectangle {
                    required property var modelData

                    readonly property string swatch: root.colorHex(modelData)

                    width: 22
                    height: 22
                    radius: Theme.radiusControl
                    color: modelData
                    border.width: swatch === root.hex.toUpperCase() ? 2 : 1
                    border.color: swatch === root.hex.toUpperCase()
                        ? Theme.fg
                        : Theme.alpha(Theme.fg, 0.15)

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.applyHex(swatch)
                    }
                }
            }
        }
    }

    Item {
        x: 14
        y: 116
        width: parent.width - 28
        height: 38

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            value: "Hue"
            size: 8
            color: Theme.dim
        }

        Label {
            anchors.right: parent.right
            anchors.top: parent.top
            value: Math.round(root.hue) + "°"
            size: 8
            color: Theme.alpha(Theme.fg, 0.7)
        }

        ThinSlider {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 16
            from: 0
            to: 360
            value: root.hue
            trackHeight: 3
            knobWidth: 4
            knobHeight: 12
            onMoved: function(value) { root.hue = value; }
        }
    }

    Item {
        x: 14
        y: 158
        width: parent.width - 28
        height: 38

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            value: "Saturation"
            size: 8
            color: Theme.dim
        }

        Label {
            anchors.right: parent.right
            anchors.top: parent.top
            value: Math.round(root.saturation * 100) + "%"
            size: 8
            color: Theme.alpha(Theme.fg, 0.7)
        }

        ThinSlider {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 16
            from: 0
            to: 1
            value: root.saturation
            trackHeight: 3
            knobWidth: 4
            knobHeight: 12
            onMoved: function(value) { root.saturation = value; }
        }
    }

    Item {
        x: 14
        y: 200
        width: parent.width - 28
        height: 38

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            value: "Brightness"
            size: 8
            color: Theme.dim
        }

        Label {
            anchors.right: parent.right
            anchors.top: parent.top
            value: Math.round(root.value * 100) + "%"
            size: 8
            color: Theme.alpha(Theme.fg, 0.7)
        }

        ThinSlider {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 16
            from: 0
            to: 1
            value: root.value
            trackHeight: 3
            knobWidth: 4
            knobHeight: 12
            onMoved: function(value) { root.value = value; }
        }
    }

    Row {
        x: 14
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        spacing: 6

        Rectangle {
            width: 78
            height: 28
            radius: Theme.radiusControl
            color: cancelMouse.containsMouse ? Theme.hover : "transparent"
            border.width: 1
            border.color: Theme.alpha(Theme.fg, 0.10)

            Label {
                anchors.centerIn: parent
                value: "Cancel"
                size: 9
                color: Theme.alpha(Theme.fg, 0.7)
            }

            MouseArea {
                id: cancelMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.visible = false;
                    root.cancelled();
                }
            }
        }

        Rectangle {
            width: 78
            height: 28
            radius: Theme.radiusControl
            color: applyMouse.containsMouse ? Theme.primaryContainer : Theme.primary

            Label {
                anchors.centerIn: parent
                value: "Apply"
                strong: true
                size: 9
                color: Theme.primaryText
            }

            MouseArea {
                id: applyMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    // Pick up a hex value typed without pressing Return.
                    root.applyHex(hexField.text);
                    root.applied(root.hex);
                    root.visible = false;
                }
            }
        }
    }
}
