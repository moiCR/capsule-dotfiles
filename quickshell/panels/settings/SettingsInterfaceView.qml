import QtQuick
import QtQuick.Controls
import "root:/theme"
import Quickshell
import Quickshell.Io

Item {
    id: interfaceViewRoot
    anchors.fill: parent

    property var settingsWindow: null

    // State properties for the sliding keybind drawer
    property bool showDrawer: false
    property bool isEditMode: false
    property string oldKeys: ""
    property string newKeys: ""
    property string newCmd: ""

    // "cmd" or "app" binding type selection
    property string bindType: "cmd"

    // Key recording state
    property bool isRecording: false

    // Loaded applications from desktop files
    property var appsList: []
    property string appsBuffer: ""

    Process {
        id: listAppsProcess
        command: ["python3", Quickshell.env("HOME") + "/pro/dotfiles/theme/list_apps.py"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                appsBuffer += data;
            }
        }
        onExited: (exitCode, exitStatus) => {
            try {
                appsList = JSON.parse(appsBuffer.trim());
            } catch(e) {
                console.log("Error parsing apps list: " + e);
            }
            appsBuffer = "";
        }
    }

    Process {
        id: manageBindsProcess
        onExited: (exitCode, exitStatus) => {
            if (settingsWindow) {
                settingsWindow.keybindsFile.reload();
                settingsWindow.hyprReloadProcess.running = true;
            }
            showDrawer = false;
        }
    }

    Process {
        id: blockBindsProcess
        command: ["hyprctl", "eval", "hl.dispatch(hl.dsp.submap(\"clean\"))"]
    }

    Process {
        id: unblockBindsProcess
        command: ["hyprctl", "eval", "hl.dispatch(hl.dsp.submap(\"reset\"))"]
    }

    // Main Column Content (Smoothly shrinks to the left when drawer opens)
    Item {
        id: mainContentContainer
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: showDrawer ? 270 : 0

        Behavior on anchors.rightMargin {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        Column {
            anchors.fill: parent
            spacing: 20

            // 1. Header and Add Button
            Item {
                width: parent.width
                height: 32

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        text: "\uf11c" // Keyboard icon
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: Theme.accent
                    }

                    Text {
                        text: Theme.currentLang === "es" ? "Atajos de Teclado" : "Keyboard Shortcuts"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                    }
                }

                // Modern Add Button
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 90
                    height: 28
                    radius: 8
                    color: addBindMouse.containsMouse ? Theme.accent : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
                    border.color: Theme.accent
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { 
                            text: "\uf067" // Plus icon
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true 
                            color: addBindMouse.containsMouse ? Theme.bg : Theme.accent 
                        }
                        Text {
                            text: Theme.currentLang === "es" ? "Nuevo" : "New"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            color: addBindMouse.containsMouse ? Theme.bg : Theme.accent
                        }
                    }

                    MouseArea {
                        id: addBindMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            isEditMode = false;
                            bindType = "cmd";
                            newKeys = "";
                            newCmd = "";
                            showDrawer = true;
                        }
                    }
                }
            }

            // 2. Keybinds List
            Rectangle {
                width: parent.width
                height: parent.height - 110 // Remaining height
                color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.02)
                radius: 12
                border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)
                border.width: 1
                clip: true

                ListView {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6
                    model: settingsWindow ? settingsWindow.keybindsList : []

                    delegate: Rectangle {
                        id: bindItem
                        required property var modelData
                        width: ListView.view.width
                        height: 38
                        radius: 8
                        
                        color: itemMouse.containsMouse 
                            ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.04) 
                            : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.01)
                        border.color: itemMouse.containsMouse 
                            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15) 
                            : "transparent"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        // Shortcut Badge/Pill on the left
                        Rectangle {
                            id: shortcutPill
                            width: 130
                            height: 24
                            radius: 6
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1)
                            border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2)
                            border.width: 1
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: modelData.keys
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                                elide: Text.ElideRight
                                width: parent.width - 12
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        // Description / Command Text
                        Text {
                            text: modelData.desc ?? modelData.command
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            anchors.left: shortcutPill.right
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.cmd) {
                                    isEditMode = true;
                                    oldKeys = modelData.keys;
                                    newKeys = modelData.keys;
                                    newCmd = modelData.cmd;

                                    // Detect if this command matches a known app executable
                                    let foundApp = false;
                                    for (let app of appsList) {
                                        if (app.exec === modelData.cmd) {
                                            foundApp = true;
                                            break;
                                        }
                                    }
                                    bindType = foundApp ? "app" : "cmd";
                                    showDrawer = true;
                                }
                            }
                        }
                    }
                }
            }

            // 3. Language Selector Row
            Item {
                width: parent.width
                height: 32

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        text: "\uf1ab" // Language icon
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.fgMuted
                    }

                    Text {
                        text: Theme.currentLang === "es" ? "Idioma del Sistema:" : "System Language:"
                        color: Theme.fgMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Repeater {
                        model: settingsWindow ? settingsWindow.languagesList : []

                        delegate: Rectangle {
                            required property var modelData
                            width: 76
                            height: 26
                            radius: 8
                            
                            color: Theme.currentLang === modelData.id 
                                ? Theme.accent 
                                : (langMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08) : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.02))
                            border.color: Theme.currentLang === modelData.id 
                                ? "transparent" 
                                : (langMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.15) : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05))
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.name
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: Theme.currentLang === modelData.id
                                color: Theme.currentLang === modelData.id ? Theme.bg : Theme.fg
                            }

                            MouseArea {
                                id: langMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (settingsWindow && Theme.currentLang !== modelData.id) {
                                        let jsonPath = Quickshell.env("HOME") + "/pro/dotfiles/theme/current.json";
                                        settingsWindow.langWriteProcess.command = ["python3", "-c", "import json; d = json.load(open('" + jsonPath + "')); d['lang'] = '" + modelData.id + "'; json.dump(d, open('" + jsonPath + "', 'w'), indent=2)"];
                                        settingsWindow.langWriteProcess.running = true;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // 4. Sliding Keybind Edit/Create Drawer (Solid Capsule Style Panel)
    Rectangle {
        id: rightDrawer
        width: 250
        height: parent.height
        radius: 12
        color: Theme.bg
        border.color: Theme.bgAlt
        border.width: 1

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: showDrawer ? 0 : -260

        Behavior on anchors.rightMargin {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        Item {
            anchors.fill: parent
            anchors.margins: 16

            // 1. Top Inputs Container
            Column {
                id: inputsColumn
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 12

                // Drawer Header
                Item {
                    width: parent.width
                    height: 24

                    Text {
                        text: isEditMode 
                            ? (Theme.currentLang === "es" ? "Editar Atajo" : "Edit Shortcut") 
                            : (Theme.currentLang === "es" ? "Nuevo Atajo" : "New Shortcut")
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Close Drawer Button
                    Text {
                        text: "\uf00d"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: drawerCloseMouse.containsMouse ? Theme.red : Theme.fgMuted
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        
                        MouseArea {
                            id: drawerCloseMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: showDrawer = false
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)
                }

                // Keys Recording Button / Display
                Column {
                    width: parent.width
                    spacing: 4

                    Text {
                        text: Theme.currentLang === "es" ? "Combinación de teclas (Haz clic para grabar):" : "Key Combination (Click to record):"
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        color: Theme.fgMuted
                    }

                    Rectangle {
                        id: recordButton
                        width: parent.width
                        height: 32
                        radius: 6
                        color: isRecording 
                            ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.12)
                            : (recordMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.06) : Qt.rgba(1,1,1,0.02))
                        border.color: isRecording 
                            ? Theme.red 
                            : (recordMouse.containsMouse ? Theme.accent : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08))
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            // Blinking dot when recording
                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                color: Theme.red
                                visible: isRecording
                                
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    running: isRecording
                                    NumberAnimation { from: 1.0; to: 0.2; duration: 500 }
                                    NumberAnimation { from: 0.2; to: 1.0; duration: 500 }
                                }
                            }

                            Text {
                                text: isRecording 
                                    ? (Theme.currentLang === "es" ? "Grabando... Presiona teclas" : "Recording... Press keys")
                                    : (newKeys === "" ? (Theme.currentLang === "es" ? "Hacer clic para grabar" : "Click to record") : newKeys)
                                color: isRecording ? Theme.red : (newKeys === "" ? Theme.fgMuted : Theme.fg)
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: !isRecording && newKeys !== ""
                            }
                        }

                        MouseArea {
                            id: recordMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                isRecording = true;
                            }
                        }
                    }
                }

                // Toggle selector for CMD or APP
                Row {
                    width: parent.width
                    height: 28
                    spacing: 0

                    Rectangle {
                        width: parent.width / 2
                        height: parent.height
                        radius: 6
                        color: bindType === "cmd" ? Theme.accent : "transparent"
                        border.color: bindType === "cmd" ? "transparent" : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)

                        Text {
                            anchors.centerIn: parent
                            text: Theme.currentLang === "es" ? "Comando" : "Command"
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: true
                            color: bindType === "cmd" ? Theme.bg : Theme.fg
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bindType = "cmd"
                        }
                    }

                    Rectangle {
                        width: parent.width / 2
                        height: parent.height
                        radius: 6
                        color: bindType === "app" ? Theme.accent : "transparent"
                        border.color: bindType === "app" ? "transparent" : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)

                        Text {
                            anchors.centerIn: parent
                            text: Theme.currentLang === "es" ? "Aplicación" : "Application"
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: true
                            color: bindType === "app" ? Theme.bg : Theme.fg
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bindType = "app"
                        }
                    }
                }

                // 1. Raw Command Input (Visible if bindType === "cmd")
                Column {
                    width: parent.width
                    spacing: 4
                    visible: bindType === "cmd"

                    Text {
                        text: Theme.currentLang === "es" ? "Comando a ejecutar:" : "Command to execute:"
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        color: Theme.fgMuted
                    }

                    TextField {
                        id: inputCmd
                        width: parent.width
                        height: 32
                        text: newCmd
                        onTextChanged: newCmd = text
                        placeholderText: "firefox"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        background: Rectangle {
                            color: Qt.rgba(1,1,1,0.02)
                            border.color: inputCmd.activeFocus ? Theme.accent : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
                            border.width: 1
                            radius: 6
                        }
                    }
                }

                // 2. Application Search Field (Visible if bindType === "app")
                Column {
                    width: parent.width
                    spacing: 4
                    visible: bindType === "app"

                    Text {
                        text: Theme.currentLang === "es" ? "Buscar Aplicación:" : "Search Application:"
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        color: Theme.fgMuted
                    }

                    TextField {
                        id: appSearch
                        width: parent.width
                        height: 28
                        placeholderText: Theme.currentLang === "es" ? "Buscar..." : "Search..."
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        background: Rectangle {
                            color: Qt.rgba(1,1,1,0.02)
                            border.color: appSearch.activeFocus ? Theme.accent : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
                            radius: 6
                        }
                    }
                }
            }

            // 2. Application List Container (Fills middle space, visible if bindType === "app")
            Rectangle {
                id: appsContainer
                anchors.top: inputsColumn.bottom
                anchors.topMargin: 8
                anchors.bottom: actionButtonsColumn.top
                anchors.bottomMargin: 12
                anchors.left: parent.left
                anchors.right: parent.right
                color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.01)
                border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05)
                radius: 8
                clip: true
                visible: bindType === "app"

                ListView {
                    id: appListView
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 2
                    model: {
                        let query = appSearch.text.toLowerCase().trim();
                        if (query === "") return appsList;
                        return appsList.filter(app => app.name.toLowerCase().includes(query));
                    }

                    delegate: Rectangle {
                        id: appItem
                        width: ListView.view.width
                        height: 28
                        radius: 4
                        color: (newCmd === modelData.exec) 
                            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
                            : (appMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.04) : "transparent")
                        border.color: (newCmd === modelData.exec) ? Theme.accent : "transparent"
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 8

                            Text {
                                text: "\uf109" // Monitor icon
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: (newCmd === modelData.exec) ? Theme.accent : Theme.fgMuted
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: modelData.name
                                color: (newCmd === modelData.exec) ? Theme.accent : Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: newCmd === modelData.exec
                                elide: Text.ElideRight
                                width: appItem.width - 24
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: appMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                newCmd = modelData.exec;
                            }
                        }
                    }
                }
            }

            // 3. Action Buttons Column (Anchored to bottom)
            Column {
                id: actionButtonsColumn
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 8

                // Save/Create Button
                Rectangle {
                    width: parent.width
                    height: 34
                    radius: 8
                    color: saveMouse.containsMouse ? Theme.accent : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
                    border.color: Theme.accent
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: isEditMode 
                            ? (Theme.currentLang === "es" ? "Guardar Cambios" : "Save Changes") 
                            : (Theme.currentLang === "es" ? "Añadir Atajo" : "Add Shortcut")
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                        color: saveMouse.containsMouse ? Theme.bg : Theme.accent
                    }

                    MouseArea {
                        id: saveMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (newKeys.trim() === "" || newCmd.trim() === "") return;
                            if (isEditMode) {
                                manageBindsProcess.command = ["python3", Quickshell.env("HOME") + "/pro/dotfiles/theme/manage_keybinds.py", "--edit", oldKeys, newKeys, newCmd];
                            } else {
                                manageBindsProcess.command = ["python3", Quickshell.env("HOME") + "/pro/dotfiles/theme/manage_keybinds.py", "--add", newKeys, newCmd];
                            }
                            manageBindsProcess.running = true;
                        }
                    }
                }

                // Delete Button (Only visible in edit mode)
                Rectangle {
                    width: parent.width
                    height: 34
                    radius: 8
                    color: deleteMouse.containsMouse ? Theme.red : Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.1)
                    border.color: Theme.red
                    border.width: 1
                    visible: isEditMode

                    Text {
                        anchors.centerIn: parent
                        text: Theme.currentLang === "es" ? "Eliminar Atajo" : "Delete Shortcut"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                        color: deleteMouse.containsMouse ? Theme.bg : Theme.red
                    }

                    MouseArea {
                        id: deleteMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            manageBindsProcess.command = ["python3", Quickshell.env("HOME") + "/pro/dotfiles/theme/manage_keybinds.py", "--delete", oldKeys];
                            manageBindsProcess.running = true;
                        }
                    }
                }

                // Cancel Button
                Rectangle {
                    width: parent.width
                    height: 34
                    radius: 8
                    color: "transparent"
                    border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: Theme.currentLang === "es" ? "Cancelar" : "Cancel"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.fgMuted
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: showDrawer = false
                    }
                }
            }
        }
    }

    // Hidden Item to capture keybinds when recording
    Item {
        id: keyGrabber
        focus: isRecording
        
        Keys.onPressed: (event) => {
            if (!isRecording) return;
            
            // Extract modifiers
            let mods = [];
            if (event.modifiers & Qt.MetaModifier) mods.push("SUPER");
            if (event.modifiers & Qt.ControlModifier) mods.push("CTRL");
            if (event.modifiers & Qt.AltModifier) mods.push("ALT");
            if (event.modifiers & Qt.ShiftModifier) mods.push("SHIFT");
            
            // Extract main key
            let keyText = "";
            let k = event.key;
            
            // Handle alphabet and numbers
            if (k >= Qt.Key_A && k <= Qt.Key_Z) {
                keyText = String.fromCharCode(k);
            } else if (k >= Qt.Key_0 && k <= Qt.Key_9) {
                keyText = String.fromCharCode(k);
            } else {
                switch(k) {
                    case Qt.Key_Return: keyText = "Return"; break;
                    case Qt.Key_Enter: keyText = "Return"; break;
                    case Qt.Key_Space: keyText = "Space"; break;
                    case Qt.Key_Escape: keyText = "Escape"; break;
                    case Qt.Key_Tab: keyText = "Tab"; break;
                    case Qt.Key_Backspace: keyText = "BackSpace"; break;
                    case Qt.Key_Delete: keyText = "Delete"; break;
                    case Qt.Key_Insert: keyText = "Insert"; break;
                    case Qt.Key_Home: keyText = "Home"; break;
                    case Qt.Key_End: keyText = "End"; break;
                    case Qt.Key_PageUp: keyText = "Prior"; break;
                    case Qt.Key_PageDown: keyText = "Next"; break;
                    case Qt.Key_Left: keyText = "Left"; break;
                    case Qt.Key_Right: keyText = "Right"; break;
                    case Qt.Key_Up: keyText = "Up"; break;
                    case Qt.Key_Down: keyText = "Down"; break;
                    case Qt.Key_F1: keyText = "F1"; break;
                    case Qt.Key_F2: keyText = "F2"; break;
                    case Qt.Key_F3: keyText = "F3"; break;
                    case Qt.Key_F4: keyText = "F4"; break;
                    case Qt.Key_F5: keyText = "F5"; break;
                    case Qt.Key_F6: keyText = "F6"; break;
                    case Qt.Key_F7: keyText = "F7"; break;
                    case Qt.Key_F8: keyText = "F8"; break;
                    case Qt.Key_F9: keyText = "F9"; break;
                    case Qt.Key_F10: keyText = "F10"; break;
                    case Qt.Key_F11: keyText = "F11"; break;
                    case Qt.Key_F12: keyText = "F12"; break;
                    default:
                        // Modifier keys pressed alone do not stop recording
                        if (k === Qt.Key_Control || k === Qt.Key_Shift || k === Qt.Key_Alt || k === Qt.Key_Meta) {
                            event.accepted = true;
                            return;
                        }
                        break;
                }
            }
            
            if (keyText !== "") {
                let finalBind = "";
                if (mods.length > 0) {
                    finalBind = mods.join(" + ") + " + " + keyText;
                } else {
                    finalBind = keyText;
                }
                newKeys = finalBind;
                isRecording = false;
                event.accepted = true;
            }
        }
    }

    onIsRecordingChanged: {
        if (isRecording) {
            keyGrabber.forceActiveFocus();
            blockBindsProcess.running = true;
        } else {
            unblockBindsProcess.running = true;
        }
    }

    onShowDrawerChanged: {
        if (!showDrawer) {
            isRecording = false;
        }
    }
}
