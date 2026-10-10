import QtQuick
import QtQuick.Effects
import QtMultimedia
import QtQuick.Controls.Basic

Rectangle {
    id: root
    color: config.panel

    // dynamic screen size
    property real s: Math.min(width / 2560, height / 1440)
    property real fieldWidth: 450 * s       // text field width
    property real panelWidth: 800 * s       // blur panel width
    property date now: new Date()

    FontLoader {
        id: poiret
        source: "PoiretOne-Regular.ttf"
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    MediaPlayer {
        id: player
        source: "background.mp4"
        loops: MediaPlayer.Infinite
        videoOutput: vo
        audioOutput: AudioOutput { muted: true }
        Component.onCompleted: play()
    }

    VideoOutput {
        id: vo
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
    }

    // blurred glass panel on the left
    Item {
        id: panel
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.panelWidth

        ShaderEffectSource {
            id: blurSource
            anchors.fill: parent
            sourceItem: vo
            sourceRect: Qt.rect(0, 0, panel.width, panel.height)
            live: true
            visible: false
        }

        MultiEffect {
            anchors.fill: parent
            source: blurSource
            blurEnabled: true
            blur: 1.0
            blurMax: 50
            autoPaddingEnabled: false
        }

        // tint
        Rectangle {
            anchors.fill: parent
            color: "#0000002e"
        }

        // thin highlight along the right edge
        Rectangle {
            anchors.right: parent.right
            width: Math.max(1, 1 * root.s)
            height: parent.height
            color: "#22cdd6f4"
        }
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: (root.panelWidth - root.fieldWidth) / 2
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -75 * root.s
        spacing: 30 * root.s
        width: root.fieldWidth

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(root.now, "h:mm AP")
                color: config.text
                font.family: poiret.name
                font.pixelSize: 96 * root.s
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(root.now, "dddd, MMMM d")
                color: config.text
                font.family: poiret.name
                font.pixelSize: 32 * root.s
            }
        }

        // gap between time/date and icon
        Item {
            width: 1
            height: 80 * root.s
        }

        Item {
            id: icon
            width: 300 * root.s
            height: 300 * root.s
            anchors.horizontalCenter: parent.horizontalCenter

            Image {
                id: iconImg
                anchors.fill: parent
                source: "fern1x1.jpg"
                sourceSize: Qt.size(width * 2, height * 2)
                fillMode: Image.PreserveAspectCrop
                layer.enabled: true
                visible: false
            }

            Rectangle {
                id: iconMask
                anchors.fill: parent
                radius: width / 2
                layer.enabled: true
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: iconImg
                maskEnabled: true
                maskSource: iconMask
            }

            // ring around icon
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: 4 * root.s
                border.color: config.accent
            }
        }

        // gap between icon and text fields
        Item {
            width: 1
            height: 80 * root.s
        }

        TextField {
            id: user
            width: parent.width
            height: 55 * root.s
            leftPadding: 22 * root.s
            font.family: poiret.name
            font.pixelSize: 24 * root.s
            text: userModel.lastUser
            placeholderText: "Username"
            placeholderTextColor: "#80cdd6f4"
            color: config.text
            selectionColor: config.accent
            selectedTextColor: "#1e1e2e"
            KeyNavigation.tab: pass

            background: Rectangle {
                radius: 25 * root.s
                color: "#401e1e2e"
                border.width: 2 * root.s
                border.color: user.activeFocus ? config.accent : "#33cdd6f4"

                Behavior on border.color { ColorAnimation { duration: 150 } }
            }
        }

        TextField {
            id: pass
            width: parent.width
            height: 55 * root.s
            leftPadding: 22 * root.s
            font.family: poiret.name
            font.pixelSize: 24 * root.s
            echoMode: TextInput.Password
            placeholderText: "Password"
            placeholderTextColor: "#80cdd6f4"
            color: config.text
            selectionColor: config.accent
            selectedTextColor: "#1e1e2e"
            KeyNavigation.tab: user
            Keys.onReturnPressed: sddm.login(user.text, pass.text, sessionModel.lastIndex)
            focus: true

            background: Rectangle {
                radius: 25 * root.s
                color: "#401e1e2e"
                border.width: 2 * root.s
                border.color: pass.activeFocus ? config.accent : "#33cdd6f4"

                Behavior on border.color { ColorAnimation { duration: 150 } }
            }
        }

        Text {
            id: error
            color: "#f38ba8"
            text: ""
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            error.text = "Login failed"
            pass.text = ""
            pass.forceActiveFocus()
        }
    }
}