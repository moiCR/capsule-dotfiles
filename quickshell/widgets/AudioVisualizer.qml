import QtQuick
import Quickshell.Io
import "root:/theme"

Rectangle {
    id: visualizerBox

    width: 90
    height: 24
    radius: 8
    
    // OLED black box with accent border highlight
    color: "#000000"
    border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
    border.width: 1

    property int numBars: 10
    property var barHeights: []
    property bool audioActive: false

    Component.onCompleted: {
        let temp = [];
        for (let i = 0; i < numBars; i++) {
            temp.push(2);
        }
        barHeights = temp;
    }

    Process {
        id: checkAudioProcess
        command: ["sh", "-c", "while true; do pactl list sink-inputs | grep -q 'Corked: no' && echo 1 || echo 0; sleep 0.2; done"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                visualizerBox.audioActive = (data.trim() === "1");
            }
        }
    }

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            let temp = [];
            for (let i = 0; i < numBars; i++) {
                if (visualizerBox.audioActive) {
                    // Generate bouncing visualizer heights when sound is playing
                    temp.push(3 + Math.random() * 14);
                } else {
                    // Default flat line (2px height) when idle
                    temp.push(2);
                }
            }
            barHeights = temp;
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 3
        height: 16

        Repeater {
            model: visualizerBox.numBars

            delegate: Rectangle {
                width: 3
                height: (visualizerBox.barHeights && visualizerBox.barHeights.length > index) ? visualizerBox.barHeights[index] : 2
                radius: 1.5
                anchors.bottom: parent.bottom
                
                // Colors match current accent theme
                color: Theme.accent
                
                Behavior on height {
                    NumberAnimation {
                        duration: 90
                        easing.type: Easing.OutBack
                    }
                }
            }
        }
    }
}
