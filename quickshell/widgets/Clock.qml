import QtQuick
import Quickshell
import Quickshell.Hyprland
import "root:/theme"

Item {
    id: root

    implicitWidth: textItem.implicitWidth
    implicitHeight: 24
    width: implicitWidth
    height: implicitHeight
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    property bool menuOpen: false

    property SystemClock clock: SystemClock {
        precision: SystemClock.Seconds
    }

    // Calendar state & logic
    property int currentYear: new Date().getFullYear()
    property int currentMonth: new Date().getMonth()
    property var calendarDays: []

    function getMonthName(m) {
        if (Theme.t.months_full && Theme.t.months_full[m] !== undefined) {
            return Theme.t.months_full[m];
        }
        const names = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
                       "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
        return names[m];
    }

    function isToday(y, m, d) {
        let today = new Date();
        return today.getFullYear() === y && today.getMonth() === m && today.getDate() === d;
    }

    function generateCalendar(year, month) {
        let days = [];
        
        let prevMonth = month - 1;
        let prevYear = year;
        if (prevMonth < 0) {
            prevMonth = 11;
            prevYear--;
        }
        let prevMonthDays = new Date(prevYear, prevMonth + 1, 0).getDate();
        
        let currentMonthDays = new Date(year, month + 1, 0).getDate();
        let firstDay = new Date(year, month, 1).getDay();
        let startDay = firstDay === 0 ? 6 : firstDay - 1; // 0 = Mon, 6 = Sun
        
        for (let i = startDay - 1; i >= 0; i--) {
            days.push({
                "day": prevMonthDays - i,
                "isCurrentMonth": false,
                "month": prevMonth,
                "year": prevYear
            });
        }
        
        for (let i = 1; i <= currentMonthDays; i++) {
            days.push({
                "day": i,
                "isCurrentMonth": true,
                "month": month,
                "year": year
            });
        }
        
        let nextMonth = month + 1;
        let nextYear = year;
        if (nextMonth > 11) {
            nextMonth = 0;
            nextYear++;
        }
        
        let remainingCells = 42 - days.length;
        for (let i = 1; i <= remainingCells; i++) {
            days.push({
                "day": i,
                "isCurrentMonth": false,
                "month": nextMonth,
                "year": nextYear
            });
        }
        
        return days;
    }

    function updateCalendar() {
        calendarDays = generateCalendar(currentYear, currentMonth);
    }

    Component.onCompleted: {
        updateCalendar();
    }

    onCurrentMonthChanged: updateCalendar()
    onCurrentYearChanged: updateCalendar()

    onMenuOpenChanged: {
        if (menuOpen) {
            let today = new Date();
            currentYear = today.getFullYear();
            currentMonth = today.getMonth();
            updateCalendar();
        }
    }

    Text {
        id: textItem
        anchors.centerIn: parent
        height: parent.height
        verticalAlignment: Text.AlignVCenter
        text: {
            const d = root.clock.date;
            const dayName = (Theme.t.days && Theme.t.days[d.getDay()] !== undefined) ? Theme.t.days[d.getDay()] : Qt.formatDateTime(d, "ddd");
            const monthName = (Theme.t.months && Theme.t.months[d.getMonth()] !== undefined) ? Theme.t.months[d.getMonth()] : Qt.formatDateTime(d, "MMM");
            const day = d.getDate();
            
            let hours = d.getHours();
            let minutes = d.getMinutes();
            let ampm = hours >= 12 ? "PM" : "AM";
            hours = hours % 12;
            hours = hours ? hours : 12;
            minutes = minutes < 10 ? '0'+minutes : minutes;
            let timeStr = hours + ":" + minutes + " " + ampm;
            
            return dayName + ", " + monthName + " " + day + " - " + timeStr;
        }
        color: clockArea.containsMouse ? Theme.accent : Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    MouseArea {
        id: clockArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.menuOpen = !root.menuOpen
    }

    PopupWindow {
        id: calendarPopup
        visible: root.menuOpen || closingAnim.running

        property int gap: 20

        anchor.item: root
        anchor.edges: Edges.Top
        anchor.gravity: Edges.Top

        implicitWidth: calendarCard.implicitWidth
        implicitHeight: calendarCard.implicitHeight + gap
        color: "transparent"

        HyprlandFocusGrab {
            windows: [calendarPopup]
            active: root.menuOpen
            onCleared: {
                root.menuOpen = false;
            }
        }

        PropertyAnimation {
            id: closingAnim
            target: calendarCard
            property: "opacity"
            to: 0
            duration: 180
            easing.type: Easing.InCubic
        }

        Rectangle {
            id: calendarCard
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: parent.height - calendarPopup.gap

            implicitWidth: 248
            implicitHeight: 301

            color: Theme.bg
            radius: 14
            border.color: Theme.bgAlt
            border.width: 1

            opacity: 0
            scale: 0.9
            y: 8

            states: State {
                name: "open"
                when: root.menuOpen
                PropertyChanges {
                    target: calendarCard
                    opacity: 1
                    scale: 1
                    y: 0
                }
            }

            transitions: Transition {
                NumberAnimation {
                    properties: "opacity,scale,y"
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            Column {
                id: calendarLayout
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Row {
                    width: parent.width
                    height: 28

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        color: prevMouse.containsMouse ? Theme.bgAlt : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "\uf104"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: prevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.currentMonth === 0) {
                                    root.currentMonth = 11;
                                    root.currentYear--;
                                } else {
                                    root.currentMonth--;
                                }
                            }
                        }
                    }

                    Text {
                        width: parent.width - 56
                        height: parent.height
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: root.getMonthName(root.currentMonth) + " " + root.currentYear
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        color: nextMouse.containsMouse ? Theme.bgAlt : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "\uf105"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.currentMonth === 11) {
                                    root.currentMonth = 0;
                                    root.currentYear++;
                                } else {
                                    root.currentMonth++;
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.bgAlt
                }

                Row {
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: Theme.t.days_initials ?? ["L", "M", "M", "J", "V", "S", "D"]
                        Text {
                            width: 28
                            height: 20
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: modelData
                            color: Theme.fgMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }
                }

                Grid {
                    id: daysGrid
                    columns: 7
                    spacing: 4

                    Repeater {
                        model: root.calendarDays

                        delegate: Rectangle {
                            id: dayDelegate
                            width: 28
                            height: 28
                            radius: 14

                            required property var modelData

                            property bool isTodayDate: modelData !== undefined && modelData !== null ? root.isToday(modelData.year, modelData.month, modelData.day) : false

                            color: isTodayDate 
                                   ? Theme.accent 
                                   : (dayMouse.containsMouse ? Theme.bgAlt : "transparent")

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: dayDelegate.modelData !== undefined && dayDelegate.modelData !== null ? dayDelegate.modelData.day : ""
                                color: dayDelegate.isTodayDate 
                                       ? Theme.bg 
                                       : (dayDelegate.modelData !== undefined && dayDelegate.modelData !== null && dayDelegate.modelData.isCurrentMonth ? Theme.fg : Theme.surface)
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: dayDelegate.isTodayDate
                            }

                            MouseArea {
                                id: dayMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }
                }
            }
        }

        onVisibleChanged: {
            if (!root.menuOpen && visible) {
                closingAnim.start();
            }
        }
    }

    Connections {
        target: closingAnim
        function onStopped() {
            if (!root.menuOpen) {
                calendarPopup.visible = false;
            }
        }
    }
}