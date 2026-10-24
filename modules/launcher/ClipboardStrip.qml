pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.items
import qs.modules.launcher.services

// The clipboard as a strip of cards you slide through left to right (the launcher's other modes are vertical lists).
ListView {
    id: root

    required property SearchBar search
    required property ScreenState screenState

    readonly property real cardHeight: Tokens.sizes.launcher.itemHeight * 2.8

    orientation: ListView.Horizontal
    spacing: Tokens.spacing.small
    implicitHeight: cardHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    highlightMoveDuration: 200

    model: ScriptModel {
        values: Clipboard.query(root.search.text)
        onValuesChanged: root.currentIndex = 0
    }

    delegate: ClipboardCard {
        list: root
    }

    // Fresh history every time the strip comes up.
    Component.onCompleted: Clipboard.reload()
}
