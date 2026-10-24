pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.items
import qs.modules.launcher.services

// The clipboard as a grid of cards, a couple of rows at a time. Moving past the last visible card flips to the
// next set of rows; the wheel scrolls a row at a time. (The launcher's other modes are vertical lists.)
GridView {
    id: root

    required property SearchBar search
    required property ScreenState screenState

    readonly property int visibleRows: 2
    readonly property int columns: Math.max(1, Math.floor(width / cellWidth))
    readonly property int rows: Math.ceil(count / columns)
    readonly property real maxY: Math.max(0, rows * cellHeight - height)
    property bool wheeling

    // Move the highlight by whole cells; Up / Down use dy, Left / Right dx.
    function step(dx: int, dy: int): void {
        if (count === 0)
            return;
        currentIndex = Math.max(0, Math.min(count - 1, currentIndex + dx + dy * columns));
    }

    function incrementCurrentIndex(): void {
        step(1, 0);
    }

    function decrementCurrentIndex(): void {
        step(-1, 0);
    }

    // Show the set of rows that holds the highlighted card.
    function showHighlighted(): void {
        const row = Math.floor(currentIndex / columns);
        contentY = Math.min(maxY, Math.floor(row / visibleRows) * visibleRows * cellHeight);
    }

    cellWidth: Tokens.sizes.launcher.itemHeight * 3.4
    cellHeight: Tokens.sizes.launcher.itemHeight * 2.8
    implicitHeight: cellHeight * visibleRows
    leftMargin: Math.max(0, (width - columns * cellWidth) / 2)

    clip: true
    interactive: false
    highlightFollowsCurrentItem: false

    model: ScriptModel {
        values: Clipboard.query(root.search.text)
        onValuesChanged: root.currentIndex = 0
    }

    delegate: ClipboardCard {
        list: root
    }

    onCurrentIndexChanged: {
        if (!wheeling)
            showHighlighted();
    }

    Behavior on contentY {
        Anim {}
    }

    // The wheel moves a row at a time; the highlight follows into view, in the same column.
    WheelHandler {
        onWheel: event => {
            const dir = event.angleDelta.y < 0 ? 1 : -1;
            root.wheeling = true;
            root.contentY = Math.max(0, Math.min(root.maxY, root.contentY + dir * root.cellHeight));
            const first = Math.round(root.contentY / root.cellHeight);
            const row = Math.floor(root.currentIndex / root.columns);
            const col = root.currentIndex % root.columns;
            if (row < first)
                root.currentIndex = Math.min(root.count - 1, first * root.columns + col);
            else if (row > first + root.visibleRows - 1)
                root.currentIndex = Math.min(root.count - 1, (first + root.visibleRows - 1) * root.columns + col);
            root.wheeling = false;
        }
    }

    // Fresh history every time the strip comes up.
    Component.onCompleted: Clipboard.reload()
}
