import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// A dropdown in one pill: the selected item and a chevron, and the whole pill opens the menu.
// (It used to be two joined pieces, hence the name; the properties are the same.)
StyledRect {
    id: root

    enum Type {
        Filled,
        Tonal
    }

    property real horizontalPadding: Tokens.padding.large
    property real verticalPadding: Tokens.padding.small
    property real spacing: Tokens.spacing.small
    property int type: SplitButton.Filled
    property bool disabled
    property bool menuOnTop
    property string fallbackIcon
    property string fallbackText
    property real minLeftWidth

    property alias menuItems: menu.items
    property alias active: menu.active
    property alias expanded: menu.expanded
    readonly property alias menu: menu
    readonly property alias iconLabel: iconLabel
    readonly property alias label: label
    readonly property alias stateLayer: stateLayer
    readonly property alias textRow: textRow
    readonly property alias expandBtn: expandIcon

    property color colour: type == SplitButton.Filled ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer
    property color textColour: type == SplitButton.Filled ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
    property color disabledColour: Qt.alpha(Colours.palette.m3onSurface, 0.1)
    property color disabledTextColour: Qt.alpha(Colours.palette.m3onSurface, 0.38)

    radius: implicitHeight / 2 * Math.min(1, Tokens.rounding.scale)
    color: root.disabled ? root.disabledColour : root.colour

    implicitWidth: Math.max(root.minLeftWidth + expandIcon.implicitWidth + root.spacing, textRow.implicitWidth + root.horizontalPadding * 2)
    implicitHeight: textRow.implicitHeight + root.verticalPadding * 2

    StateLayer {
        id: stateLayer

        color: root.textColour
        disabled: root.disabled
        onClicked: root.expanded = !root.expanded
    }

    RowLayout {
        id: textRow

        anchors.centerIn: parent
        width: Math.min(implicitWidth, parent.width - root.horizontalPadding * 2)
        spacing: root.spacing

        MaterialIcon {
            id: iconLabel

            Layout.alignment: Qt.AlignVCenter
            animate: true
            text: root.active?.activeIcon ?? root.fallbackIcon
            color: root.disabled ? root.disabledTextColour : root.textColour
            fill: 1
        }

        StyledText {
            id: label

            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            animate: true
            text: root.active?.activeText ?? root.fallbackText
            color: root.disabled ? root.disabledTextColour : root.textColour
            elide: Text.ElideRight
        }

        MaterialIcon {
            id: expandIcon

            Layout.alignment: Qt.AlignVCenter
            text: "expand_more"
            color: root.disabled ? root.disabledTextColour : root.textColour
            rotation: root.expanded ? 180 : 0

            Behavior on rotation {
                Anim {}
            }
        }
    }

    Menu {
        id: menu

        attachTo: root
        attachSideY: root.menuOnTop ? Menu.Top : Menu.Bottom
        thisSideY: root.menuOnTop ? Menu.Bottom : Menu.Top
        marginY: Tokens.spacing.small * (root.menuOnTop ? -1 : 1)
    }
}
