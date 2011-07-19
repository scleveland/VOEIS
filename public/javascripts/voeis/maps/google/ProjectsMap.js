dojo.provide("voeis.maps.google.ProjectsMap");
dojo.require("yogo.maps.google.DataMap");
dojo.require("dojo.DeferredList");
//UPDATE!

dojo.declare("voeis.maps.google.ProjectsMap", yogo.maps.google.DataMap, {
    createMarkers: function() {
        var dfd = new dojo.Deferred();

        var allSites = dojo.when(this.items(), dojo.hitch(this, function(projects){
            console.log("mapping projects -> sites")
            console.debug(projects);
            var projectSites = dojo.map(projects, function(p){
                return p.sites();
            }, this);
            return new dojo.DeferredList(projectSites);
        }));

        
        var flatSites = dojo.when(allSites, dojo.hitch(this, function(dfdList) {
            console.log("flattening sites array");
            console.debug(dfdList);
            var flat = []
            
            dojo.forEach(dfdList, function(s){
                console.debug(s);
                if(s[1]) {
                    flat = flat.concat(s[1]);
                }
            });
            
            return flat;
        }));

        dojo.when(flatSites, dojo.hitch(this, function(sites){
            console.log("mapping sites -> markers");
            console.debug(sites);
            var markers = dojo.map(sites, dojo.hitch(this, "markerFromItem"));
            console.debug(markers);
            dfd.resolve(markers);
        }));

        
        return dfd;
    },

    markerFromItem: function(item) {
        var marker = this.inherited(arguments);
        marker._voeisSite = item;

        var markerClick = dojo.hitch(this, function(evt){
            this._siteClick(item,marker);
        });

        google.maps.event.addListener(marker, 'click', markerClick);
        return marker;
    },

		_siteClick: function(site,marker) {
        //dojo.publish("voeis/project/site/selected", [site.projectId(), site.id]);
				marker.popWin(this);
        // click table
        var grid = dijit.byId(site.projectId());
	      var tabs = dijit.byId('tab_browser');
        if(grid) {
		      tabs.selectChild(grid);
					var col = grid.layout.cells[1];
	        grid.selection.clear();
	        for(var i=0; i<grid.rowCount; i++)
	          if(site.id==grid.getItem(i).id) {
	            grid.scrollToRow(i);
	            grid.focus.setFocusCell(col,i);
	            grid.focus.focusGrid();
		        	grid.selection.addToSelection(i);
	            break;
	          };
        	//grid.selection.addToSelection(site);
				};
    }
});
