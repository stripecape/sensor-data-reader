import QtQuick 2.7
import QtQuick.Controls 1.4 as OldCtrl
import QtQuick.Controls 2.0 as NewCtrl
import QtQuick.Window 2.2
import QtCharts 2.2
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.1
import QtQuick.Controls.Styles 1.4

Item {

    id: window
    width: box.width - 40
    height: box.height
    anchors.top: parent.top
    anchors.topMargin: 30

    property string dataType
    property string graphType
    property date startDate
    property date endDate
    property int datecount: 0
    property string errorTextString: ""
    property date dateSelected

    onGraphTypeChanged: handleGraphTypeChange()

    // Button to open and close calendatr
    NewCtrl.Button {
        id: btn_calendar
        text: "Choose interval"
        background: Rectangle {
            radius: 10
            color: "#dddddd"
        }
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
        onClicked: {
            calendar.showCalendarInfo()
            calendar.toggle()
        }

    }

    // Calendar Component to select dates for history and chart views
    OldCtrl.Calendar {
        id: calendar
        anchors.centerIn: window
        anchors.topMargin: 40
        maximumDate: datareader.getTimeStamp()
        height: parent.height*0.7
        width: 300
        visible: false
        onClicked: checkDate(date)
        z: 10

        function toggle(){
            visible = !visible;
            btn_calendar.text = visible ? "Close" : "Choose interval"

        }

        function showCalendarInfo() {
            error_text.visible = true
            errorTextString = "Select the first and the last date of the time interval."
        }

    }

    // Ways to display error messages

    Text {
        id: error_text
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
        anchors.leftMargin: 20
        text: errorTextString
        visible: false

        onTextChanged: {
            showErrorText()
        }
    }


    MessageDialog {
        id: server_error_dialog
        title: "Error with data source"
        text: "Could not get data from data source!"
        onAccepted: {
            this.close()
        }
    }


    // One of these three components is visible, based on selected graph type

    Chart {
        anchors.top: window.top
        anchors.bottom: btn_calendar.top
        anchors.topMargin: 30
        id: lineChart
        service: data_type
    }

    CurrentValue {
        service: data_type
        anchors.centerIn: parent
        id: currentValue
    }

    History {
        anchors.top: window.top
        anchors.bottom: btn_calendar.top
        anchors.topMargin: 30
        id: historyList
        errorText: errorTextString
    }

    // ------------------------------ functions -------------------------------

    function showErrorText() {
        error_text.visible = true
    }

    function showErrorDialog(custom_text){
        server_error_dialog.text = custom_text;
        server_error_dialog.open();
    }


    function handleGraphTypeChange() {
        if (graphType === "Current value") {
            currentValue.visible = true
            historyList.visible = false
            lineChart.visible = false
            btn_calendar.visible = false
        } else if (graphType === "History") {
            btn_calendar.visible = true
            historyList.visible = true
            lineChart.visible = false
            currentValue.visible = false
        } else {
            btn_calendar.visible = true
            lineChart.visible = true
            historyList.visible = false
            currentValue.visible = false
        }
    }


    // Set selected dates to Chart and History Components
    function checkDate(date) {

       if (datecount === 0) {
           startDate = date
           datecount += 1

       } else {
           endDate = date
           datecount +=1
       }

       if(datecount === 2) {
          error_text.visible = false
           if (graphType === "History"){
               historyList.setTimeInterval(startDate, endDate)
           }
           else if (graphType === "Graph"){
               lineChart.setTimeInterval(startDate, endDate)
           }
           // reset dates and hide calendar
           startDate = ""
           endDate = ""
           datecount = 0
           calendar.toggle()
       }
    }

}
