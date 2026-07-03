import QtQuick
import Quickshell.Io
import "root:/theme"

Rectangle {
    id: visualizerBox

    property bool isVertical: Theme.barPosition === "left" || Theme.barPosition === "right"
    property bool showBox: true

    width: showBox ? (isVertical ? 40 : 90) : (numBars * 2 + (numBars - 1) * 2)
    height: showBox ? 24 : 12
    radius: 8
    
    implicitWidth: width
    implicitHeight: height

    // OLED black box with accent border highlight
    color: showBox ? "#000000" : "transparent"
    border.color: showBox ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25) : "transparent"
    border.width: showBox ? 1 : 0

    property int numBars: isVertical ? 5 : 10
    property var barHeights: []
    property bool audioActive: false
    property color barColor: Theme.accent

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
        id: visualizerTimer
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            let temp = [];
            let maxH = showBox ? 14 : 10; // lower height in compact mode
            for (let i = 0; i < numBars; i++) {
                if (visualizerBox.audioActive) {
                    temp.push(2 + Math.random() * maxH);
                } else {
                    temp.push(2);
                }
            }
            barHeights = temp;
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 2
        height: showBox ? 16 : 12

        Repeater {
            model: visualizerBox.numBars

            delegate: Rectangle {
                width: 2
                height: (visualizerBox.barHeights && visualizerBox.barHeights.length > index) ? visualizerBox.barHeights[index] : 2
                radius: 1
                anchors.bottom: parent.bottom
                
                color: visualizerBox.barColor
                
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
