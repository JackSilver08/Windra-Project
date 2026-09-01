import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    width: 390
    height: 590
    minimumWidth: 360
    minimumHeight: 540
    visible: true
    title: "Windra Calc"
    color: "#f4f7f4"

    property real accumulator: 0
    property string operation: ""
    property bool startNewNumber: true
    property string displayText: "0"

    function numberValue() { return Number(displayText.replace(",", ".")) }
    function formatNumber(v) {
        if (!isFinite(v)) return "Error"
        const rounded = Math.round(v * 1000000000) / 1000000000
        return String(rounded)
    }
    function calculate() {
        const b = numberValue(); let r = b
        if (operation === "+") r = accumulator + b
        else if (operation === "−") r = accumulator - b
        else if (operation === "×") r = accumulator * b
        else if (operation === "÷") r = b === 0 ? NaN : accumulator / b
        displayText = formatNumber(r); accumulator = Number(displayText); operation = ""; startNewNumber = true
    }
    function press(k) {
        if (k >= "0" && k <= "9") {
            if (startNewNumber || displayText === "0" || displayText === "Error") displayText = k
            else displayText += k
            startNewNumber = false; return
        }
        if (k === ".") { if (startNewNumber) { displayText = "0."; startNewNumber = false } else if (displayText.indexOf(".") < 0) displayText += "."; return }
        if (k === "C") { accumulator = 0; operation = ""; displayText = "0"; startNewNumber = true; return }
        if (k === "±") { displayText = formatNumber(-numberValue()); return }
        if (k === "%") { displayText = formatNumber(numberValue() / 100); startNewNumber = true; return }
        if (k === "=") { if (operation.length) calculate(); return }
        if (["+","−","×","÷"].indexOf(k) >= 0) {
            if (operation.length && !startNewNumber) calculate()
            accumulator = numberValue(); operation = k; startNewNumber = true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 13
        Label { text: "Windra Calc"; font.pixelSize: 21; font.bold: true; color: "#111315" }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 112
            radius: 20
            color: "#ffffff"
            Label {
                anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 20
                text: root.displayText
                font.pixelSize: 38; font.bold: true; color: "#111315"
                elide: Text.ElideLeft
            }
            Label { anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; text: root.operation.length ? root.accumulator + " " + root.operation : ""; color: "#7b8589" }
        }
        GridLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            columns: 4; rowSpacing: 9; columnSpacing: 9
            Repeater {
                model: ["C","±","%","÷","7","8","9","×","4","5","6","−","1","2","3","+","0",".","=","="]
                delegate: Button {
                    required property string modelData
                    required property int index
                    text: modelData
                    Layout.fillWidth: true; Layout.fillHeight: true
                    font.pixelSize: 21
                    enabled: !(index === 19)
                    opacity: index === 19 ? 0 : 1
                    onClicked: root.press(modelData)
                }
            }
        }
    }
}
