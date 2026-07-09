import QtQuick
import QtQuick.Controls
import "root:/theme"
import Quickshell
import Quickshell.Io

Item {
    id: inputViewRoot
    anchors.fill: parent

    property var settingsWindow: null
    
    // Original configuration loaded from disk
    property var originalConfig: ({
        "kb_layout": "es",
        "accel_profile": "flat",
        "follow_mouse": 1,
        "sensitivity": 0.0,
        "natural_scroll": false
    })

    // Current values
    property string kbLayout: "es"
    property string accelProfile: "flat"
    property int followMouse: 1
    property double sensitivity: 0.0
    property bool naturalScroll: false

    onOriginalConfigChanged: {
        kbLayout = originalConfig.kb_layout;
        accelProfile = originalConfig.accel_profile;
        followMouse = originalConfig.follow_mouse;
        sensitivity = originalConfig.sensitivity;
        naturalScroll = originalConfig.natural_scroll;
    }

    // isDirty is dynamically evaluated by comparing current values with originalConfig!
    readonly property bool isDirty: (
        kbLayout !== originalConfig.kb_layout ||
        accelProfile !== originalConfig.accel_profile ||
        followMouse !== originalConfig.follow_mouse ||
        Math.abs(sensitivity - originalConfig.sensitivity) > 0.001 ||
        naturalScroll !== originalConfig.natural_scroll
    )

    // Load input settings on startup
    Process {
        id: loadInputProcess
        command: ["python3", Quickshell.env("HOME") + "/pro/dotfiles/theme/manage_input.py", "--get"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    let config = JSON.parse(data.trim());
                    originalConfig = {
                        "kb_layout": config.kb_layout || "es",
                        "accel_profile": config.accel_profile || "flat",
                        "follow_mouse": config.follow_mouse !== undefined ? config.follow_mouse : 1,
                        "sensitivity": config.sensitivity !== undefined ? parseFloat(config.sensitivity) : 0.0,
                        "natural_scroll": config.natural_scroll || false
                    };
                } catch(e) {
                    console.log("Error parsing input config: " + e);
                }
            }
        }
    }

    // Save input settings
    Process {
        id: saveInputProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                originalConfig = {
                    "kb_layout": kbLayout,
                    "accel_profile": accelProfile,
                    "follow_mouse": followMouse,
                    "sensitivity": sensitivity,
                    "natural_scroll": naturalScroll
                };
                if (settingsWindow) {
                    settingsWindow.hyprReloadProcess.running = true;
                }
            }
        }
    }

    function applyConfig() {
        let config = {
            "kb_layout": kbLayout,
            "accel_profile": accelProfile,
            "follow_mouse": followMouse,
            "sensitivity": sensitivity,
            "natural_scroll": naturalScroll
        };
        saveInputProcess.command = ["python3", Quickshell.env("HOME") + "/pro/dotfiles/theme/manage_input.py", "--save", JSON.stringify(config)];
        saveInputProcess.running = true;
    }

    // Pinned Apply Button at the bottom
    Rectangle {
        id: applyButton
        width: parent.width
        height: 36
        radius: 8
        anchors.bottom: parent.bottom
        color: isDirty 
            ? (applyMouse.containsMouse ? Theme.accent : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15))
            : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.02)
        border.color: isDirty ? Theme.accent : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: Theme.currentLang === "es" ? "Aplicar Cambios" : "Apply Changes"
            color: isDirty 
                ? (applyMouse.containsMouse ? Theme.bg : Theme.accent)
                : Theme.fgMuted
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.bold: true
        }

        MouseArea {
            id: applyMouse
            anchors.fill: parent
            hoverEnabled: isDirty
            cursorShape: isDirty ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (isDirty) {
                    applyConfig();
                }
            }
        }
    }

    // Column for everything else
    Column {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: applyButton.top
        anchors.bottomMargin: 14
        spacing: 16

        // Title and Subtitle
        Column {
            width: parent.width
            spacing: 2

            Text {
                text: Theme.currentLang === "es" ? "Entrada" : "Input"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
            }

            Text {
                text: Theme.currentLang === "es" ? "Configura tu teclado, ratón y comportamiento del cursor" : "Configure your keyboard, mouse, and cursor behavior"
                color: Theme.fgMuted
                font.family: Theme.fontFamily
                font.pixelSize: 9
            }
        }

        // Settings Blocks
        Column {
            width: parent.width
            spacing: 12

            // block 1: Mouse Sensitivity and Acceleration Profile
            Rectangle {
                width: parent.width
                height: 110
                radius: 12
                color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.01)
                border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Text {
                        text: Theme.currentLang === "es" ? "Configuración del Ratón" : "Mouse Configuration"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                    }

                    // Slider Sensitivity
                    Row {
                        width: parent.width
                        spacing: 12

                        Text {
                            text: Theme.currentLang === "es" ? "Sensibilidad:" : "Sensitivity:"
                            color: Theme.fgMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            width: 75
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Slider {
                            id: sensSlider
                            from: -1.0
                            to: 1.0
                            value: sensitivity
                            width: parent.width - 130
                            anchors.verticalCenter: parent.verticalCenter
                            onMoved: {
                                sensitivity = value;
                            }
                            background: Rectangle {
                                x: sensSlider.leftPadding
                                y: sensSlider.topPadding + sensSlider.availableHeight / 2 - height / 2
                                implicitWidth: 200
                                implicitHeight: 4
                                width: sensSlider.availableWidth
                                height: implicitHeight
                                radius: 2
                                color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)

                                Rectangle {
                                    width: sensSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: Theme.accent
                                    radius: 2
                                }
                            }
                            handle: Rectangle {
                                x: sensSlider.leftPadding + sensSlider.visualPosition * (sensSlider.availableWidth - width)
                                y: sensSlider.topPadding + sensSlider.availableHeight / 2 - height / 2
                                implicitWidth: 14
                                implicitHeight: 14
                                radius: 7
                                color: Theme.accent
                                border.color: Theme.bg
                                border.width: 2
                            }
                        }

                        Text {
                            text: sensitivity.toFixed(2)
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: true
                            width: 30
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    // Accel Profile
                    Row {
                        width: parent.width
                        spacing: 12

                        Text {
                            text: Theme.currentLang === "es" ? "Perfil Acel.:" : "Accel Profile:"
                            color: Theme.fgMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            width: 75
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Row {
                            spacing: 6
                            anchors.verticalCenter: parent.verticalCenter

                            Repeater {
                                model: ["adaptive", "flat", "none"]

                                delegate: Rectangle {
                                    width: 70
                                    height: 24
                                    radius: 6
                                    color: accelProfile === modelData
                                        ? Theme.accent
                                        : (accelMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05) : Qt.rgba(1,1,1,0.02))
                                    border.color: accelProfile === modelData
                                        ? "transparent"
                                        : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                        color: accelProfile === modelData ? Theme.bg : Theme.fg
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 8
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: accelMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            accelProfile = modelData;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // block 2: Follow Mouse Behavior
            Rectangle {
                width: parent.width
                height: 75
                radius: 12
                color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.01)
                border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        text: Theme.currentLang === "es" ? "Comportamiento de Enfoque" : "Focus Behavior"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                    }

                    Row {
                        width: parent.width
                        spacing: 12

                        Text {
                            text: Theme.currentLang === "es" ? "Foco cursor:" : "Follow mouse:"
                            color: Theme.fgMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            width: 75
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Row {
                            spacing: 6
                            anchors.verticalCenter: parent.verticalCenter

                            Repeater {
                                model: [
                                    { "value": 1, "name": Theme.currentLang === "es" ? "Estándar" : "Standard" },
                                    { "value": 2, "name": Theme.currentLang === "es" ? "Al click" : "On click" },
                                    { "value": 0, "name": "Manual" },
                                    { "value": 3, "name": Theme.currentLang === "es" ? "Estricto" : "Strict" }
                                ]

                                delegate: Rectangle {
                                    width: 75
                                    height: 24
                                    radius: 6
                                    color: followMouse === modelData.value
                                        ? Theme.accent
                                        : (followMouseMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05) : Qt.rgba(1,1,1,0.02))
                                    border.color: followMouse === modelData.value
                                        ? "transparent"
                                        : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.name
                                        color: followMouse === modelData.value ? Theme.bg : Theme.fg
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 8
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: followMouseMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            followMouse = modelData.value;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // block 3: Keyboard Layout & Touchpad Switch
            Row {
                width: parent.width
                spacing: 12

                // Keyboard Layout
                Rectangle {
                    width: parent.width * 0.48
                    height: 80
                    radius: 12
                    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.01)
                    border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Text {
                            text: Theme.currentLang === "es" ? "Distribución del Teclado" : "Keyboard Layout"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                        }

                        Row {
                            width: parent.width
                            spacing: 8
                            anchors.verticalCenter: parent.verticalCenter

                            TextField {
                                id: layoutInput
                                text: kbLayout
                                placeholderText: "es"
                                width: 50
                                height: 26
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                horizontalAlignment: Text.AlignHCenter
                                background: Rectangle {
                                    color: Qt.rgba(1,1,1,0.02)
                                    border.color: layoutInput.activeFocus ? Theme.accent : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
                                    border.width: 1
                                    radius: 6
                                }
                                onTextChanged: {
                                    kbLayout = text.trim();
                                }
                            }

                            Text {
                                text: Theme.currentLang === "es" ? "Ej: 'es', 'us'" : "E.g. 'es', 'us'"
                                color: Theme.fgMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 8
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                // Touchpad Options
                Rectangle {
                    width: parent.width * 0.49
                    height: 80
                    radius: 12
                    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.01)
                    border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Text {
                            text: Theme.currentLang === "es" ? "Panel Táctil (Touchpad)" : "Touchpad"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                        }

                        // iOS Switch for Natural Scroll
                        Row {
                            width: parent.width
                            spacing: 8
                            
                            Text {
                                text: Theme.currentLang === "es" ? "Desplazamiento Natural:" : "Natural Scroll:"
                                color: Theme.fgMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Item {
                                width: 1
                                height: 1
                            }

                            // iOS Switch
                            Rectangle {
                                width: 34
                                height: 20
                                radius: 10
                                color: naturalScroll ? Theme.accent : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
                                anchors.verticalCenter: parent.verticalCenter

                                Behavior on color { ColorAnimation { duration: 120 } }

                                Rectangle {
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: Theme.bg
                                    x: naturalScroll ? 16 : 2
                                    anchors.verticalCenter: parent.verticalCenter

                                    Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        naturalScroll = !naturalScroll;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
