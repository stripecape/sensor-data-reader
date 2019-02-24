import QtQuick 2.9
import QtQuick.Window 2.2
import DataViewer.datareader 1.0
import DataViewer.usermanager 1.0
import DataViewer.dataanalyzer 1.0

import QtQuick.Controls 2.0
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.1
import QtQuick.Controls.Styles 1.4

import "DataViewHandler.js" as DvHandler

ApplicationWindow {

    id: main_win
    color: "#dddddd"
    visible: true
    property int menu_height: 20
    property string background_image
    width: 1000
    height: 800
    title: qsTr("Data Viewer")

    style: ApplicationWindowStyle {
            background: Image {
                source: background_image
            }
        }


    // C++ objects
    DataReader {
        id: datareader
    }

    UserManager {
        id: usermanager
    }
    
    
    DataAnalyzer {
        id: dataanalyzer
    }
    

    // QML Components
    
    menuBar: MenuBar {
        Menu {
            title: "Background  image"
            MenuItem {
                text: "Open"
                onTriggered: dialog_image.open();
            }
            MenuItem {
                text: "Close"
                onTriggered: background_image = ""
            }
        }

        Menu {
            title: "New Data View"
            Menu {
                title: "Current value"
                MenuItem {
                    text: "Temperature"
                    onTriggered: if (!DvHandler.addNewDataView("Current value", "Temperature")) dialog_no_room_for_dv.open();
                }
                MenuItem {
                    text: "Cooling power usage"
                    onTriggered: if (!DvHandler.addNewDataView("Current value", "Cooling power usage")) dialog_no_room_for_dv.open();
                }
                MenuItem {
                    text: "Energy consumption"
                    onTriggered: if (!DvHandler.addNewDataView("Current value", "Energy consumption")) dialog_no_room_for_dv.open();
                }
                MenuItem {
                    text: "Solar panels"
                    onTriggered: if (!DvHandler.addNewDataView("Current value", "Solar panels")) dialog_no_room_for_dv.open();
                }
            }

            Menu {
                title: "History"
                MenuItem {
                    text: "Temperature"
                    onTriggered: if (!DvHandler.addNewDataView("History", "Temperature")) dialog_no_room_for_dv.open();
                }
                MenuItem {
                    text: "Cooling power usage"
                    onTriggered: if (!DvHandler.addNewDataView("History", "Cooling power usage")) dialog_no_room_for_dv.open();
                }
                MenuItem {
                    text: "Energy consumption"
                    onTriggered: if (!DvHandler.addNewDataView("History", "Energy consumption")) dialog_no_room_for_dv.open();
                }
                MenuItem {
                    text: "Solar panels"
                    onTriggered: if (!DvHandler.addNewDataView("History", "Solar panels")) dialog_no_room_for_dv.open();
                }
            }
            Menu {
                title: "Graph"
                MenuItem {
                    text: "Temperature"
                    onTriggered: if (!DvHandler.addNewDataView("Graph", "Temperature")) dialog_no_room_for_dv.open();
                }
                MenuItem {
                    text: "Cooling power usage"
                    onTriggered: if (!DvHandler.addNewDataView("Graph", "Cooling power usage")) dialog_no_room_for_dv.open();
                }
                MenuItem {
                    text: "Energy consumption"
                    onTriggered: if (!DvHandler.addNewDataView("Graph", "Energy consumption")) dialog_no_room_for_dv.open();
                }
                MenuItem {
                    text: "Solar panels"
                    onTriggered: if (!DvHandler.addNewDataView("Graph", "Solar panels")) dialog_no_room_for_dv.open();
                }
            }
        }
    }

    MessageDialog {
        id: dialog_no_room_for_dv
        title: "No room for new data view!"
        text: "Maximum amount of dataviews that can be open is 4. Close a view before opening a new one."
        onAccepted: {
            this.close()
        }
    }

    FileDialog {

        id: dialog_image
        title: "Please choose a background image"
        folder: shortcuts.home
        nameFilters: [ "Image files (*.jpg *.png)" ]
        selectMultiple: false
        onAccepted: {
            main_win.background_image = fileUrl
            dialog_image.close()
        }
        onRejected: {
            dialog_image.close()
        }
        Component.onCompleted: visible = false
    }


    // Signal handlers

    signal dataViewClosed(int row, int col)

    onDataViewClosed: {
        console.log("closed: "+row+", "+col)
        DvHandler.removeDataView(row, col);
    }

    Component.onCompleted: {
        var config = JSON.parse(usermanager.getPreviousConfig());

        DvHandler.initializeDataViews(config);
        if ('bg_img' in config) background_image = config.bg_img;
        var services = datareader.getServices();
        for (var i = 0; i < services.length; i++){
            datareader.getMeters(services[i]);
        }
    }

    Component.onDestruction: {
        var config = DvHandler.getConfig();
        config.bg_img = background_image;
        usermanager.saveConfig(JSON.stringify(config));
    }
}




