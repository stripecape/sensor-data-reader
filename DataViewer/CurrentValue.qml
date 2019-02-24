import QtQuick 2.0
import QtQuick.Controls 2.0
import QtCharts 2.0
import QtQuick.Dialogs 1.1

Item {

    property string service: parent.dataType

    id: currentValue

    height: box.height - 20
    width: box.width - 20

    // Button to open menu to select meters
    Button {
        background: Rectangle {
            radius: 10
            color: "#dddddd"
        }

        height: 20
        id: btn_open_meter_menu
        text: "Meters"
        onClicked: menu_meter.open()
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 10
        anchors.rightMargin: 10

        Menu {
            id: menu_meter
            title: "Meter"
            height: meter_model.count * 40

            contentItem: ListView {

                orientation: Qt.Vertical
                model: meter_model
                delegate: MenuItem {text: name; checkable: true; onToggled: updateList(name, checked)}
            }

            ListModel {
                id: meter_model
            }

            function updateItems(){
                meter_model.clear();
                pieSeries.clear();
                var meters = datareader.getMeters(datareader.getServiceId(service));
                for (var i = 0; i < meters.length; i++){
                    var meter_name = datareader.getMeterName(meters[i]);
                    meter_model.append({"name": meter_name});
                }
            }

            Component.onCompleted: {
                updateItems();
            }
        }
    }

    // Show current values of selected meters in a pie chart
    ChartView {
        width: parent.width / 2
        anchors.top: btn_open_meter_menu.bottom
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30
        theme: ChartView.ChartThemeBrownSand
        antialiasing: true

        PieSeries {
            id: pieSeries
        }
    }

    // Show current values of selected meters in a list
    ListView {
        id: meter_list
        width: parent.width / 2
        height: parent.height
        orientation: Qt.Vertical
        model: selectedMeters
        anchors.top: parent.top
        anchors.leftMargin: 30
        anchors.left: parent.left
        anchors.right: btn_open_meter_menu.left
        spacing: 20
        delegate:
            Column {
                Text {text: name; font.bold: true; fontSizeMode: Text.Fit}
                Text {text: value + unit; fontSizeMode: Text.Fit}
           }
    }

    ListModel {
        id: selectedMeters
    }


    // ------------------------------ functions -------------------------------

    // Sets new current value when value for meter "meter_id" changes
    function setValue(type, meter_id, timestamp, val, unit){
        if (datareader.getLatestRetVal() === false){
            server_error_dialog.open();
            return;
        }

        var meter_name = datareader.getMeterName(meter_id);

        for (var i = 0; i < selectedMeters.count; i++){
            var item = selectedMeters.get(i);
            if (item.name === meter_name){
                item.value = val;
                item.unit = unit;
            }
        }
    }


    // Updates list of selected meters and adds current values for selected meters as text and in PieChart
    function updateList(name, checked){
        if (checked) {
            var meter_id = datareader.getMeterId(name);
            var latest_value = datareader.getLatestValue(service, meter_id);
            var ret_val = datareader.getLatestRetVal();

            if (ret_val){
                pieSeries.append(name, latest_value);
                selectedMeters.append({"name": name, "value": latest_value.toFixed(2), "unit": datareader.getUnit(meter_id)})
            }
            else {
                server_error_dialog.open();
            }
        }
        else {
            for (var i = 0; i < selectedMeters.count; i++){
                if (selectedMeters.get(i).name === name) {
                    selectedMeters.remove(i);
                }
            }

            pieSeries.remove(pieSeries.find(name));
        }

        if (selectedMeters.count == 0){
            parent.errorTextString = "Select meters";
        }
        else {
            parent.errorTextString = "";
        }
    }


    onServiceChanged: {
        console.log("New service: "+service);
        selectedMeters.clear();
        menu_meter.updateItems();
    }

    Component.onCompleted: {
        datareader.valueChanged.connect(setValue)
        parent.errorTextString = "Select meters";
    }
}
