import QtQuick
import ".."

Text {
    id: root

    property string value: ""
    property int maxLength: 0
    property bool elideText: false

    readonly property string sourceText: "" + root.value
    readonly property string displayValue: {
        if (root.maxLength > 0 && root.sourceText.length > root.maxLength)
            return root.sourceText.substring(0, root.maxLength - 1) + "…";
        return root.sourceText;
    }

    text: root.displayValue
    textFormat: Text.PlainText
    font.family: Theme.fontText
    font.pointSize: Theme.textSize
    color: Theme.fg
    style: Theme.outlineText ? Text.Outline : Text.Normal
    styleColor: Theme.textOutline
    verticalAlignment: Text.AlignVCenter
    wrapMode: Text.NoWrap
    elide: root.elideText ? Text.ElideRight : Text.ElideNone
}
