import QtQuick
import QtQuick.Controls
import Quickshell
import "root:/theme"

Item {
    id: authWrapper

    readonly property var flow: dock.polkitAgent ? dock.polkitAgent.flow : null

    implicitWidth: 488
    implicitHeight: mainColumn.implicitHeight + pad * 2
    readonly property int pad: 16

    focus: true
    Component.onCompleted: {
        authWrapper.forceActiveFocus();
        if (passwordInput) {
            passwordInput.forceActiveFocus();
        }
    }

    Component.onDestruction: {
        if (flow && !flow.isCompleted && !flow.isCancelled) {
            flow.cancelAuthenticationRequest();
        }
    }

    // Monitor flow completion to automatically close the panel
    Connections {
        target: flow ? flow : null
        function onIsCompletedChanged() {
            if (flow && flow.isCompleted) {
                // If successful or fully resolved, go back to default
                dock.currentMode = "default";
            }
        }
        function onIsCancelledChanged() {
            if (flow && flow.isCancelled) {
                dock.currentMode = "default";
            }
        }
    }

    Column {
        id: mainColumn
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: pad
        anchors.leftMargin: pad
        anchors.rightMargin: pad
        spacing: 10

        // ── Header (Lock icon + Title) ──────────────────────────────────────
        Row {
            spacing: 8
            width: parent.width

            Text {
                text: "\uf023" // Lock icon
                font.family: Theme.fontFamily
                font.pixelSize: 13
                color: Theme.accent
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: Theme.t.auth_required ?? "Authentication Required"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.bold: true
                color: Theme.fg
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // ── Description & Action ID ──────────────────────────────────────────
        Column {
            width: parent.width
            spacing: 4

            Text {
                width: parent.width
                text: flow ? flow.message : "Authentication is needed to run privileged actions."
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.fg
                wrapMode: Text.WordWrap
            }

            Text {
                width: parent.width
                text: flow ? flow.actionId : "org.freedesktop.policykit.exec"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: Theme.fgMuted
                elide: Text.ElideRight
            }
        }

        // ── Error Message (if any) ───────────────────────────────────────────
        Text {
            width: parent.width
            text: flow ? flow.supplementaryMessage : ""
            font.family: Theme.fontFamily
            font.pixelSize: 10
            color: Theme.red
            visible: text !== ""
            wrapMode: Text.WordWrap
        }

        // ── Password Input ───────────────────────────────────────────────────
        Rectangle {
            width: parent.width
            height: 32
            radius: 8
            color: Theme.bgAlt
            border.width: 1
            border.color: passwordInput.activeFocus ? Theme.accent : Qt.rgba(1, 1, 1, 0.05)

            TextInput {
                id: passwordInput
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.fg
                echoMode: TextInput.Password
                
                focus: true

                Text {
                    text: flow ? flow.inputPrompt : "Password:"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.fgMuted
                    visible: passwordInput.text === "" && !passwordInput.activeFocus
                    anchors.verticalCenter: parent.verticalCenter
                }

                onAccepted: {
                    if (flow && text !== "") {
                        flow.submit(text);
                    }
                }
            }
        }

        // ── Buttons ──────────────────────────────────────────────────────────
        Row {
            anchors.right: parent.right
            spacing: 8

            // Cancel Button
            Button {
                id: cancelBtn
                text: Theme.t.cancel ?? "Cancel"
                onBtnClicked: {
                    if (flow) {
                        flow.cancelAuthenticationRequest();
                    } else {
                        dock.currentMode = "default";
                    }
                }
            }

            // Authenticate Button
            Button {
                id: authBtn
                text: Theme.t.authenticate ?? "Authenticate"
                highlighted: true
                onBtnClicked: {
                    console.log("Authenticate button clicked. Submitting password...");
                    if (flow) {
                        flow.submit(passwordInput.text);
                    }
                }
            }
        }
    }

    // Inline custom component for styled buttons
    component Button : Rectangle {
        id: btnRoot
        property string text: ""
        property bool highlighted: false
        signal btnClicked()

        width: label.implicitWidth + 24
        height: 28
        radius: 14
        color: highlighted ? Theme.green : Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.6)
        border.width: highlighted ? 0 : 1
        border.color: Qt.rgba(1, 1, 1, 0.1)

        Text {
            id: label
            anchors.centerIn: parent
            text: btnRoot.text
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.bold: true
            color: highlighted ? Theme.bg : Theme.fg
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                console.log("Button MouseArea clicked: " + btnRoot.text);
                btnRoot.btnClicked();
            }
            onEntered: {
                if (!highlighted) btnRoot.color = Theme.bgAlt;
            }
            onExited: {
                if (!highlighted) btnRoot.color = Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.6);
            }
        }
    }
}
