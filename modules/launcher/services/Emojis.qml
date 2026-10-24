pragma Singleton

import ".."
import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.utils

// Emoji list for the launcher's "emojis" mode, from `caelestia emoji` ("<glyph> <search words>" per line).
// Picking one copies it to the clipboard.
Searcher {
    id: root

    property var entries: []
    property bool loaded

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}emojis `.length);
    }

    function load(): void {
        if (!loaded && !getList.running)
            getList.running = true;
    }

    list: items.instances
    key: "words"

    Variants {
        id: items

        model: root.entries

        Emoji {}
    }

    Process {
        id: getList

        command: ["caelestia", "emoji"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const space = line.indexOf(" ");
                    if (space < 1)
                        continue;
                    out.push({
                        glyph: line.slice(0, space),
                        words: line.slice(space + 1)
                    });
                }
                root.entries = out;
                root.loaded = out.length > 0;
            }
        }
    }

    component Emoji: QtObject {
        required property var modelData
        readonly property string glyph: modelData.glyph
        readonly property string words: modelData.words

        function onClicked(list: AppList): void {
            list.screenState.launcher = false;
            Quickshell.execDetached(["wl-copy", "--", glyph]);
        }
    }
}
