import QtQuick
import ".."
import "../components"
import "../services"

Rectangle {
    id: popover

    property int viewYear: new Date().getFullYear()
    property int viewMonth: new Date().getMonth()
    property date selectedDate: new Date()
    property string draftTitle: ""
    property string draftTime: ""

    implicitWidth: ShellState.centerBarWidth > 0
        ? ShellState.centerBarWidth
        : Settings.overlay.calendarWidth
    implicitHeight: 480
    radius: Theme.radiusPanel
    color: Theme.panel
    border.width: 1
    border.color: Theme.border
    clip: true

    readonly property date today: new Date()
    readonly property string selectedKey: dateKey(selectedDate)
    readonly property var selectedEntries: CalendarStore.eventsForDate(selectedKey)
    readonly property bool canAdd: draftTitle.trim().length > 0
        && (draftTime.length === 0 || validTime(draftTime))
    readonly property var cells: buildCells()

    function pad(value) {
        return value < 10 ? "0" + value : "" + value;
    }

    function dateKey(date) {
        return date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate());
    }

    function validTime(value) {
        return /^([01][0-9]|2[0-3]):[0-5][0-9]$/.test(value.trim());
    }

    function addEntry() {
        const title = draftTitle.trim();
        const time = draftTime.trim();
        if (title.length === 0 || (time.length > 0 && !validTime(time)))
            return;

        CalendarStore.add(selectedKey, time, title);
        draftTitle = "";
        draftTime = "";
        titleInput.forceActiveFocus();
    }

    function buildCells() {
        const first = new Date(popover.viewYear, popover.viewMonth, 1);
        const weekday = (first.getDay() + 6) % 7; // Monday-first
        const days = new Date(popover.viewYear, popover.viewMonth + 1, 0).getDate();
        const prevDays = new Date(popover.viewYear, popover.viewMonth, 0).getDate();
        const list = [];

        for (let i = 0; i < 42; i++) {
            const offset = i - weekday;
            let day;
            let monthOffset = 0;
            if (offset < 0) {
                day = prevDays + offset + 1;
                monthOffset = -1;
            } else if (offset >= days) {
                day = offset - days + 1;
                monthOffset = 1;
            } else {
                day = offset + 1;
            }

            const date = new Date(popover.viewYear, popover.viewMonth + monthOffset, day);
            const key = popover.dateKey(date);
            const isToday = date.getFullYear() === popover.today.getFullYear()
                && date.getMonth() === popover.today.getMonth()
                && date.getDate() === popover.today.getDate();
            const isSelected = date.getFullYear() === popover.selectedDate.getFullYear()
                && date.getMonth() === popover.selectedDate.getMonth()
                && date.getDate() === popover.selectedDate.getDate();

            list.push({
                "day": day,
                "offset": monthOffset,
                "date": date,
                "key": key,
                "muted": monthOffset !== 0,
                "today": isToday,
                "selected": isSelected,
                "entryCount": CalendarStore.countForDate(key)
            });
        }
        return list;
    }

    function shiftMonth(delta) {
        const date = new Date(popover.viewYear, popover.viewMonth + delta, 1);
        popover.viewYear = date.getFullYear();
        popover.viewMonth = date.getMonth();
    }

    function resetToday() {
        const now = new Date();
        popover.viewYear = now.getFullYear();
        popover.viewMonth = now.getMonth();
        popover.selectedDate = now;
    }

    function weekNumber(date) {
        const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
        const day = d.getUTCDay() || 7;
        d.setUTCDate(d.getUTCDate() + 4 - day);
        const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
        return Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
    }

    Component.onCompleted: CalendarStore.refresh()

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
    }

    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 16
        anchors.rightMargin: 12
        anchors.topMargin: 14
        height: 36

        Label {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            value: new Date(popover.viewYear, popover.viewMonth, 1)
                .toLocaleDateString(Qt.locale(), "MMMM yyyy")
            strong: true
            size: 16
            color: Theme.fg
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Rectangle {
                width: todayLabel.implicitWidth + 14
                height: 26
                radius: Theme.radiusControl
                color: todayMouse.containsMouse ? Theme.hover : "transparent"

                Label {
                    id: todayLabel
                    anchors.centerIn: parent
                    value: "Today"
                    size: 8
                    color: Theme.primary
                }

                MouseArea {
                    id: todayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popover.resetToday()
                }
            }

            IconButton {
                icon: Glyphs.chevronLeft
                size: 28
                iconSize: 17
                iconColor: Theme.dim
                onClicked: popover.shiftMonth(-1)
            }

            IconButton {
                icon: Glyphs.chevronRight
                size: 28
                iconSize: 17
                iconColor: Theme.dim
                onClicked: popover.shiftMonth(1)
            }
        }
    }

    Item {
        id: weekdays
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        height: 20

        Row {
            width: parent.width

            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                delegate: Label {
                    required property string modelData
                    width: weekdays.width / 7
                    value: modelData
                    size: 7
                    color: Theme.dim
                    opacityValue: 0.55
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    Grid {
        id: daysGrid
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: weekdays.bottom
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        columns: 7
        columnSpacing: 0
        rowSpacing: 1

        readonly property real cellWidth: width / 7

        Repeater {
            model: popover.cells

            delegate: Item {
                id: cell

                required property var modelData

                width: daysGrid.cellWidth
                height: 32

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: Theme.radiusCard
                    color: cell.modelData.today
                        ? Theme.primary
                        : (dayMouse.containsMouse ? Theme.hover : "transparent")
                    border.width: cell.modelData.selected && !cell.modelData.today ? 1 : 0
                    border.color: Theme.alpha(Theme.primary, 0.55)

                    Label {
                        anchors.centerIn: parent
                        value: "" + cell.modelData.day
                        strong: cell.modelData.today || cell.modelData.selected
                        size: 10
                        color: cell.modelData.today
                            ? Theme.primaryText
                            : cell.modelData.muted
                                ? Theme.alpha(Theme.dim, 0.30)
                                : Theme.alpha(Theme.fg, 0.76)
                    }

                    Rectangle {
                        visible: cell.modelData.entryCount > 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 4
                        width: 3
                        height: 3
                        radius: 1.5
                        color: cell.modelData.today ? Theme.primaryText : Theme.primary
                    }
                }

                MouseArea {
                    id: dayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        popover.selectedDate = cell.modelData.date;
                        if (cell.modelData.offset !== 0)
                            popover.shiftMonth(cell.modelData.offset);
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: daysGrid.bottom
        anchors.topMargin: 6
        height: 1
        color: Theme.alpha(Theme.fg, 0.06)
    }

    Item {
        id: entriesHeader
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: daysGrid.bottom
        anchors.topMargin: 16
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        height: 18

        Label {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            value: "Notes & appointments"
            strong: true
            size: 9
            color: Theme.fg
        }

        Label {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            value: "W" + popover.weekNumber(popover.selectedDate) + " · "
                + popover.selectedDate.toLocaleDateString(Qt.locale(), "ddd, dd MMM")
            size: 8
            color: Theme.dim
            opacityValue: 0.7
        }
    }

    Flickable {
        id: entriesScroll
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: entriesHeader.bottom
        anchors.topMargin: 6
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        height: 82
        clip: true
        contentWidth: width
        contentHeight: entriesColumn.height
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: entriesColumn
            width: entriesScroll.width
            spacing: 3

            Repeater {
                model: popover.selectedEntries

                delegate: Rectangle {
                    id: entryRow
                    required property var modelData

                    width: entriesColumn.width
                    height: 32
                    radius: Theme.radiusControl
                    color: entryMouse.containsMouse ? Theme.hover : Theme.alpha(Theme.fg, 0.025)
                    border.width: 1
                    border.color: Theme.alpha(Theme.fg, 0.055)

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.right: deleteButton.left
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Label {
                            width: 40
                            value: entryRow.modelData.time.length > 0
                                ? entryRow.modelData.time
                                : "Note"
                            eyebrow: entryRow.modelData.time.length === 0
                            size: 8
                            color: entryRow.modelData.time.length > 0 ? Theme.primary : Theme.dim
                        }

                        Label {
                            width: parent.width - 48
                            value: entryRow.modelData.title
                            size: 9
                            color: Theme.alpha(Theme.fg, 0.82)
                            elide: Text.ElideRight
                        }
                    }

                    IconButton {
                        id: deleteButton
                        anchors.right: parent.right
                        anchors.rightMargin: 3
                        anchors.verticalCenter: parent.verticalCenter
                        icon: Glyphs.trash
                        iconSize: 12
                        size: 24
                        iconColor: Theme.dim
                        danger: true
                        onClicked: CalendarStore.remove(entryRow.modelData.id)
                    }

                    MouseArea {
                        id: entryMouse
                        anchors.fill: parent
                        anchors.rightMargin: 28
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton
                    }
                }
            }

            Label {
                visible: popover.selectedEntries.length === 0
                width: parent.width
                height: 32
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                value: "No entries for this day"
                size: 8
                color: Theme.dim
                opacityValue: 0.5
            }
        }
    }

    Row {
        id: composer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: entriesScroll.bottom
        anchors.topMargin: 8
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 6

        Rectangle {
            width: parent.width - timeBox.width - addButton.width - 12
            height: 34
            radius: Theme.radiusControl
            color: Theme.surfaceLowest
            border.width: 1
            border.color: titleInput.activeFocus
                ? Theme.alpha(Theme.primary, 0.42)
                : Theme.alpha(Theme.fg, 0.07)

            TextInput {
                id: titleInput
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 9
                anchors.rightMargin: 9
                height: parent.height
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.fg
                font.family: Theme.fontText
                font.pixelSize: 10
                selectionColor: Theme.primary
                selectedTextColor: Theme.primaryText
                clip: true
                activeFocusOnPress: true
                onTextChanged: popover.draftTitle = text
                onAccepted: popover.addEntry()

                Label {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    visible: titleInput.text.length === 0
                    value: "Add note or appointment"
                    size: 9
                    color: Theme.dim
                    opacityValue: 0.5
                }
            }
        }

        Rectangle {
            id: timeBox
            width: 58
            height: 34
            radius: Theme.radiusControl
            color: Theme.surfaceLowest
            border.width: 1
            border.color: popover.draftTime.length > 0 && !popover.validTime(popover.draftTime)
                ? Theme.alpha(Theme.error, 0.55)
                : (timeInput.activeFocus
                    ? Theme.alpha(Theme.primary, 0.42)
                    : Theme.alpha(Theme.fg, 0.07))

            TextInput {
                id: timeInput
                anchors.fill: parent
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.fg
                font.family: Theme.fontText
                font.pixelSize: 10
                selectionColor: Theme.primary
                selectedTextColor: Theme.primaryText
                maximumLength: 5
                activeFocusOnPress: true
                onTextChanged: popover.draftTime = text
                onAccepted: popover.addEntry()

                Label {
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    visible: timeInput.text.length === 0
                    value: "HH:MM"
                    size: 8
                    color: Theme.dim
                    opacityValue: 0.45
                }
            }
        }

        IconButton {
            id: addButton
            width: 30
            height: 34
            icon: Glyphs.add
            iconSize: 16
            size: 30
            active: popover.canAdd
            interactive: popover.canAdd
            onClicked: popover.addEntry()
        }
    }
}
