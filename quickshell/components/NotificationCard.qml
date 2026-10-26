import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../services"

Rectangle {
    id: root

    property var notification: null
    property bool popupMode: false
    property bool showApp: true
    property int maxBodyLines: root.popupMode ? 3 : 6

    signal closeRequested()
    signal activated()

    readonly property bool hovered: cardMouse.containsMouse
    readonly property var actionButtons: {
        const list = root.notification && root.notification.actions ? root.notification.actions : [];
        const result = [];
        for (let i = 0; i < list.length; i++) {
            if (list[i] && list[i].identifier !== "default")
                result.push(list[i]);
        }
        return result;
    }

    readonly property string appLabel: root.notification
        ? (root.notification.appName || root.notification.desktopEntry || "Notification")
        : "Notification"
    readonly property string summaryText: root.notification ? (root.notification.summary || "") : ""
    readonly property string bodyText: root.notification ? (root.notification.body || "") : ""
    readonly property string firstBodyLine: {
        const text = root.bodyText;
        const newline = text.indexOf("\n");
        return newline >= 0 ? text.substring(0, newline) : text;
    }
    // Some notifiers send only a body. Promote that line rather than showing
    // an empty headline above it.
    readonly property string headlineText: root.summaryText.length > 0
        ? root.summaryText
        : root.firstBodyLine
    readonly property string detailText: root.summaryText.length > 0
        ? root.bodyText
        : ""
    readonly property bool hasBody: root.detailText.length > 0
    readonly property bool systemNotifier: NotificationService.isSystemNotifier(root.notification)
    readonly property bool hasActions: root.actionButtons.length > 0
    readonly property string imageSource: root.notification ? (root.notification.image || "") : ""
    readonly property int urgency: root.notification ? Number(root.notification.urgency || 0) : 0

    implicitHeight: content.implicitHeight + 22
    radius: root.popupMode ? Theme.radiusPanel : Theme.radiusCard
    color: root.popupMode
        ? Theme.panel
        : (root.hovered ? Theme.alpha(Theme.surfaceHigh, 0.46) : Theme.alpha(Theme.surfaceHigh, 0.36))
    border.width: 1
    border.color: root.urgency === 2
        ? Theme.alpha(Theme.error, 0.45)
        : (root.hovered ? Theme.alpha(Theme.fg, 0.09) : Theme.alpha(Theme.fg, 0.055))

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }

    RowLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 11
        anchors.rightMargin: 9
        anchors.topMargin: 11
        spacing: 10

        AppIcon {
            Layout.alignment: Qt.AlignTop
            size: 30
            source: root.notification ? (root.notification.appIcon || "") : ""
            fallbackIcon: root.notification && root.notification.urgency === 2 ? Glyphs.warning : Glyphs.bell
            foreground: Theme.alpha(Theme.dim, 0.85)
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Label {
                    Layout.fillWidth: true
                    visible: root.showApp && !root.systemNotifier
                    value: root.appLabel
                    strong: true
                    size: 9
                    color: Theme.alpha(Theme.fg, 0.68)
                }

                Label {
                    value: root.notification ? NotificationService.relativeTime(root.notification.id) : ""
                    size: 8
                    color: Theme.dim
                    opacityValue: 0.42
                }
            }

            Label {
                Layout.fillWidth: true
                visible: root.headlineText.length > 0
                value: root.headlineText
                strong: true
                size: 11
                color: Theme.fg
            }

            Label {
                Layout.fillWidth: true
                visible: root.hasBody
                value: root.detailText
                size: 10
                color: Theme.alpha(Theme.dim, 0.78)
                wrapMode: Text.Wrap
                maximumLineCount: root.maxBodyLines
                elide: Text.ElideRight
                textFormat: Text.StyledText
                onLinkActivated: function(link) { Qt.openUrlExternally(link); }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 92
                visible: root.imageSource.length > 0
                radius: Theme.radiusControl
                color: Theme.surfaceLowest
                clip: true

                Image {
                    anchors.fill: parent
                    source: root.imageSource
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                }
            }

            Flow {
                Layout.fillWidth: true
                spacing: 5
                visible: root.hasActions

                Repeater {
                    model: root.actionButtons

                    delegate: Rectangle {
                        id: actionButton
                        required property var modelData

                        implicitWidth: actionText.implicitWidth + 16
                        implicitHeight: 24
                        radius: Theme.radiusControl
                        color: actionMouse.containsMouse ? Theme.hover : Theme.input
                        border.width: 1
                        border.color: Theme.border

                        Label {
                            id: actionText
                            anchors.centerIn: parent
                            value: actionButton.modelData.text
                            size: 9
                            color: Theme.fg
                        }

                        MouseArea {
                            id: actionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NotificationService.invokeAction(root.notification, actionButton.modelData)
                        }
                    }
                }
            }
        }

        IconButton {
            Layout.alignment: Qt.AlignTop
            icon: Glyphs.close
            iconSize: 13
            size: 22
            iconColor: Theme.dim
            opacity: root.popupMode || root.hovered ? 1 : 0
            onClicked: root.closeRequested()
        }
    }
}
