import QtQuick
import ".."

Text {
    id: root

    property string value: ""
    property bool strong: false
    property bool eyebrow: false
    property int size: Theme.sizeBody
    property real opacityValue: 1

    text: root.eyebrow ? root.value.toUpperCase() : root.value
    textFormat: Text.PlainText
    color: Theme.fg
    opacity: root.opacityValue
    font.family: root.strong ? Theme.fontDemi : Theme.fontText
    font.pixelSize: Math.max(10, root.size)
    font.letterSpacing: root.eyebrow ? 0.9 : 0
    verticalAlignment: Text.AlignVCenter
    wrapMode: Text.NoWrap
    elide: Text.ElideRight
}
