import QtQuick
import ".."

Text {
    textFormat: Text.PlainText
    font.family: Theme.fontIcon
    font.pointSize: Theme.iconSize
    color: Theme.fg
    style: Theme.outlineText ? Text.Outline : Text.Normal
    styleColor: Theme.textOutline
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}
