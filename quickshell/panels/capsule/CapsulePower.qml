import QtQuick
import Quickshell
import Quickshell.Io
import "root:/theme"

Item {
    id: powerWrapper

    implicitWidth: 420
    implicitHeight: 130

    focus: true
    Component.onCompleted: powerWrapper.forceActiveFocus()
    Keys.onEscapePressed: capsule.currentMode = "default"

    property bool hasEPP: false
    property string currentEPP: "unknown"
    property string currentGov: "unknown"
    property string activePlan: "unknown" // "performance", "balanced", "powersave"

    // Process to read current governor / EPP
    Process {
        id: checkGovProcess
        command: ["sh", "-c", "if [ -f /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference ]; then echo 'epp'; cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference; else echo 'gov'; cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor; fi"]
        running: true
        stdout: SplitParser {
            property string parseMode: ""
            onRead: (data) => {
                let txt = data.trim();
                if (!txt) return;
                if (txt === "epp" || txt === "gov") {
                    parseMode = txt;
                } else {
                    if (parseMode === "epp") {
                        hasEPP = true;
                        currentEPP = txt;
                        if (txt === "performance") {
                            activePlan = "performance";
                        } else if (txt === "power" || txt === "balance_power") {
                            activePlan = "powersave";
                        } else {
                            activePlan = "balanced";
                        }
                    } else {
                        hasEPP = false;
                        currentGov = txt;
                        if (txt === "performance") {
                            activePlan = "performance";
                        } else {
                            activePlan = "powersave";
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: capsule
        function onPowerCommandFinished() {
            checkGovProcess.running = true;
        }
    }

    Timer {
        id: refreshTimer
        interval: 3000
        running: true
        repeat: true
        onTriggered: checkGovProcess.running = true
    }

    Column {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 16
        anchors.bottomMargin: 16
        spacing: 12

        // ── Header ──────────────────────────────────────────────────────────
        Item {
            width: parent.width
            height: 20

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    text: "\uf0e7" // Bolt
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: Theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: Theme.currentLang === "es" ? "Plan de Energía" : "Power Plan"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.fg
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Current Active Badge
                Rectangle {
                    height: 16
                    width: govText.implicitWidth + 12
                    radius: 8
                    color: {
                        if (activePlan === "performance") return Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.15);
                        if (activePlan === "balanced") return Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15);
                        return Qt.rgba(Theme.green.r, Theme.green.g, Theme.green.b, 0.15);
                    }
                    border.width: 1
                    border.color: {
                        if (activePlan === "performance") return Theme.red;
                        if (activePlan === "balanced") return Theme.accent;
                        return Theme.green;
                    }
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        id: govText
                        anchors.centerIn: parent
                        text: {
                            if (activePlan === "performance") return Theme.currentLang === "es" ? "RENDIMIENTO" : "PERFORMANCE";
                            if (activePlan === "balanced") return Theme.currentLang === "es" ? "EQUILIBRADO" : "BALANCED";
                            return Theme.currentLang === "es" ? "AHORRO" : "POWERSAVE";
                        }
                        font.family: Theme.fontFamily
                        font.pixelSize: 8
                        font.bold: true
                        color: {
                            if (activePlan === "performance") return Theme.red;
                            if (activePlan === "balanced") return Theme.accent;
                            return Theme.green;
                        }
                    }
                }
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "\uf00d"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: closeMouse.containsMouse ? Theme.red : Theme.fgMuted
                Behavior on color { ColorAnimation { duration: 120 } }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: capsule.currentMode = "default"
                }
            }
        }

        // ── Separator ───────────────────────────────────────────────────────
        Rectangle {
            width: parent.width
            height: 1
            color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.6)
        }

        // ── Governor Buttons Row ────────────────────────────────────────────
        Row {
            width: parent.width
            height: 40
            spacing: 8

            // 1. powersave button
            Rectangle {
                width: (parent.width - 16) / 3
                height: parent.height
                radius: 10
                color: activePlan === "powersave"
                    ? Qt.rgba(Theme.green.r, Theme.green.g, Theme.green.b, 0.15)
                    : (saveMouse.containsMouse ? Qt.rgba(1,1,1,0.06) : Qt.rgba(1,1,1,0.03))
                border.width: activePlan === "powersave" ? 1.5 : 1
                border.color: activePlan === "powersave" ? Theme.green : Qt.rgba(1,1,1,0.08)

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "\uf06c" // Leaf
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: activePlan === "powersave" ? Theme.green : Theme.fg
                    }

                    Text {
                        text: Theme.currentLang === "es" ? "Ahorro" : "Powersave"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: activePlan === "powersave"
                        color: activePlan === "powersave" ? Theme.green : Theme.fg
                    }
                }

                MouseArea {
                    id: saveMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (hasEPP) {
                            capsule.runPowerCommand(["pkexec", "cpupower", "set", "-e", "power"]);
                        } else {
                            capsule.runPowerCommand(["pkexec", "cpupower", "frequency-set", "-g", "powersave"]);
                        }
                    }
                }
            }

            // 2. balanced button
            Rectangle {
                width: (parent.width - 16) / 3
                height: parent.height
                radius: 10
                enabled: hasEPP // Disabled if EPP is not supported
                opacity: hasEPP ? 1.0 : 0.4
                color: activePlan === "balanced"
                    ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
                    : (balMouse.containsMouse ? Qt.rgba(1,1,1,0.06) : Qt.rgba(1,1,1,0.03))
                border.width: activePlan === "balanced" ? 1.5 : 1
                border.color: activePlan === "balanced" ? Theme.accent : Qt.rgba(1,1,1,0.08)

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "\uf2db" // Microchip
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: activePlan === "balanced" ? Theme.accent : Theme.fg
                    }

                    Text {
                        text: Theme.currentLang === "es" ? "Equilibrado" : "Balanced"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: activePlan === "balanced"
                        color: activePlan === "balanced" ? Theme.accent : Theme.fg
                    }
                }

                MouseArea {
                    id: balMouse
                    anchors.fill: parent
                    hoverEnabled: hasEPP
                    cursorShape: hasEPP ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (hasEPP) {
                            capsule.runPowerCommand(["pkexec", "cpupower", "set", "-e", "balance_performance"]);
                        }
                    }
                }
            }

            // 3. performance button
            Rectangle {
                width: (parent.width - 16) / 3
                height: parent.height
                radius: 10
                color: activePlan === "performance"
                    ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.15)
                    : (perfMouse.containsMouse ? Qt.rgba(1,1,1,0.06) : Qt.rgba(1,1,1,0.03))
                border.width: activePlan === "performance" ? 1.5 : 1
                border.color: activePlan === "performance" ? Theme.red : Qt.rgba(1,1,1,0.08)

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "\uf0e4" // Tachometer
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: activePlan === "performance" ? Theme.red : Theme.fg
                    }

                    Text {
                        text: Theme.currentLang === "es" ? "Rendimiento" : "Performance"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: activePlan === "performance"
                        color: activePlan === "performance" ? Theme.red : Theme.fg
                    }
                }

                MouseArea {
                    id: perfMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (hasEPP) {
                            capsule.runPowerCommand(["pkexec", "cpupower", "set", "-e", "performance"]);
                        } else {
                            capsule.runPowerCommand(["pkexec", "cpupower", "frequency-set", "-g", "performance"]);
                        }
                    }
                }
            }
        }
    }
}
