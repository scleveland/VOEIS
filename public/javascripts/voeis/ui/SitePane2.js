dojo.provide("voeis.ui.SitePane2");
dojo.require("dijit.layout.ContentPane");

dojo.declare("voeis.ui.SitePane2", dijit.layout.ContentPane, {
	project: '',
	site: '',
	siteIdx: 0,
	closable: true,
	editMode: false,
	paneDivId: 'site_pane_proto',
	style: "margin-top:0;padding-top:0;",
	test: '',
	
	constructor: function(site) {
    //this.tabs = dijit.byId('tab_browser');
		//this.tabs.site_tabs = this.tabs.site_tabs || [];
		this.site_tabs = site_tabs;
		
		//this.project = #{@project.to_json};
		//this.setSitePane();
		//this.setSite(site);
		//this.siteUpdate();
	},

	siteUpdate: function() {

		var sitename = this.site.name.toString();
		var sitename0 = sitename.slice(0,12);
		if(sitename.length>12) sitename0+='...';
		if(sitename.length>24) sitename0+=sitename.slice(-12);
		this.set("title", sitename0);
		
		var siteTag = this.id;
		//var sitePane = document.getElementById(this.paneDivId).cloneNode(true);
		//sitePane = sitePane.nodeValue;
		var sitePane = $('#'+this.paneDivId).html();
		sitePane = sitePane.replace(/site00/g, siteTag);
		
		sitePane = sitePane.replace(/\$\$\$site-name\$\$\$/g, this.site.name);
		
		//PROPERTIES STUFF
		//$('#'+siteTag+'-name-head').html(this.site.name);
		//for(var prop in site_properties) 
		for(var i=0;i<site_properties.length;i++) 
			sitePane = sitePane.replace(new RegExp('\\$\\$\\$'+site_properties[i]+'\\$\\$\\$', 'g'), this.site[site_properties[i]]);
			//$('#show-'+siteTag+' .show_'+site_properties[i]).text(this.site[site_properties[i]]);
			//document.getElementById('show_'+site_properties[i]).value = this.site[site_properties[i]];

		//var variable_table = document.getElementById('variable-table');
		//var sample_table = document.getElementById('sample-table');
		//var variable_table = dijit.byId(siteTag+'-variable-table');
		//var sample_table = dijit.byId('sample-table');
		//alert('>>> '+variable_table);
		//variable_table.selection.selectRange(0,variable_table.rowCount).removeSelectedRows();
		//sample_table.selection.selectRange(0,sample_table.rowCount).removeSelectedRows();
		//for(var i=0;i<this.site_stats.length;i++)
		//	variable_table.addRow(this.site_stats[i]);
		//for(var i=0;i<this.site_samps.length;i++)
		//	sample_table.addRow(this.site_samps[i]);
		//alert('>>>\n'+this.content);
		
		//SHOW VARIABLE STUFF
		var data = [];
		if(this.site_stats.length>0) {
			for(var i=0;i<this.site_stats.length;i++) {
				for(var stat in this.site_stats[i])
					data.push(this.site_stats[i][stat]+'</td><td>');
			};
			data.join('</tr><tr>\n');
		} else {
			data = '<em>&nbsp;&nbsp;&nbsp; - no data available -</em></td><td></td><td></td><td>';
		};
		sitePane = sitePane.replace(/\$\$\$site-variable-data\$\$\$/, data);
		
		//SHOW SAMPLE STUFF
		data = [];
		if(this.site_samps.length>0) {
			sitePane = sitePane.replace(/\$\$\$export-style\$\$\$/, 'display:none;');
			//sitePane = sitePane.replace(/\$\$\$export-style\$\$\$/, '');
			for(var i=0;i<this.site_samps.length;i++) {
				for(var samp in this.site_samps[i])
					data.push(this.site_samps[i][samp]+'</td><td>');
			};
			data.join('</tr><tr>\n');
		} else {
			sitePane = sitePane.replace(/\$\$\$export-style\$\$\$/, 'display:none;');
			//sitePane = sitePane.replace(/\$\$\$export-style\$\$\$/, '');
			//data = '<td><em>&nbsp;&nbsp;&nbsp; no data available</em></td>';
			data = '<em>&nbsp;&nbsp;&nbsp; - no data available -</em></td><td></td><td></td><td>';
		};
		sitePane = sitePane.replace(/\$\$\$site-sample-data\$\$\$/, data);
		sitePane = sitePane.replace(/\$\$\$site-samps\$\$\$/, this.site_samps.toString());

		if(this.editMode) {
			sitePane = sitePane.replace(/\$\$\$edit-style\$\$\$/, '');
			sitePane = sitePane.replace(/\$\$\$show-style\$\$\$/, 'display:none;');
		} else {
			sitePane = sitePane.replace(/\$\$\$show-style\$\$\$/, '');
			sitePane = sitePane.replace(/\$\$\$edit-style\$\$\$/, 'display:none;');
		};
		
		this.set('content', sitePane);

	},

	xxxonClose: function() {
		var new_tabs = [];
		for(var i=0;i<this.tabs.site_tabs.length;i++)
			if(this.site.id!=this.tabs.site_tabs[i])
				new_tabs.push(this.tabs.site_tabs[i]);
		this.tabs.site_tabs = new_tabs;
		return true;
	},

	onClose: function() {
		var new_tabs = [];
		for(var i=0;i<this.site_tabs.length;i++)
			if(this.site.id!=this.site_tabs[i])
				new_tabs.push(this.site_tabs[i]);
		site_tabs = new_tabs;
		return true;
	},

	setSite: function(site) {
		if(site && site.id && site.code && site.idx)
			this.site = site;
		else {
			if(!site) this.site = site_data[0];
			else {
				var siteId = parseInt(site);
				this.site = this.getSite(siteId);
			};
		};
		this.set('id', 'site'+this.site.id);
		this.site_tabs.push(this.site.id);
		//this.tabs.site_tabs.push(this.site.id);
		
		this.siteIdx = this.site.idx;
		this.site_stats = site_stat_data[this.siteIdx];
		this.site_samps = site_samp_data[this.siteIdx];
		this.siteUpdate();
	},
	
	getSite: function(siteId) {
		for(var i=0;i<site_data.length;i++)
			if(site_data[i].id==siteId) 
				return site_data[i];
	},

	setSitePane: function(divId) {
		var paneDivId = divId || self.paneDivId;
		paneDivId = 'site_pane_proto';
		self.paneDivId = paneDivId;
		var sitePane = document.getElementById(paneDivId).cloneNode(true);
		sitePane = sitePane.nodeValue;
		this.sitePane = sitePane;
		//this.content = this.sitePane;
	}

});

voeis.ui.SitePane2.project = voeis.ui.SitePane2.project || {};
