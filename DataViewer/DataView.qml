import QtQuick 2.0
import QtQuick.Controls 1.4
import QtQuick.Controls 2.0

Rectangle {
    id: box
    radius: 10
    color: "#aec5c1"

    anchors.topMargin: 10 + menu_height
    anchors.bottomMargin: 10
    anchors.leftMargin: 10
    anchors.rightMargin: 10

    state: "normal"

    property string data_type: "Temperature"
    property string graph_type: "Current value"
    property int row
    property int col
    property int menu_height
    property string previous_state: "normal"

    // QML Components

    // Closes dataview
    RoundButton {
        id: btn_close
        text: "x"

        anchors.top: parent.top
        anchors.right: parent.right

        onClicked: close()
    }

    // Toggles full screen on / off
    RoundButton {
        id: btn_resize
        text: "\u25A1"

        anchors.top: parent.top
        anchors.right: btn_close.left

        onClicked: toggleFullscreen()
    }

    // Opens menu to set data type for dataview
    Button {
        background: Rectangle {
            radius: 10
            color: "#dddddd"
        }

        height: 20
        id: btn_open_dt_menu
        text: data_type
        onClicked: menu_data_type.open()
        anchors.top: box.top
        anchors.topMargin: 10
        anchors.rightMargin: 10
        anchors.right: btn_resize.left

        Menu {
            id: menu_data_type
            title: "Data Type"

            MenuItem {
                text: "Temperature"
                onTriggered: {
                    data_type = this.text
                }
            }

            MenuItem {
                text: "Energy consumption"
                onTriggered: {
                    data_type = this.text
                }
            }

            MenuItem {
                text: "Cooling power usage"
                onTriggered: {
                    data_type = this.text
                }
            }

            MenuItem {
                text: "Solar panels"
                onTriggered: {
                    data_type = this.text
                }
            }
        }
    }

    // Opens menu to set data type for dataview
    Button {

        background: Rectangle {
            radius: 10
            color: "#dddddd"
        }

        height: 20
        id: btn_open_gt_menu
        text: graph_type
        onClicked: menu_graph_type.open()
        anchors.top: box.top
        anchors.topMargin: 10
        anchors.rightMargin: 10
        anchors.right: btn_open_dt_menu.left

        Menu {
            id: menu_graph_type
            title: "Graph type"
            MenuItem {
                text: "Current value"
                onTriggered: {
                    graph_type = this.text
                }
            }

            MenuItem {
                text: "History"
                onTriggered: {
                    graph_type = this.text
                }
            }

            MenuItem {
                text: "Graph"
                onTriggered: {
                    graph_type = this.text
                }
            }

        }
    }

    // DataWindow that shows the actual data (Current value, history or graph for given data type)
    DataWindow {
        graphType: graph_type
        dataType: data_type
    }


    // States and animations
    states: [
        State {
            name: "fullscreen";
            PropertyChanges {
                target: box
                width: parent.width - 20
                height: parent.height - menu_height - 20
                z: 1
            }
        },
        State {
            name: "semi_fullscreen_horizontal";
            PropertyChanges {
                target: box
                width: parent.width - 20
                height: parent.height / 2 - 20 - menu_height / 2
            }
        },
        State {
            name: "semi_fullscreen_vertical";
            PropertyChanges {
                target: box
                width: parent.width / 2 - 20
                height: parent.height - 20 - menu_height
            }
        },
        State {
            name: "normal";
            PropertyChanges {
                target: box
                width: parent.width / 2 - 20
                height: parent.height / 2 - 20 - menu_height / 2
            }
        }
    ]

    transitions: Transition {
        NumberAnimation {
            properties: "width,height"
            easing.type: Easing.InOutQuad
        }
     }

    Component.onCompleted: {
        position();
    }

    // ------------------------------ functions -------------------------------

    // Opens dataview in fullscreen mode and return it back to normal
    function toggleFullscreen(){
        if (state !== "fullscreen") {
            state = "fullscreen";
        }
        else {
            state = previous_state;
        }
    }

    // Close a dataview
    function close(){
       dataViewClosed(row, col);
       visible = false;
    }

    // Set correct position for dataview using anchors
    function position(){
        if (row === 0){
            anchors.bottom = undefined
            anchors.top = parent.top;
        }
        else {
            anchors.top = undefined
            anchors.bottom = parent.bottom;
        }

        if (col === 0){
            anchors.right = undefined
            anchors.left = parent.left;
        }
        else {
            anchors.left = undefined
            anchors.right = parent.right;
        }
    }

    // Save the previous state of dataview (when exiting fullscreen mode this is the state the dataview returns to)
    function saveState(){
        previous_state = state;
    }
}
