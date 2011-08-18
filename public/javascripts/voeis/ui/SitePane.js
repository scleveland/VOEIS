dojo.provide("voeis.ui.SitePane");
dojo.require("dijit.layout.ContentPane");
dojo.require("voeis.Server");

dojo.declare("voeis.ui.SitePane", dijit.layout.ContentPane, {
    siteId: "",
    projectId: "",
    closable: true,
  
	  xxxioArgs: {
	      headers: {
	          "Accept": "text/html"
	      }
	  },

    constructor: function() {
        this.server = this.server || voeis.Server.DEFAULT;
        this.watch("siteId", dojo.hitch(this, "_siteUpdated"));

        //if(arguments.length>0) this.projectId = arguments[0];
        //if(arguments.length>1) this.siteId = arguments[1];
    },
    
    _siteUpdated: function() {
        this.setID();
        this.set("title", "Loading...");
        this.set("href", this.server.projectSitePath(this.projectId, this.siteId));
        dojo.when(this.site(), dojo.hitch(this, function(site) {
						var sitename = site.name.slice(0,12);
						if(site.name.length>12) sitename+='...';
						if(site.name.length>20) sitename+=site.name.slice(-8);
						this.set("title", sitename);
						//this.set("title", site.name);
        }));
    },

    setSite: function(projectId,siteId) {
        this.projectId = projectId;
        this.siteId = siteId;
        this.setID();
    },
    
    setID: function() {
        this.set('id',this.projectId+'--'+this.siteId);
    },
    
    site: function() {
        var server = this.server;
        this._siteStore = this._siteStore || server.projectSites(this.projectId);
        return this._siteStore.get(this.siteId);
    }

});

voeis.ui.SitePane._project = voeis.ui.SitePane._project || {};

