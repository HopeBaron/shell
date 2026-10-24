import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var modelData
    required property var list

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: root.modelData?.onClicked(root.list)
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.margins: Tokens.padding.small

        StyledText {
            id: glyph

            anchors.verticalCenter: parent.verticalCenter
            width: parent.height * 1.8
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.modelData?.glyph ?? ""
            font.pointSize: Tokens.font.icon.large.pointSize
        }

        StyledText {
            anchors.left: glyph.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            text: root.modelData?.words ?? ""
            font: Tokens.font.body.medium
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
}
