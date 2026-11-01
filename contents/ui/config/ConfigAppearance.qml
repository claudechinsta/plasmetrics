import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    readonly property int maxResults: 8
    readonly property string currentFont: cfg_fontFamily !== "" ? cfg_fontFamily : Kirigami.Theme.defaultFont.family
    property var allFonts: null
    property var results: []
    property int hidden: 0

    // The family list is only read on the first search, then reused
    function search(query) {
        var q = query.trim().toLowerCase()
        if (q === "") { results = []; hidden = 0; return }
        if (allFonts === null) allFonts = Qt.fontFamilies()
        var out = [], total = 0
        for (var i = 0; i < allFonts.length; i++) {
            if (allFonts[i].toLowerCase().indexOf(q) >= 0) {
                total++
                if (out.length < maxResults) out.push(allFonts[i])
            }
        }
        results = out
        hidden = total - out.length
    }

    property alias cfg_useCustomFont: customFont.checked
    property string cfg_fontFamily
    property alias cfg_panelFontSize: panelSize.value
    property alias cfg_popupFontSize: popupSize.value
    property alias cfg_fontBold: bold.checked
    property alias cfg_verticalLabels: vertLabels.checked

    property bool cfg_useCustomFontDefault
    property string cfg_fontFamilyDefault
    property int cfg_panelFontSizeDefault
    property int cfg_popupFontSizeDefault
    property bool cfg_fontBoldDefault
    property bool cfg_verticalLabelsDefault

    Kirigami.FormLayout {
        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Font") }
        QQC2.CheckBox { id: customFont; text: i18n("Use custom font") }
        ColumnLayout {
            Kirigami.FormData.label: i18n("Family:")
            Kirigami.FormData.buddyFor: searchField
            enabled: customFont.checked
            Layout.preferredWidth: Kirigami.Units.gridUnit * 16
            spacing: 0

            QQC2.Label {
                text: page.currentFont
                font.family: page.currentFont
                Layout.bottomMargin: Kirigami.Units.smallSpacing
            }
            Kirigami.SearchField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: i18n("Search fonts…")
                onTextChanged: page.search(text)
            }
            Repeater {
                model: page.results
                QQC2.ItemDelegate {
                    Layout.fillWidth: true
                    text: modelData
                    font.family: modelData
                    onClicked: {
                        page.cfg_fontFamily = modelData
                        searchField.text = ""
                    }
                }
            }
            QQC2.Label {
                visible: page.hidden > 0
                text: i18n("%1 more, keep typing to narrow down", page.hidden)
                opacity: 0.6
                Layout.topMargin: Kirigami.Units.smallSpacing
            }
        }
        QQC2.SpinBox { id: panelSize; Kirigami.FormData.label: i18n("Panel size (px):"); from: 6; to: 40 }
        QQC2.SpinBox { id: popupSize; Kirigami.FormData.label: i18n("Popup size (pt):"); from: 6; to: 24 }
        QQC2.CheckBox { id: bold; text: i18n("Bold panel values") }
        QQC2.CheckBox { id: vertLabels; text: i18n("Vertical panel labels") }

    }
}
