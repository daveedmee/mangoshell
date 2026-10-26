import QtQuick
import ".."

Text {
    id: root

    property string name: ""
    property bool filled: false
    property int size: 18
    property int weight: 400
    property real opacityValue: 1

    text: root.name
    textFormat: Text.PlainText
    color: Theme.fg
    opacity: root.opacityValue
    font.family: Theme.fontIcon
    font.pixelSize: root.size
    font.variableAxes: ({
        "FILL": root.filled ? 1 : 0,
        "wght": root.weight,
        "GRAD": 0,
        "opsz": 24
    })
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}
