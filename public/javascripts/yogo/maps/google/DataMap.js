dojo.provide("yogo.maps.google.DataMap");
dojo.require("yogo.maps.google.Map");
dojo.require("dojo.store.Observable");
dojo.require("dojo.store.Memory");
//UPDATE!

dojo.declare("yogo.maps.google.DataMap", yogo.maps.google.Map, {
    store: null,
    query: null,
    
    markerIcon: "",
    
    constructor: function() {
        this._markers = [];
				this._markerhash = {};
        this.setStore(this.store || new dojo.store.Memory());
    },
    setStore: function(store) {
        if(typeof store.notify !== 'function') {
            dojo.store.Observable(store);
        }
        if(this.store !== store) {
            this.store = store;
        }
        this.loadData().refresh();
    },
    items: function() {
        this._items || this.loadData();
        return this._items;
    },
    loadData: function() {
        this._itemsListener && this._itemsListener.cancel();
        this._items = this.store.query();
        this._itemsListener = this._items.observe(dojo.hitch(this, "_itemsChanged"), true);
        return this;
    },
    refresh: function() {
        this.loadData();
        dojo.when(this._mapDfd, dojo.hitch(this, function(){
            this.updateMarkers(true);
        }));
        return this;
    },
    beginItemChanges: function() {
        this._itemsChanging = true;
        return this;
    },
    endItemChanges: function() {
        this._itemsChanging = false;
        this._itemsChanged();
        return this;
    },
    _itemsChanged: function(object, removedFrom, insertedAt) {
        // this should be made more efficient
        //console.log("_itemsChanged");
        //console.debug(arguments);
        if(!this._itemsChanging) {
            this.updateMarkers(true);
        }
    },
    itemTitle: function(item) {
        return item.title || item.name;
    },
    itemPosition: function(item) {
        return new google.maps.LatLng(item.latitude, item.longitude);
    },
    markerFromItem: function(item) {
        var marker = new google.maps.Marker({
            title: this.itemTitle(item),
            position: this.itemPosition(item),
            icon: this.markerIcon
        });
        var link = '<a href="javascript:" onclick="dojo.publish(\'voeis/project/site/selected\', [\''+item.projectId()+'\', '+item.id+']);"><strong>';
				var link2 = '</strong></a>';
				marker.test = 'TESTING-1-2-3';
				marker.projId = item.projectId();
				marker.siteId = item.id;
        marker.info = '<p style="margin:0 15px;">';
        marker.info += link+this.itemTitle(item)+link2+'<br/>(click for '+link+'SITE DETAILS'+link2+')<br/>';
        marker.info += '&nbsp;&nbsp; <strong>Code:</strong> '+item.code+'<br/>';
        marker.info += '&nbsp;&nbsp; <strong>Site ID:</strong> '+item.id+'&nbsp;&nbsp;';
        marker.info += '&nbsp;&nbsp; <strong>State:</strong> '+item.state+'<br/>';
        marker.info += '&nbsp;&nbsp; <strong>Lat/Long:</strong> '+item.latitude+', '+item.longitude;
        //marker.info += item.code+'<br/>Elevation: '+item.elevation_m+'<br/>'
        //marker.info += item.county+', '+item.state;
        marker.info += '</p>';
        marker.window = new google.maps.InfoWindow({content:marker.info});
        marker.popWin = function(map) {
          	//this.setIcon(); this.getIcon();
						for(var i=0;i<map._markers.length;i++) {
            		map._markers[i].window.close();
            		//this._markers[i].setIcon(this.markerIcon);
          	};
          	//this.setIcon(icon_pop);
          	marker.window.open(map._map, marker);
        };
				return marker
    },
    markerBounds: function(markers) {
        var currMarkers = markers || this._markers;
        var bounds;

        if(currMarkers.length > 0) {
            bounds = new google.maps.LatLngBounds();
        }
        else {
            var ne = new google.maps.LatLng(50, -50);
            var sw = new google.maps.LatLng(18, -130);
            bounds = new google.maps.LatLngBounds(sw, ne);
        }
        
        dojo.forEach(currMarkers, function(marker) {
            //console.debug(marker);
            bounds.extend(marker.getPosition());
        });
        return bounds;
    },
    fitBounds: function(bounds) {
        this._map.fitBounds(bounds || this.markerBounds());
    },
    createMarkers: function() {
        return items.map(dojo.hitch(this, "markerFromItem"));
    },
    createHashId: function(projId,siteId) {
				return projId+'>>>'+siteId.toString();
    },
    generateHash: function(markers) {
				var hash_markers = markers || this._markers;
				var markerhash = {};
				for(var i=0;i<hash_markers.length;i++) {
						var marker = hash_markers[i];
						var hashId = this.createHashId(marker.projId, marker.siteId);
						markerhash[hashId] = marker;
				};
				this._markerhash = markerhash;
				return markerhash;
    },
		markers: this._markers,
    updateMarkers: function(updateBounds) {
        //console.log("getting items");
        //console.log("mapping items to markers");
        var items = this.items();
        var newMarkers = this.createMarkers();
				var markerhash = this.generateHash(newMarkers);

        dojo.when(newMarkers, dojo.hitch(this, function(markers) {
            //console.debug(markers);
            //console.log("removing old markers");
            dojo.forEach(this._markers, function(marker) {
                marker.setMap(null); // remove the marker
            }, this);
            
            this._markers = [];
            
            console.log("adding new markers");

            dojo.forEach(markers, function(marker) {
                //console.debug(marker);
                this._markers.push(marker);                
                marker.setMap(this._map);
            }, this);
            this.generateHash();

            if(updateBounds) {
                this.fitBounds();
            }
        }));
    },
		fetchMarker: function(projId,siteId) {
				var hashId = this.createHashId(projId, siteId);
				var marker = this._markerhash[hashId];
				if(marker) return marker;
				return false;
		}
});
