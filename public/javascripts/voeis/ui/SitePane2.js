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
			//document.getElementById('show_'+site_properties[i]).value = this.site[site_proper

		//SHOW VARIABLE STUFF
		var data = '';
		if(this.site_var_stats.length>0) {
			for(var i=0;i<this.site_var_stats.length;i++) {
				data += this.site_var_stats[i].var+'</td><td>\n';
				data += this.site_var_stats[i].count+'</td><td>\n';
				data += this.site_var_stats[i].first+'</td><td>\n';
				data += this.site_var_stats[i].last+'</td></tr>\n';
				data += '<tr><td>'
			};
//				for(var stat in this.site_var_stats[i])
//					data.push(this.site_var_stats[i][stat]+'</td><td>');
//				data.join('</tr><tr>\n');
		} else {
			//data = '<em>&nbsp;&nbsp;&nbsp; - no data available -</em></td><td></td><td></td><td>';
			data = '</td><td colspan="2"><em>- no data available -</em></td><td>';
		};
		sitePane = sitePane.replace(/\$\$\$site-variable-data\$\$\$/, data);
		
		//SHOW SAMPLE STUFF
		data = '';
		if(this.site_samps.length>0) {
			sitePane = sitePane.replace(/\$\$\$export-style\$\$\$/, '');
			for(var i=0;i<this.site_samps.length;i++) {
				data += this.site_samps[i][0]+'</td><td>\n';
				data += this.site_samps[i][1]+'</td><td>\n';
				data += this.site_samps[i][2]+'</td><td>\n';
				data += this.site_samps[i][3]+'</td></tr>\n';
				data += '<tr><td>'
			};
		} else {
			sitePane = sitePane.replace(/\$\$\$export-style\$\$\$/, 'display:none');
			//sitePane = sitePane.replace(/\$\$\$export-style\$\$\$/, '');
			//data = '<td><em>&nbsp;&nbsp;&nbsp; no data available</em></td>';
			data = '</td><td colspan="2"><em>- no data available -</em></td><td>';
		};
		sitePane = sitePane.replace(/\$\$\$site-sample-data\$\$\$/, data);
		sitePane = sitePane.replace(/\$\$\$site-samps\$\$\$/, dojo.toJson(this.site_samps));

		/* ***
		if(this.editMode) {
			sitePane = sitePane.replace(/\$\$\$show-style\$\$\$/, '***TEST***');
			sitePane = sitePane.replace(/\$\$\$edit-style\$\$\$/, '***TEST***');
		} else {
			sitePane = sitePane.replace(/\$\$\$show-style\$\$\$/, 'display:none');
			sitePane = sitePane.replace(/\$\$\$edit-style\$\$\$/, 'display:none');
		};*/
		
		this.set('content', sitePane);
		//this.refresh();

		if(this.editMode) {
			$('#show-site'+this.site.id).hide();
			$('#edit-site'+this.site.id).show();
		};

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
		this.site_var_stats = site_var_data[this.siteIdx];
		this.site_samps = site_samp_data[this.siteIdx];
		this.siteUpdate();
	},
	
	getSite: function(siteId) {
		for(var i=0;i<site_data.length;i++)
			if(site_data[i].id==siteId) 
				return site_data[i];
	},

	siteSave: function(props) {
		var new_data = site_data[this.siteIdx];
		for(prop in props) 
			new_data[prop] = props[prop];
		site_data[this.siteIdx] = new_data;
		this.siteUpdate();
	},

	siteFormSave: function(form) {
		var new_data = site_data[this.siteIdx];
		for(fn in new_data) {
			console.log('FIELD >> '+fn)
			var fld = form.elements['site['+fn+']']
			if(fld) {
				new_data[fn] = fld.value;
				console.log('UPDATE >> '+fn)
			};
		};
		site_data[this.siteIdx] = new_data;
		this.siteUpdate();
	}

});

voeis.ui.SitePane2.project = voeis.ui.SitePane2.project || {};
