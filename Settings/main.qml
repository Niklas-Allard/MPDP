import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: settingsPage
    objectName: "settingsPage"

    Text {
        id: headerText
        text: "Einstellungen"
        font.pixelSize: 24 * settingsManager.fontScale
        font.bold: true
        color: settingsManager.colorText
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 16
    }

    TabBar {
        id: tabBar
        anchors.top: headerText.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 8

        TabButton { text: "Darstellung" }
        TabButton { text: "Sprachausgabe" }
        TabButton { text: "Aussprache" }
        TabButton { text: "Navigation" }
        TabButton { text: "Wiedergabe" }
        TabButton { text: "Verzeichnisse" }
        TabButton { text: "Bildschirmschoner" }
        TabButton { text: "Text-Filter" }
        TabButton { text: "Shuffle" }
    }

    StackLayout {
        anchors.top: tabBar.bottom
        anchors.bottom: footer.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 8
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        currentIndex: tabBar.currentIndex

        TabAppearance          {}
        TabSpeech              {}
        TabWordPronunciation   {}
        TabNavigation          {}
        TabPlayback            {}
        TabDirectories         {}
        TabScreensaver         {}
        TabTextFilter          {}
        TabShuffle             {}
    }

    RowLayout {
        id: footer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        spacing: 16

        Button {
            text: "Zurück"
            onClicked: settingsPage.StackView.view.pop()
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }

        Button {
            text: "Auf Standardwerte zurücksetzen"
            onClicked: settingsManager.reset_to_defaults()
        }
    }
}
