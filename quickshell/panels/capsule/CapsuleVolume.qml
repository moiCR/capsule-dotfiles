import QtQuick
import Quickshell.Services.Pipewire
import "root:/theme"

Item {
    implicitWidth: 250
    implicitHeight: 18

    Row {
        anchors.fill: parent
        spacing: 12

        Text {
            id: volIcon
            text: {
                if (!Pipewire.defaultAudioSink) return "\uf026";
                if (Pipewire.defaultAudioSink.audio.muted) return "\uf6a9";
                let v = Pipewire.defaultAudioSink.audio.volume;
                if (v === 0) return "\uf026";
                if (v < 0.3) return "\uf027";
                return "\uf028";
            }
            font.family: Theme.fontFamily
            font.pixelSize: 13
            color: Theme.accent
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: parent.width - volIcon.implicitWidth - volText.implicitWidth - parent.spacing * 2
            height: 8
            radius: 4
            color: Theme.bgAlt
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                width: parent.width * (Pipewire.defaultAudioSink ? Math.min(1.0, Pipewire.defaultAudioSink.audio.volume) : 0.0)
                height: parent.height
                radius: parent.radius
                color: Theme.accent
            }
        }

        Text {
            id: volText
            text: Pipewire.defaultAudioSink ? Math.round(Pipewire.defaultAudioSink.audio.volume * 100) + "%" : "0%"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.bold: true
            color: "#ffffff"
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
