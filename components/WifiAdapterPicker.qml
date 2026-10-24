import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Dropdown of network adapters (every Wi-Fi one, and the wired ones with includeEthernet), so each can be looked at,
// connected and disconnected on its own.
StyledRect {
    id: root

    function label(iface: var): string {
        return Nmcli.isConnectedState(iface.state) && iface.connection ? `${iface.device} · ${iface.connection}` : iface.device;
    }

    function iconFor(iface: var): string {
        if (iface?.type === "ethernet")
            return "cable";
        return iface && Nmcli.isConnectedState(iface.state) ? "wifi" : "wifi_off";
    }

    property bool includeEthernet

    readonly property var adapters: [...Nmcli.wirelessInterfaces, ...(includeEthernet ? Nmcli.ethernetInterfaces : [])]
    readonly property string selected: includeEthernet && Nmcli.showEthernet ? (Nmcli.ethernetSelected ? Nmcli.selectedDevice : (Nmcli.activeEthernet?.iface ?? Nmcli.ethernetInterfaces[0]?.device ?? "")) : Nmcli.wifiDevice
    readonly property var current: adapters.find(i => i.device === selected) ?? null

    visible: adapters.length > 1
    Layout.fillWidth: true
    implicitHeight: row.implicitHeight + Tokens.padding.small * 2
    radius: Tokens.rounding.full
    color: Colours.palette.m3secondaryContainer

    StateLayer {
        color: Colours.palette.m3onSecondaryContainer
        onClicked: menu.expanded = !menu.expanded
    }

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.large
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: root.iconFor(root.current)
            color: Colours.palette.m3onSecondaryContainer
            fill: 1
        }

        StyledText {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: root.current ? root.label(root.current) : root.selected
            color: Colours.palette.m3onSecondaryContainer
        }

        MaterialIcon {
            text: "expand_more"
            color: Colours.palette.m3onSecondaryContainer
            rotation: menu.expanded ? 180 : 0

            Behavior on rotation {
                Anim {}
            }
        }
    }

    Menu {
        id: menu

        attachTo: root
        attachSideX: Menu.Left
        thisSideX: Menu.Left
        marginY: Tokens.spacing.small
        menuWidth: root.width
        items: adapterItems.instances
        active: items.find(i => i.value === root.selected) ?? null
        onItemSelected: item => Nmcli.selectDevice(item.value)
    }

    Variants {
        id: adapterItems

        model: root.adapters

        MenuItem {
            required property var modelData

            text: root.label(modelData)
            icon: root.iconFor(modelData)
            value: modelData.device
        }
    }
}
