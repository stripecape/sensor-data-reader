import QtQuick 2.0
import QtCharts 2.2
import QtQuick.Controls 2.0


Item {

    id: historyList
    anchors.bottom: parent.bottom
    visible: false
    height: box.height - 20
    width: box.width - 20

    property string unit
    property string service: parent.dataType
    property date startingDate
    property date endingDate
    property string axisX
    property string axisY
    property string errorText: parent.errorTextString
    property bool dateSelected: false

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
                delegate: MenuItem {
                    text: name;
                    checkable: true;
                    onToggled: updateList(name, checked)
                }
            }
            ListModel {
                id: meter_model
            }

            function updateItems(){
                meter_model.clear();
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

    // List of currently selected meters
    ListModel {
        id: selectedMeters
    }

    // ------------------------------------ Chart ------------------------------------

    ChartView {

        title: service
        id: chart
        width: parent.width - 40
        theme: ChartView.ChartThemeHighContrast
        antialiasing: true
        anchors.top: btn_open_meter_menu.bottom
        anchors.bottom: parent.bottom
        visible: true

        property string chartName


        LineSeries {
            id: history_series
            axisY: ValueAxis {
                id: valueAxisY
                titleText: unit
                gridVisible: true
                labelsVisible: true
                min: -10
                max: 10
            }

            axisX: DateTimeAxis {
                id: dateTimeAxisX
                titleText: "Timestamp"
                format: "dd.MM.yyyy"
                gridVisible: true
                labelsVisible: true
                min: startingDate
                max: endingDate
            }
        }

        PinchArea {
            anchors.fill: parent
            onPinchUpdated: chart.zoom(pinch.scale);
        }



        function setHistoryLine() {

            if (!dateSelected){
                historyList.parent.errorTextString  = "Select dates!";
                return;
            }

            chart.removeAllSeries()

            if (selectedMeters.count == 0){
                historyList.parent.errorTextString  = "Select meters!";
                return;
            }

            historyList.parent.errorTextString = "";

            var max = -Infinity;
            var min = Infinity;
            for (var i = 0; i < selectedMeters.count; i++){
                var meter_id = datareader.getMeterId(selectedMeters.get(i).name)
                var service = datareader.getServiceToMeter(meter_id)
                var data = datareader.getData(service, meter_id, startingDate, endingDate)

                if (datareader.getLatestRetVal() === false){
                    window.showErrorDialog();
                }

                unit = datareader.getUnit(meter_id);

                if (data.length === 0) {
                    window.showErrorDialog("No data to show!");
                }
                else {
                    var series = chart.createSeries(ChartView.SeriesTypeLine, selectedMeters.get(i).name+" avg: "+dataanalyzer.getAvg(data).toFixed(2), dateTimeAxisX, valueAxisY)

                    var day = -1;
                    for (var j = 0; j < data.length; j++){
                        if (parseFloat(data[j].value) > max) max = parseFloat(data[j].value);
                        if (parseFloat(data[j].value) < min) min = parseFloat(data[j].value);

                        var date = datareader.variantToDateTime(data[j].timestamp)
                        series.append(toMsecsSinceEpoch(date), data[j].value)
                    }

                    checkDataAmounts(data);
                }
            }

            valueAxisY.max = max + Math.abs(max * 0.1)
            valueAxisY.min = min - Math.abs(min * 0.1)

            if (valueAxisY.max == 0) valueAxisY.max = 1;
            if (valueAxisY.min == 0) valueAxisY.min = -1;

        }
    }

    // ------------------------------ functions -------------------------------

    // Updates list of selected meters and draws history data for the meters that are selected
    function updateList(name, checked){
        if (checked) {
            selectedMeters.append({"name": name})
            if (!dateSelected) {
                errorText = "Select dates!"
            }
        }
        else {
            for (var i = 0; i < selectedMeters.count; i++){
                if (selectedMeters.get(i).name === name) {
                    selectedMeters.remove(i);
                }
            }
        }

        chart.setHistoryLine()
    }


    function toMsecsSinceEpoch(date) {
        var msecs = date.getTime();
        return msecs;
    }


    // Sets time interval to show history
   function setTimeInterval(dateStart, dateEnd) {
       if (dateStart <= dateEnd) {
           startingDate = dateStart
           endingDate = dateEnd
           dateSelected = true
           chart.setHistoryLine();
       } else {
           dateSelected = false
           parent.errorTextString = "The date selected first can't be bigger than the second date!"
       }

   }

   // Check that at least 50 datapoints were found on for every day. Less than that indicates problem with data source
   function checkDataAmounts(data){
       var problem_dates = []
       var current_day = startingDate.getUTCDate();
       var previous_date = startingDate;
       var current_date;
       var counter = 0;
       for (var j = 0; j < data.length; j++){
           current_date = datareader.variantToDateTime(data[j].timestamp)
           counter++;

           if (current_day !== current_date.getUTCDate()){
               current_day = current_date.getUTCDate();
               if (counter < 50){

                   problem_dates.push(previous_date)
               }

               counter = 0;
               previous_date = current_date;
           }
       }

       if (current_day !== endingDate.getUTCDate()){
           problem_dates.push(current_date);
           problem_dates.push(endingDate);
       }

       if (problem_dates.length == 1){
           window.showErrorDialog("Problem with data source on "+problem_dates[0].toDateString());
       }
       else if (problem_dates.length > 1){
           window.showErrorDialog("Problem with data source between "+problem_dates[0].toDateString()+ " and "+problem_dates[problem_dates.length - 1].toDateString());
       }
   }


   onServiceChanged: {
       selectedMeters.clear();
       chart.setHistoryLine();
       menu_meter.updateItems();
   }
}

