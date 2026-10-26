//@ pragma UseQApplication
//@ pragma IconTheme breeze

import QtQuick
import Quickshell
import "."
import "popups"
import "services"

ShellRoot {
    id: root

    readonly property var overviewService: Overview

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Bar {
                required property var modelData
                targetScreen: modelData
            }
        }
    }

    LayoutPanelWindow {}
    OverlayHost {}
    OSD {}
    NotificationPopup {}
}
