pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.items
import qs.modules.launcher.services

// The clipboard as one row of cards (a horizontal list, so it is always a single row). Reaching the last visible card flips to the next row, which starts with that
// card; going back mirrors it. The wheel flips a row at a time. (The launcher's other modes are vertical lists.)
ListView {
    id: root

    required property SearchBar search
    required property ScreenState screenState

    // First visible card, and how many fit.
    property int start
    property int previousIndex
    property bool wheeling
    readonly property int columns: Math.max(1, Math.floor(width / cellWidth))

    // Show the row beginning at card i (kept inside the list).
    function showFrom(i: int): void {
        start = Math.max(0, Math.min(Math.max(0, count - columns), i));
        contentX = originX + start * cellWidth;
    }

    // Move the highlight one card (Up / Down move it too, as in the other lists).
    function step(dx: int, dy: int): void {
        if (count === 0)
            return;
        currentIndex = Math.max(0, Math.min(count - 1, currentIndex + dx + dy));
    }

    function incrementCurrentIndex(): void {
        step(1, 0);
    }

    function decrementCurrentIndex(): void {
        step(-1, 0);
    }

    readonly property real cellWidth: Tokens.sizes.launcher.itemHeight * 3.4
    readonly property real cellHeight: Tokens.sizes.launcher.itemHeight * 2.8

    implicitHeight: cellHeight
    leftMargin: Math.max(0, (width - columns * cellWidth) / 2)

    orientation: ListView.Horizontal
    spacing: 0
    clip: true
    interactive: false
    highlightFollowsCurrentItem: false
    highlightRangeMode: ListView.NoHighlightRange

    model: ScriptModel {
        values: Clipboard.query(root.search.text)
        onValuesChanged: {
            root.currentIndex = 0;
            root.previousIndex = 0;
            root.showFrom(0);
        }
    }

    delegate: ClipboardCard {
        list: root
    }

    onCurrentIndexChanged: {
        if (wheeling)
            return;
        const forward = currentIndex > previousIndex;
        previousIndex = currentIndex;
        if (currentIndex < start)
            showFrom(currentIndex - (columns - 1)); // went back: this card becomes the last of the row
        else if (currentIndex > start + columns - 1)
            showFrom(currentIndex);
        else if (forward && currentIndex === start + columns - 1 && currentIndex < count - 1)
            showFrom(currentIndex); // reached the last visible card: it becomes the first of the next row
    }

    Behavior on contentX {
        Anim {}
    }

    // The wheel flips a row at a time (the new row starts on the old row's last card); the highlight follows into view.
    WheelHandler {
        onWheel: event => {
            const dir = event.angleDelta.y < 0 ? 1 : -1;
            root.wheeling = true;
            root.showFrom(root.start + dir * (root.columns - 1));
            if (root.currentIndex < root.start)
                root.currentIndex = root.start;
            else if (root.currentIndex > root.start + root.columns - 1)
                root.currentIndex = Math.min(root.count - 1, root.start + root.columns - 1);
            root.previousIndex = root.currentIndex;
            root.wheeling = false;
        }
    }

    // Fresh history every time the strip comes up.
    Component.onCompleted: Clipboard.reload()
}
