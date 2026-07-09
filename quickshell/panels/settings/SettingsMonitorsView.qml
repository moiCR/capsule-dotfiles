import QtQuick
import QtQuick.Controls
import "root:/theme"
import Quickshell
import Quickshell.Io

Item {
    id: monitorsViewRoot
    anchors.fill: parent

    property var settingsWindow: null
    property var monitorsList: []
    property string monitorsBuffer: ""
    property int selectedIndex: 0
    property string originalMonitorsJson: ""

    // isDirty is dynamically evaluated by comparing current settings with original settings
    readonly property bool isDirty: {
        if (originalMonitorsJson === "") return false;
        
        let currentList = [];
        for (let i = 0; i < monitorsList.length; i++) {
            let m = monitorsList[i];
            currentList.push({
                "output": m.name,
                "mode": m.width + "x" + m.height + "@" + Math.round(m.refreshRate),
                "position": m.x + "x" + m.y,
                "scale": m.scale.toString()
            });
        }
        
        return JSON.stringify(currentList) !== originalMonitorsJson;
    }

    // 1. Process to load monitors info from hyprctl
    Process {
        id: loadMonitorsProcess
        command: ["hyprctl", "monitors", "-j"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                monitorsBuffer += data;
            }
        }
        onExited: (exitCode, exitStatus) => {
            try {
                let parsed = JSON.parse(monitorsBuffer.trim());
                // Sort left-to-right based on x position
                parsed.sort((a, b) => a.x - b.x);
                monitorsList = parsed;
                
                // Keep selectedIndex in bounds
                if (selectedIndex >= parsed.length) {
                    selectedIndex = Math.max(0, parsed.length - 1);
                }

                // Generate and save original config representation
                let orig = [];
                for (let i = 0; i < parsed.length; i++) {
                    let m = parsed[i];
                    orig.push({
                        "output": m.name,
                        "mode": m.width + "x" + m.height + "@" + Math.round(m.refreshRate),
                        "position": m.x + "x" + m.y,
                        "scale": m.scale.toString()
                    });
                }
                originalMonitorsJson = JSON.stringify(orig);
            } catch(e) {
                console.log("Error parsing monitors: " + e);
            }
            monitorsBuffer = "";
        }
    }

    // 2. Process to save monitors using our Python helper
    Process {
        id: saveProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                if (settingsWindow) {
                    settingsWindow.hyprReloadProcess.running = true;
                }
                // Reload list to get fresh compositor values
                loadMonitorsProcess.running = true;
            }
        }
    }

    // Helpers
    function isCurrentMode(modeStr, m) {
        let match = modeStr.match(/^(\d+)x(\d+)@([\d.]+)Hz/);
        if (!match) return false;
        let w = parseInt(match[1]);
        let h = parseInt(match[2]);
        let hz = parseFloat(match[3]);
        return (w === m.width && h === m.height && Math.abs(hz - m.refreshRate) < 1.0);
    }

    function selectMode(modeStr) {
        let match = modeStr.match(/^(\d+)x(\d+)@([\d.]+)Hz/);
        if (!match) return;
        
        let list = [...monitorsList];
        let m = list[selectedIndex];
        
        let newW = parseInt(match[1]);
        let newH = parseInt(match[2]);
        let newHz = parseFloat(match[3]);

        if (m.width !== newW || m.height !== newH || Math.abs(m.refreshRate - newHz) > 0.5) {
            m.width = newW;
            m.height = newH;
            m.refreshRate = newHz;
            monitorsList = list;
        }
    }

    function selectScale(scaleVal) {
        let list = [...monitorsList];
        let m = list[selectedIndex];
        if (parseFloat(m.scale) !== scaleVal) {
            m.scale = scaleVal;
            monitorsList = list;
            // Recalculate layout coordinates immediately because scale affects visual width!
            recalculatePositions();
        }
    }

    function moveLeft(index) {
        if (index <= 0) return;
        let list = [...monitorsList];
        let temp = list[index];
        list[index] = list[index - 1];
        list[index - 1] = temp;
        monitorsList = list;
        recalculatePositions();
    }

    function moveRight(index) {
        if (index >= monitorsList.length - 1) return;
        let list = [...monitorsList];
        let temp = list[index];
        list[index] = list[index + 1];
        list[index + 1] = temp;
        monitorsList = list;
        recalculatePositions();
    }

    function recalculatePositions() {
        let currentX = 0;
        let list = [...monitorsList];
        for (let i = 0; i < list.length; i++) {
            let m = list[i];
            let width = m.width;
            let scale = parseFloat(m.scale) || 1.0;
            let layoutWidth = Math.round(width / scale);
            
            m.x = currentX;
            m.y = 0;
            currentX += layoutWidth;
        }
        monitorsList = list;
    }

    function applyConfig() {
        let updatedList = [];
        for (let i = 0; i < monitorsList.length; i++) {
            let m = monitorsList[i];
            updatedList.push({
                "output": m.name,
                "mode": m.width + "x" + m.height + "@" + Math.round(m.refreshRate),
                "position": m.x + "x" + m.y,
                "scale": m.scale.toString()
            });
        }
        
        saveProcess.command = ["python3", Quickshell.env("HOME") + "/pro/dotfiles/theme/manage_monitors.py", "--save", JSON.stringify(updatedList)];
        saveProcess.running = true;
    }

    // Layout
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
        spacing: 14

        // Title and Subtitle
        Column {
            width: parent.width
            spacing: 2

            Text {
                text: Theme.currentLang === "es" ? "Pantallas" : "Displays"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
            }

            Text {
                text: Theme.currentLang === "es" ? "Disposición visual de pantallas y configuración" : "Visual screen layout and configuration"
                color: Theme.fgMuted
                font.family: Theme.fontFamily
                font.pixelSize: 9
            }
        }

        // 1. Visual Layout Representation
        Rectangle {
            width: parent.width
            height: 125
            radius: 12
            color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.02)
            border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)
            border.width: 1

            // Helper text if empty
            Text {
                text: Theme.currentLang === "es" ? "Buscando pantallas..." : "Searching displays..."
                color: Theme.fgMuted
                font.family: Theme.fontFamily
                font.pixelSize: 10
                anchors.centerIn: parent
                visible: monitorsList.length === 0
            }

            Row {
                anchors.centerIn: parent
                spacing: 12
                visible: monitorsList.length > 0

                Repeater {
                    model: monitorsList

                    delegate: Rectangle {
                        id: monitorCard
                        // Proportional aspect ratio calculations
                        width: Math.max(100, Math.min(160, 120 * (modelData.width / 1920)))
                        height: width * (modelData.height / modelData.width)
                        radius: 8
                        color: selectedIndex === index 
                            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08)
                            : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.03)
                        border.color: selectedIndex === index ? Theme.accent : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.12)
                        border.width: selectedIndex === index ? 2 : 1
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: selectedIndex = index
                        }

                        // Inner Display mockup
                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            width: parent.width - 12

                            Text {
                                text: modelData.name
                                color: selectedIndex === index ? Theme.accent : Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                width: parent.width
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.width + "x" + modelData.height
                                color: Theme.fgMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 8
                                horizontalAlignment: Text.AlignHCenter
                                width: parent.width
                            }

                            Text {
                                text: Math.round(modelData.refreshRate) + "Hz"
                                color: Theme.fgMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 8
                                horizontalAlignment: Text.AlignHCenter
                                width: parent.width
                            }
                        }

                        // Arrow Controls Overlay (Visible if multiple monitors exist)
                        Row {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 4
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8
                            visible: monitorsList.length > 1

                            // Move Left
                            Text {
                                text: "\uf060"
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                color: (index > 0) ? (leftArrowMouse.containsMouse ? Theme.accent : Theme.fgMuted) : "transparent"
                                visible: index > 0

                                MouseArea {
                                    id: leftArrowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: moveLeft(index)
                                }
                            }

                            // Move Right
                            Text {
                                text: "\uf061"
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                color: (index < monitorsList.length - 1) ? (rightArrowMouse.containsMouse ? Theme.accent : Theme.fgMuted) : "transparent"
                                visible: index < monitorsList.length - 1

                                MouseArea {
                                    id: rightArrowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: moveRight(index)
                                }
                            }
                        }
                    }
                }
            }
        }

        // 2. Settings configuration form (Shown only when screen is selected)
        Row {
            width: parent.width
            height: 200
            spacing: 16
            visible: monitorsList.length > 0

            // Left Column: Details & Scale
            Column {
                width: parent.width * 0.45
                spacing: 12
                anchors.top: parent.top

                // Display info card
                Rectangle {
                    width: parent.width
                    height: 60
                    radius: 8
                    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.01)
                    border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05)
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 2

                        Text {
                            text: monitorsList[selectedIndex] ? monitorsList[selectedIndex].description : ""
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: "Output: " + (monitorsList[selectedIndex] ? monitorsList[selectedIndex].name : "") + " | Pos: " + (monitorsList[selectedIndex] ? (monitorsList[selectedIndex].x + ", " + monitorsList[selectedIndex].y) : "0, 0")
                            color: Theme.fgMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 8
                        }
                        
                        Text {
                            text: monitorsList[selectedIndex] && monitorsList[selectedIndex].focused ? (Theme.currentLang === "es" ? "Pantalla Focalizada (Principal)" : "Focused Display (Primary)") : ""
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: 8
                            font.bold: true
                        }
                    }
                }

                // Scale Selection
                Column {
                    width: parent.width
                    spacing: 6

                    Text {
                        text: Theme.currentLang === "es" ? "Escala / Scale:" : "Scale / Zoom:"
                        color: Theme.fgMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                    }

                    Row {
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: [1.0, 1.25, 1.5, 2.0]

                            delegate: Rectangle {
                                width: (parent.width - 18) / 4
                                height: 26
                                radius: 6
                                color: (monitorsList[selectedIndex] && parseFloat(monitorsList[selectedIndex].scale) === modelData)
                                    ? Theme.accent
                                    : (scaleMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05) : Qt.rgba(1,1,1,0.02))
                                border.color: (monitorsList[selectedIndex] && parseFloat(monitorsList[selectedIndex].scale) === modelData)
                                    ? "transparent"
                                    : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.toFixed(2)
                                    color: (monitorsList[selectedIndex] && parseFloat(monitorsList[selectedIndex].scale) === modelData) ? Theme.bg : Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    font.bold: true
                                }

                                MouseArea {
                                    id: scaleMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: selectScale(modelData)
                                }
                            }
                        }
                    }
                }
            }

            // Vertical separator
            Rectangle {
                width: 1
                height: parent.height - 20
                color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)
                anchors.verticalCenter: parent.verticalCenter
            }

            // Right Column: Available Modes List (Scrollable)
            Column {
                width: parent.width * 0.51
                spacing: 6
                anchors.top: parent.top

                Text {
                    text: Theme.currentLang === "es" ? "Modos y Tasas de Refresco:" : "Resolution & Refresh Rates:"
                    color: Theme.fgMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                }

                Rectangle {
                    width: parent.width
                    height: 140
                    radius: 8
                    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.01)
                    border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05)
                    border.width: 1
                    clip: true

                    ListView {
                        id: modesListView
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 2
                        model: monitorsList[selectedIndex] ? monitorsList[selectedIndex].availableModes : []

                        delegate: Rectangle {
                            id: modeItem
                            width: ListView.view.width
                            height: 26
                            radius: 4
                            color: isCurrentMode(modelData, monitorsList[selectedIndex])
                                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
                                : (modeMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.04) : "transparent")
                            border.color: isCurrentMode(modelData, monitorsList[selectedIndex]) ? Theme.accent : "transparent"
                            border.width: 1

                            Row {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 8

                                Text {
                                    text: "\uf00c"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    color: Theme.accent
                                    visible: isCurrentMode(modelData, monitorsList[selectedIndex])
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: modelData
                                    color: isCurrentMode(modelData, monitorsList[selectedIndex]) ? Theme.accent : Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    font.bold: isCurrentMode(modelData, monitorsList[selectedIndex])
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: modeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: selectMode(modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
