import QtQuick 2.0
import QtQuick.Controls 2.0
import QtCharts 2.2
import QtQuick.Window 2.2


Item {

    id: lineChart
    anchors.bottom: parent.bottom
    visible: true
    height: box.height - 20
    width: box.width - 20

    property string service: parent.dataType
    property string unitX
    property string unitY
    property date startingDate
    property date endingDate
    property string meterNameY
    property string meterNameX
    property bool dateSelected: false
    property double correlation


 //------------------------------- Choose x-axis ---------------------------------

    Button {

        background: Rectangle {
            radius: 10
            color: "#dddddd"
        }

        height: 20
        id: x_axis_meters_btn
        text: "Choose x-axis"
        onClicked: x_axis_menu.open()
        anchors.top: lineChart.top
        anchors.right: parent.right
        anchors.topMargin: 10
        anchors.rightMargin: 40

        // Menu for choosing the x-axis meter.
        Menu {

            id: x_axis_menu
            height: x_axis_model.count * 52
            width: 235

            contentItem: ListView {
                id: list
                orientation: Qt.Vertical
                model: x_axis_model
                delegate: RadioDelegate {
                    text: name
                    checked: index == 0
                    ButtonGroup.group: buttonGroupX
                    onToggled: {
                        meterNameX = name
                        x_axis_menu.close()
                        chart.addLineSeries()
                        x_axis_meters_btn.text = name
                    }
                }


            // Adds meters to the model.
            function addMetersToModel() {

                var services = datareader.getServices()
                for (var i = 0 ; i < services.length ; ++i) {
                    var service = services[i]
                    var meters = datareader.getMeters(service)
                    for (var j = 0 ; j < meters.length; ++j) {
                        var meter_name = datareader.getMeterName(meters[j]);
                        x_axis_model.append({"name": meter_name})

                    }
                }
            }
            // Model for storing all the meters.
            ListModel {
                id: x_axis_model
            }

            ButtonGroup {
                id: buttonGroupX
            }

            Component.onCompleted: addMetersToModel()

            }
        }
    }

    // ----------------------------- Choose y-axis -------------------------------

    Button {

        background: Rectangle {
            radius: 10
            color: "#dddddd"
        }

        height: 20
        id: y_axis_meters_btn
        text: "Choose y-axis"
        onClicked: y_axis_menu.open()
        anchors.top: lineChart.top
        anchors.right: x_axis_meters_btn.left
        anchors.topMargin: 10
        anchors.rightMargin: 40


        // Menu for choosing the y-axis meter.
        Menu {

            id: y_axis_menu
            height: y_axis_model.count * 52
            width: 235
            contentItem: ListView {
                id: y_axis_list
                model: y_axis_model
                delegate: RadioDelegate {
                    text: name
                    checked: index == 0
                    ButtonGroup.group: buttonGroupY
                    onToggled: {
                        meterNameY = name
                        y_axis_menu.close()
                        chart.addLineSeries()
                        y_axis_meters_btn.text = name
                    }
                }

                function addMetersToModel() {

                    var services = datareader.getServices()
                    for (var i = 0 ; i < services.length ; ++i) {
                        var service = services[i]
                        var meters = datareader.getMeters(service)
                        for (var j = 0 ; j < meters.length; ++j) {
                            var meter_name = datareader.getMeterName(meters[j]);
                            y_axis_model.append({"name": meter_name})      
                        }
                    }
                }

                Component.onCompleted: addMetersToModel()
            }
            ButtonGroup {
                id: buttonGroupY
            }
            // Model for storing all the meters.
            ListModel {
                id: y_axis_model
            }

        }

    }

    //------------------------------- Correlation text ------------------------------

    // Shows correlation:
    Text {
        id: correlationText
        text: "Correlation: "+ correlation
        anchors.left: lineChart.left
        anchors.leftMargin: 40
        anchors.top: lineChart.top
        height: 10
        visible: false

    }

    // ------------------------------------ Chart ------------------------------------

   ChartView {

        title: "Comparing two meters"
        id: chart
        width: parent.width - 40
        theme: ChartView.ChartThemeHighContrast
        antialiasing: true
        anchors.top: x_axis_meters_btn.bottom
        anchors.bottom: parent.bottom
        visible: true

        property string chartName



        ValueAxis {
            id: valueAxisX
            titleText: unitX
            gridVisible: true
            labelsVisible: true
            min: -10
            max: 10
        }

        ValueAxis {
            id: valueAxisY
            titleText: unitY
            min: -10
            max: 10


        }

        PinchArea {
            anchors.fill: parent
            onPinchUpdated: chart.zoom(pinch.scale);
        }

        // Function for drawing the line.
        function addLineSeries() {

            // Checks that the user has selecter the time interval.
            if (!dateSelected){
                lineChart.parent.errorTextString  = "Select dates!";
                return;
            }

            chart.removeAllSeries()

            // Checks that the user has selected the meters.
            if (meterNameX.length === 0 || meterNameY.length === 0){
                lineChart.parent.errorTextString  = "Select meters!";
                return;
            }

            historyList.parent.errorTextString = ""

            var max_x = -Infinity;
            var min_x = Infinity;

            var max_y = -Infinity;
            var min_y = Infinity;

            var name = "Dependency"
            var meter_x_id = datareader.getMeterId(meterNameX)
            var meter_y_id = datareader.getMeterId(meterNameY)
            var service_x = datareader.getServiceToMeter(meter_x_id)
            var service_y = datareader.getServiceToMeter(meter_y_id)
            
            // Retrieves initial data
            var dataX = datareader.getData(service_x, meter_x_id, startingDate, endingDate)
            var dataY = datareader.getData(service_y, meter_y_id, startingDate, endingDate)
            
            // Connects the two datasets together.
            var data = dataanalyzer.connectData(dataX, dataY)

            // If there was an error in retrieving the data, an error dialog pops up.
            if (!datareader.getLatestRetVal()) {
                window.showErrorDialog();
            } else if (data.length === 0) {
                window.showErrorDialog("No data to show!")
            } else {

                var line = chart.createSeries(ChartView.SeriesTypeLine, name, valueAxisX, valueAxisY)

                for (var i = 0; i < data.length; ++i) {
                    if (parseFloat(data[i].x) > max_x) max_x = parseFloat(data[i].x);
                    if (parseFloat(data[i].x) < min_x) min_x = parseFloat(data[i].x);

                    if (parseFloat(data[i].y) > max_y) max_y = parseFloat(data[i].y);
                    if (parseFloat(data[i].y) < min_y) min_y = parseFloat(data[i].y);

                    line.append(data[i].x, data[i].y)
                }

                // Checks for any dates with no data.
                checkDataAmounts(data)

                valueAxisX.max = max_x + Math.abs(0.1 * (max_x + 1))
                valueAxisX.min = min_x - Math.abs(0.1 * (min_x - 1))

                valueAxisY.max = max_y + Math.abs(0.1 * (max_y + 1))
                valueAxisY.min = min_y - Math.abs(0.1 * (min_y - 1))


                unitX = datareader.getUnit(meter_x_id)
                unitY = datareader.getUnit(meter_y_id)
                
                correlation = dataanalyzer.getCorrelation(data).toFixed(2);
                correlationText.visible = true
            }
        }

    }


   // --------------------------------- functions ---------------------------------


    // Sets the time interval
   function setTimeInterval(dateStart, dateEnd) {
       if (dateStart <= dateEnd) {
           startingDate = dateStart
           endingDate = dateEnd
           dateSelected = true
           chart.addLineSeries();
       } else {
           dateSelected = false
           parent.errorTextString = "The date selected first can't be bigger than the second date!"
       }
   }

   // Check for any faulty dates in the data.
   function checkDataAmounts(data){
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
                   window.showErrorDialog("Problem with data source starting on "+previous_date.toDateString());
                   return;
               }

               counter = 0;
               previous_date = current_date;
           }
       }

       console.log(current_day+" "+endingDate.getUTCDate())
       if (current_day !== endingDate.getUTCDate()){
           window.showErrorDialog("Problem with data source on "+current_date.toDateString());
       }
   }


}
