pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.launcher.services

// One clip as a card in the clipboard strip: a thumbnail for images, the start of the text otherwise.
Item {
    id: root

    required property var modelData
    required property var list

    readonly property bool image: modelData?.image ?? false
    readonly property bool pinned: modelData?.pinned ?? false
    readonly property string thumbFile: pinned ? (modelData?.file ?? "") : `${Clipboard.previewDir}/${modelData?.id}`
    property bool thumbReady: pinned

    implicitWidth: Tokens.sizes.launcher.itemHeight * 3.4
    implicitHeight: Tokens.sizes.launcher.itemHeight * 2.8

    Component.onCompleted: {
        // History images are decoded to a file once and shared with the preview; only digits reach the shell command.
        if (image && !pinned && /^[0-9]+$/.test(modelData.id))
            decode.running = true;
    }

    Process {
        id: decode

        command: ["sh", "-c", `mkdir -p "${Clipboard.previewDir}" && { [ -s "${Clipboard.previewDir}/${root.modelData?.id}" ] || cliphist decode ${root.modelData?.id} > "${Clipboard.previewDir}/${root.modelData?.id}"; }`]
        onExited: code => root.thumbReady = code === 0
    }

    StyledRect {
        anchors.fill: parent
        anchors.margins: Tokens.padding.small / 2

        radius: Tokens.rounding.large
        color: Qt.alpha(Colours.palette.m3surfaceContainerHigh, 0.6)
        border.width: 2
        border.color: root.ListView.isCurrentItem ? Colours.palette.m3primary : "transparent"

        Behavior on border.color {
            CAnim {}
        }

        StateLayer {
            radius: Tokens.rounding.large
            onClicked: root.modelData?.onClicked(root.list)
        }

        // Image: the thumbnail, cropped to fill the card.
        Image {
            anchors.fill: parent
            anchors.margins: 2
            visible: root.image && root.thumbReady
            source: visible ? `file://${root.thumbFile}` : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: width * 2
            sourceSize.height: height * 2
        }

        MaterialIcon {
            anchors.centerIn: parent
            visible: root.image && !root.thumbReady
            text: "image"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.extraLarge
        }

        // Text: the start of the clip.
        StyledText {
            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            anchors.topMargin: Tokens.padding.medium + Tokens.padding.large
            visible: !root.image

            text: root.modelData?.text ?? ""
            font: Tokens.font.body.small
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            maximumLineCount: 5
        }

        // Pin and delete, top right. On an image they sit on a scrim so they stay readable.
        Row {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Tokens.padding.small
            spacing: Tokens.spacing.small

            StyledRect {
                implicitWidth: pinIcon.implicitWidth + Tokens.padding.small * 2
                implicitHeight: implicitWidth
                radius: Tokens.rounding.full
                color: root.image ? Qt.alpha(Colours.palette.m3surface, 0.7) : "transparent"

                MaterialIcon {
                    id: pinIcon

                    anchors.centerIn: parent
                    text: "push_pin"
                    fill: root.pinned ? 1 : 0
                    color: root.pinned || pinArea.containsMouse ? Colours.palette.m3primary : Colours.palette.m3outline
                }

                MouseArea {
                    id: pinArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.modelData?.togglePin()
                }
            }

            StyledRect {
                visible: !root.pinned
                implicitWidth: deleteIcon.implicitWidth + Tokens.padding.small * 2
                implicitHeight: implicitWidth
                radius: Tokens.rounding.full
                color: root.image ? Qt.alpha(Colours.palette.m3surface, 0.7) : "transparent"

                MaterialIcon {
                    id: deleteIcon

                    anchors.centerIn: parent
                    text: "delete"
                    color: deleteArea.containsMouse ? Colours.palette.m3error : Colours.palette.m3outline
                }

                MouseArea {
                    id: deleteArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.modelData?.remove()
                }
            }
        }
    }
}
