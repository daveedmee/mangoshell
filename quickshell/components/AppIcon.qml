import QtQuick
import Quickshell
import ".."

Item {
    id: root

    property string source: ""
    property string fallbackIcon: Glyphs.bell
    property int size: 27
    property color background: Theme.alpha(Theme.fg, 0.06)
    property color foreground: Theme.dim

    implicitWidth: root.size
    implicitHeight: root.size

    function resolvedSource(value) {
        if (!value || value.length === 0)
            return "";
        if (value.indexOf("/") === 0 || value.indexOf("file:") === 0 || value.indexOf("image://") === 0)
            return value;
        return Quickshell.iconPath(value, true);
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusControl
        color: root.background
    }

    Image {
        id: image
        anchors.centerIn: parent
        width: root.size - 10
        height: root.size - 10
        source: root.resolvedSource(root.source)
        sourceSize.width: root.size
        sourceSize.height: root.size
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        visible: status === Image.Ready
    }

    Icon {
        anchors.centerIn: parent
        visible: image.status !== Image.Ready
        name: root.fallbackIcon
        size: Math.round(root.size * 0.56)
        color: root.foreground
    }
}
