dojo.provide("voeis.ui.ProjectSitesGrid");
dojo.require("dojox.grid.EnhancedGrid");
dojo.require("dojox.grid.enhanced.plugins.Filter");
dojo.require("voeis.Server");

voeis.ui.ProjectSitesGrid = function(projectId, store, server) {
	  var view_formatter = function(id) {
  		var link = '<a href="javascript:" onclick="dojo.publish(\'voeis/project/site/popped-selected\', [\''+projectId+'\', '+id+']);"><img src="/images/view.gif" alt="VIEW site" title="VIEW" /></a>';
  		//var link = '<a href="javascript:" onclick="alert(\'SiteID; \'+id);"><img src="/images/view.gif" alt="VIEW site" title="VIEW" /></a>';
			return '&nbsp;&nbsp;'+link;
		};
		var close_tab = function() {
      //dijit.byId('loading_dialog').show();
  		var map = dijit.byId('split_map');
      var tabs = dijit.byId('tab_browser');
      var tab_browser = dijit.byId('right_tabs');
      var map_pane = dijit.byId('map_pane');
			var pgrid = dijit.byId('projects_table');
      tab_browser.selectChild(map_pane);
				for(var i=0; i<pgrid.rowCount; i++)
					if(grid.id==pgrid.getItem(i).id) {
						pgrid.selection.remove(i);
						break;
					};
     	map.store.remove(projectId);
      return true;
		};
    var server = server || voeis.Server.DEFAULT;
    var project = server.projects().get(projectId);
    var sitesDataStore = store || server.projectSitesDataStore(projectId);
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
				//dojo.publish("voeis/project/site/selected", [projectId, item.id]);
			}
		});
		dojo.connect(grid, "onSelected", this, function(idx) {
			var item = grid.getItem(idx);
			if(item && item.id) {
				//dojo.publish("voeis/project/site/selected", [projectId, item.id]);
				var projId = item.projectId();
				dojo.publish("voeis/project/site/popped", [projId, item.id]);
			}
		});
		dojo.when(project, function(project) {
			grid.set("title", project.name);
		});
		return grid;
};

