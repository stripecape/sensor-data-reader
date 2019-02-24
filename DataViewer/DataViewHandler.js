// DataViewHandler.js provides functions to dynamically create and destroy dataviews,
// and to set correct size and position after dataview is added on destroyed

var config = {
    "data_views": [],
    "row_counts": []
};

var margin = 10;
   
function updateConfigMetaData(){
    var rows = [];
    for (var i = 0; i < config.data_views.length; i++){
        if (rows[config.data_views[i].row] === undefined){
            rows[config.data_views[i].row] = 1;
        }
        else {
            rows[config.data_views[i].row] += 1;
        }
    }

    var filter_nulls = rows.filter(function (el) {
      return el !== undefined;
    });

    config.row_counts = filter_nulls
}

function createDataView(dv_conf){
    var component = Qt.createComponent("DataView.qml");
    if( component.status === Component.Error)
            console.debug("Error: "+ component.errorString());

    var data_view = component.createObject(main_win, {"row": dv_conf.row, "col": dv_conf.col,
                                               "data_type": dv_conf.data_type, "graph_type": dv_conf.graph_type, "menu_height": main_win.menu_height});

    if (data_view === null) {
        console.error("Could not create DataView");
    }

    return data_view;
}

function addNewDataView(graph_type, data_type){
    updateConfigMetaData();
    var pos = getPositionForNewDataView();

    if (pos === false) {
        console.error("No room for new Data View!");
        return false;
    }

    var dv_conf = {"row": pos.row, "col": pos.col, "data_type": data_type, "graph_type": graph_type};
    var dw = createDataView(dv_conf);

    if (!dw){
        return false;
    }

    config.data_views.push(dw);
    repositionDataViews();

    return true;
}

function initializeDataViews(conf){

    for (var i = 0; i < conf.data_views.length; i++){
        var dw = createDataView(conf.data_views[i])
        if (dw){
            config.data_views.push(dw);
        }
    }

    repositionDataViews();
}

function repositionDataViews(){
    updateConfigMetaData();
    console.log(config.row_counts)
    for (var i = 0; i < config.data_views.length; i++){
        // Determine horizontal strech
        var view = config.data_views[i];
        if (config.row_counts[view.row] === 1){
            view.col = 0
            view.state = "semi_fullscreen_horizontal";
            view.saveState();
        }
        else {
            view.state = "normal";
            view.saveState();
        }

        // Determine vertical stretch
        if (config.row_counts.length === 1){
            view.row = 0;

            if (config.row_counts[0] === 2){
                view.state = "semi_fullscreen_vertical";
                view.saveState();
            }
            else {
                view.state = "fullscreen";
                view.saveState();
            }

        }
        view.position()
    }
}

function removeDataView(row, col){
    for (var i = 0; i < config.data_views.length; i++){
        if (config.data_views[i].row === row && config.data_views[i].col === col){
            config.data_views.splice(i, 1);
        }
    }

    repositionDataViews();
}

function getPositionForNewDataView(){
    var row, col;
    if (config.row_counts.length === 2){
        if (config.row_counts[1] === 1){
            row = 1;
            col = 1;
        }
        else if (config.row_counts[0] === 1){
            row = 0;
            col = 1;
        }
        else {
           return false;
        }
    }
    else if (config.row_counts.length === 1){
        row = 1;
        col = 0;
    }
    else {
        row = 0;
        col = 0;
    }

    return { "row": row, "col": col, "width": width, "height": height}
}

function getConfig(){
    updateConfigMetaData();

    var arr = [];
    for (var i = 0; i < config.data_views.length; i++){
        var obj = {"row": config.data_views[i].row, "col": config.data_views[i].col, "data_type": config.data_views[i].data_type, "graph_type": config.data_views[i].graph_type};
        arr.push(obj);
    }

    var conf = {
        "row_counts": config.row_counts,
        "data_views": arr
    };

    return conf;
}


