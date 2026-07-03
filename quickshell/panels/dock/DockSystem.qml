import QtQuick
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import "root:/theme"

Item {
    implicitWidth: systemRow.implicitWidth
    implicitHeight: systemRow.implicitHeight

    Row {
        id: systemRow
        spacing: 20
        anchors.verticalCenter: parent.verticalCenter

        Column {
            width: 140
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter

            Row {
                spacing: 6
                Text {
                    text: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio.muted ? "\uf6a9" : "\uf028"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: Theme.t.volume ?? "Vol"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.bold: true
                    color: Theme.fg
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: Pipewire.defaultAudioSink ? Math.round(Pipewire.defaultAudioSink.audio.volume * 100) + "%" : "0%"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: Theme.fgMuted
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle {
                width: parent.width
                height: 6
                radius: 3
                color: Theme.bgAlt

                Rectangle {
                    width: parent.width * (Pipewire.defaultAudioSink ? Math.min(1.0, Pipewire.defaultAudioSink.audio.volume) : 0.0)
                    height: parent.height
                    radius: parent.radius
                    color: Theme.accent
                }

                MouseArea {
                    anchors.fill: parent

                    function updateVol(mouse) {
                        let ratio = Math.max(0.0, Math.min(1.0, mouse.x / width));
                        if (Pipewire.defaultAudioSink) {
                            Pipewire.defaultAudioSink.audio.volume = ratio;
                        }
                    }

                    onPositionChanged: mouse => updateVol(mouse)
                    onPressed: mouse => updateVol(mouse)
                }
            }
        }

        // Separator
        Rectangle {
            width: 1
            height: 24
            color: Theme.bgAlt
            anchors.verticalCenter: parent.verticalCenter
        }

        // Battery Status
        Column {
            width: 100
            spacing: 3
            anchors.verticalCenter: parent.verticalCenter

            Row {
                spacing: 6
                Text {
                    text: UPower.displayDevice && UPower.displayDevice.state === 1 ? "\uf0e7" : "\uf240"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: UPower.displayDevice && UPower.displayDevice.state === 1 ? Theme.green : Theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: UPower.displayDevice ? Math.round(UPower.displayDevice.percentage) + "%" : "N/A"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.fg
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Text {
                text: {
                    if (!UPower.displayDevice) return Theme.t.battery_not_found ?? "Unknown";
                    let state = UPower.displayDevice.state;
                    if (state === 1) return Theme.t.charging ?? "Charging";
                    if (state === 2) return Theme.t.discharging ?? "Discharging";
                    return Theme.t.battery ?? "Battery";
                }
                font.family: Theme.fontFamily
                font.pixelSize: 9
                color: Theme.fgMuted
            }
        }
    }
}
