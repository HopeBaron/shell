pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.launcher.services

Item {
    id: root

    required property var content
    required property ScreenState screenState
    required property var panels
    required property real maxHeight
    required property real maxWidth
    required property SearchBar search
    required property int padding
    required property int rounding

    readonly property bool showWallpapers: search.text.startsWith(`${GlobalConfig.launcher.actionPrefix}wallpaper `)
    // The clipboard is its own strip (a horizontal list); everything else is the vertical app list.
    // The clipboard strip is exactly as wide as the whole cards that fit, so no card is ever cut off.
    readonly property real stripCell: Tokens.sizes.launcher.itemHeight * 3.4
    readonly property real stripWidth: Math.max(1, Math.floor(Math.min(maxWidth, Tokens.sizes.launcher.itemWidth * 1.8) / stripCell)) * stripCell
    readonly property bool showClipboard: !showWallpapers && search.text.startsWith(`${GlobalConfig.launcher.actionPrefix}clipboard `)
    readonly property var currentList: showWallpapers ? wallpaperList.item : showClipboard ? clipList.item : appList.item // Can be either ListView or PathView, so can't type properly
    property string animState: showWallpapers ? "wallpapers" : showClipboard ? "clipboard" : "apps"

    // Clipboard mode: the highlighted entry, and room above the list to show it (a picture, or the text itself).
    readonly property var focusedClip: showClipboard ? clipList.item?.currentItem?.modelData ?? null : null
    readonly property bool showPreview: focusedClip !== null
    readonly property real previewBaseHeight: Tokens.sizes.launcher.itemHeight * 6
    // Expanded: the full width, and a bit taller (never past what the screen leaves after a few list rows).
    readonly property bool previewFull: showPreview && Clipboard.previewExpanded
    property real previewHeight: showPreview ? (Clipboard.previewExpanded ? Math.min(previewBaseHeight * 1.4, maxHeight - Tokens.sizes.launcher.itemHeight * 4) : previewBaseHeight) : 0

    onFocusedClipChanged: {
        if (focusedClip)
            Clipboard.preview(focusedClip);
        else
            Clipboard.previewExpanded = false;
    }

    Behavior on previewHeight {
        Anim {}
    }

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom

    clip: true
    state: animState

    states: [
        State {
            name: "apps"

            PropertyChanges {
                root.implicitWidth: root.previewFull ? root.maxWidth : root.Tokens.sizes.launcher.itemWidth
                root.implicitHeight: Math.min(root.maxHeight, (appList.implicitHeight > 0 ? appList.implicitHeight : empty.implicitHeight) + root.previewHeight)
                appList.active: true
            }

            AnchorChanges {
                anchors.left: root.parent.left
                anchors.right: root.parent.right
            }
        },
        State {
            name: "clipboard"

            PropertyChanges {
                root.implicitWidth: root.previewFull ? root.maxWidth : root.stripWidth
                root.implicitHeight: Math.min(root.maxHeight, (clipList.item?.implicitHeight ?? 0) + root.previewHeight)
                clipList.active: true
            }

            AnchorChanges {
                anchors.left: root.parent.left
                anchors.right: root.parent.right
            }
        },
        State {
            name: "wallpapers"

            PropertyChanges {
                root.implicitWidth: Math.max(root.Tokens.sizes.launcher.itemWidth * 1.2, wallpaperList.implicitWidth)
                root.implicitHeight: root.Tokens.sizes.launcher.wallpaperHeight
                wallpaperList.active: true
            }
        }
    ]

    Behavior on animState {
        SequentialAnimation {
            Anim {
                target: root
                property: "opacity"
                from: 1
                to: 0
                type: Anim.DefaultEffects
            }
            PropertyAction {}
            Anim {
                target: root
                property: "opacity"
                from: 0
                to: 1
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        id: appList

        active: false

        anchors.top: parent.top
        anchors.topMargin: root.previewHeight
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        sourceComponent: AppList {
            objectName: "launcherAppList"

            search: root.search
            screenState: root.screenState
        }
    }

    Loader {
        id: clipList

        active: false

        anchors.top: parent.top
        anchors.topMargin: root.previewHeight
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        sourceComponent: ClipboardStrip {
            objectName: "launcherClipboardStrip"

            search: root.search
            screenState: root.screenState
        }
    }

    // Preview of the focused clipboard image.
    ClippingRectangle {
        id: preview

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.small
        height: Math.max(0, root.previewHeight - Tokens.padding.small * 2)

        visible: root.previewHeight > 0
        opacity: root.showPreview && (root.focusedClip.image ? Clipboard.previewReady && Clipboard.previewId === root.focusedClip.id : Clipboard.previewTextId === root.focusedClip.id) ? 1 : 0
        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerHigh

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        // Expand / shrink the preview (also Ctrl+Space).
        StyledRect {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Tokens.padding.medium
            z: 1

            color: Qt.alpha(Colours.palette.m3surface, 0.7)
            radius: Tokens.rounding.full
            implicitWidth: expandIcon.implicitWidth + Tokens.padding.small * 2
            implicitHeight: implicitWidth

            MaterialIcon {
                id: expandIcon

                anchors.centerIn: parent
                text: Clipboard.previewExpanded ? "close_fullscreen" : "open_in_full"
                color: Colours.palette.m3onSurface
            }

            StateLayer {
                radius: Tokens.rounding.full
                onClicked: Clipboard.previewExpanded = !Clipboard.previewExpanded
            }
        }

        // A text clip: the start of it, cut with "…" where it no longer fits, so the area never changes size.
        StyledText {
            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            anchors.rightMargin: Tokens.padding.large + expandIcon.implicitWidth + Tokens.padding.medium
            visible: !(root.focusedClip?.image ?? false)

            text: Clipboard.previewText
            font: Tokens.font.body.medium
            wrapMode: Text.Wrap
            elide: Text.ElideRight
        }

        Image {
            anchors.fill: parent
            anchors.margins: Tokens.padding.small
            visible: root.focusedClip?.image ?? false
            source: Clipboard.previewSource
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: false
            sourceSize.width: width * 2
            sourceSize.height: height * 2
        }
    }

    Loader {
        id: wallpaperList

        asynchronous: true
        active: false

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        sourceComponent: WallpaperList {
            objectName: "launcherWallpaperList"

            search: root.search
            screenState: root.screenState
            panels: root.panels
            content: root.content
        }
    }

    Row {
        id: empty

        opacity: root.currentList?.count === 0 ? 1 : 0
        scale: root.currentList?.count === 0 ? 1 : 0.5

        spacing: Tokens.spacing.medium
        padding: Tokens.padding.large

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        MaterialIcon {
            text: root.state === "wallpapers" ? "wallpaper_slideshow" : "manage_search"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.extraLarge

            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                text: root.state === "wallpapers" ? Tr.tr("No wallpapers found") : Tr.tr("No results")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.builders.large.weight(Font.Medium).build()
            }

            StyledText {
                text: root.state === "wallpapers" && Wallpapers.list.length === 0 ? Tr.tr("Try putting some wallpapers in %1").arg(Paths.shortenHome(Paths.wallsdir)) : Tr.tr("Try searching for something else")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.medium
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on scale {
            Anim {}
        }
    }

    // The wheel flips the clipboard strip a row at a time, wherever it is over the launcher.
    MouseArea {
        anchors.fill: parent
        z: 10
        enabled: root.showClipboard
        acceptedButtons: Qt.NoButton
        onWheel: wheel => clipList.item?.flip(wheel.angleDelta.y < 0 ? 1 : -1)
    }

    Behavior on implicitWidth {
        enabled: root.screenState.launcher

        Anim {}
    }

    Behavior on implicitHeight {
        enabled: root.screenState.launcher

        Anim {}
    }
}
