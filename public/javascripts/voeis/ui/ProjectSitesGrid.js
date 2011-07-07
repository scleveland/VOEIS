dojo.provide("voeis.ui.ProjectSitesGrid");
dojo.require("dojox.grid.EnhancedGrid");
dojo.require("dojox.grid.enhanced.plugins.Filter");
dojo.require("voeis.Server");

voeis.ui.ProjectSitesGrid = function(projectId, server) {
	  var view_formatter = function(id) {
	  		var link = '<a href="javascript:" onclick="dojo.publish(\'voeis/project/site/selected\', [\''+projectId+'\', '+id+']);"><img src="/images/view.gif" alt="VIEW site" title="VIEW" /></a>';
	  		//var link = '<a href="javascript:" onclick="alert(\'SiteID; \'+id);"><img src="/images/view.gif" alt="VIEW site" title="VIEW" /></a>';
				return '&nbsp;&nbsp;'+link;
		};
	  var close_tab = function() {
	      var map = dijit.byId('split_map');
	      var tabs = dijit.byId('tab_browser');
	      var tab_browser = dijit.byId('right_tabs');    
	      var map_pane = dijit.byId('map_pane');
	      tab_browser.selectChild(map_pane);
	      map.store.remove(projectId);
        dijit.byId('loading_dialog').show();
	      return true;
		};
    var server = server || voeis.Server.DEFAULT;
    var project = server.projects().get(projectId);
    var sitesDataStore = server.projectSitesDataStore(projectId);
    var grid = new dojox.grid.EnhancedGrid({
        id: projectId,
				store: sitesDataStore,
        closable: true,
				onClose: close_tab,
        plugins:{filter:{}},
        structure: [
        		{field: 'id', name: "View", width: "40px", formatter: view_formatter, selectable:false},
            {field: 'name', name: "Site", width: "50%"},
            //{field: 'state', name: "State", width: "auto"},
            {field: 'code', name: "Code", width: "auto"}
            //{field: 'id', name: "SiteID", width: "40px"}
            //{field: 'latitude', name: "Lat", datatype:"number", width: "auto"},
            //{field: 'longitude', name: "Lng", datatype:"number", width: "auto"}
        ]
    });
    dojo.connect(grid, "onRowDblClick", this, function(evt) {
        var item = grid.getItem(evt.rowIndex);
        if(item && item.id) {
            dojo.publish("voeis/project/site/selected", [projectId, item.id]);
        }
    });
    dojo.connect(grid, "onSelected", this, function(idx) {
        var item = grid.getItem(idx);
        var map = dijit.byId('split_map');
	      var map_pane = dijit.byId('map_pane');
	      var tab_browser = dijit.byId('right_tabs');    
        if(item && item.id) {
            //dojo.publish("voeis/project/site/selected", [projectId, item.id]);
						var projId = item.projectId();
		        var marker = map.fetchMarker(projId,item.id);
			      tab_browser.selectChild(map_pane);
		        if(marker) marker.popWin(map);
        }
    });
    dojo.when(project, function(project) {
        grid.set("title", project.name);
    });
    return grid;
};

