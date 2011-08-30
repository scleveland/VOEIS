dojo.provide("voeis.ui.SitePane2");
dojo.require("dojox.layout.ContentPane");
dojo.require("dijit.Dialog");
dojo.require("dijit.layout.ContentPane");
//changed to DOJOX.layout.ContentPane -- to allow JS
//had to do this on openVarTab (in proj_show) as well

dojo.declare("voeis.ui.SitePane2", dijit.layout.ContentPane, {
	project: '',
	site: '',
	siteIdx: 0,
	newSite: false,
	closable: true,
	editMode: false,
	preload: true,
	parseOnLoad: false,
	cleanContent: true,
	
	protoDivId: 'site_pane_proto',
	style: "margin-top:0;padding-top:0;",
	test: '',
	
	loaded: false,
	executeScripts: true,
	onLoad: function(){
		console.log('load-done-NOW: ');
		console.log('>>>parseOnLoad:',this.parseOnLoad);
		//if(initSiteForm(this.site.id)) this.loaded = true;
		//init_site_form(this.site);
	},
	
	dialog: dijit.Dialog({
		id: 'dialog ID',
		title: "dialog title",
		content: '',
		style: 'width:400px;'
		}),
	
	dialog_vertical_datum: '',
	dialog_local_projection: '',
	
	constructor: function() {
		//this.tabs = dijit.byId('tab_browser');
		//this.tabs.site_tabs = this.tabs.site_tabs || [];
		
		//this.project = #{@project.to_json};
		//this.setSitePane();
		//this.setSite(site);
		//this.siteUpdate();
	},

	siteUpdate: function() {

		if(this.newSite) {
			var sitename = 'NEW SITE';
			this.set("title", sitename);
		} else {
			var sitename = this.site.name.toString();
			var sitename0 = sitename.slice(0,12);
			if(sitename.length>12) sitename0+='...';
			if(sitename.length>20) sitename0+=sitename.slice(-8);
			this.set("title", sitename0);
		};
		
		var siteTag = this.id;
		//var sitePane = document.getElementById(this.paneDivId).cloneNode(true);
		//sitePane = sitePane.nodeValue;
		//var sitePaneContent = $('#'+this.protoDivId).html();
		var sitePaneContent = pane_proto00;
		
		sitePaneContent = sitePaneContent.replace(/site00/g, siteTag);
		sitePaneContent = sitePaneContent.replace(/\$\$\$site-name\$\$\$/g, sitename);
		
		//PROPERTIES STUFF
		//$('#'+siteTag+'-name-head').html(this.site.name);
		//for(var prop in site_properties) 
		if(this.newSite) sitePaneContent = sitePaneContent.replace(/\$\$\$id\$\$\$/g, '0');
		for(var i=0;i<site_properties.length;i++) 
			sitePaneContent = sitePaneContent.replace(new RegExp('\\$\\$\\$'+site_properties[i]+'\\$\\$\\$', 'g'), this.site[site_properties[i]]);
			//$('#show-'+siteTag+' .show_'+site_properties[i]).text(this.site[site_properties[i]]);
			//document.getElementById('show_'+site_properties[i]).value = this.site[site_proper

		//SHOW VARIABLE STUFF
		var data = '';
		if(this.site_var_stats.length>0) {
			for(var i=0;i<this.site_var_stats.length;i++) {
				data += '<a href="javascript:" onclick="dojo.publish(\'voeis/project/variable\', [';
				data += this.site_var_stats[i].varid+',\''+this.site_var_stats[i].varname+'\','+this.site.id+']);">';
				data += '<strong>'+this.site_var_stats[i].varname+'</strong></a></td><td>\n';
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
		sitePaneContent = sitePaneContent.replace(/\$\$\$site-variable-data\$\$\$/, data);
		
		//SHOW SAMPLE STUFF
		data = '';
		if(this.site_samps.length>0) {
			sitePaneContent = sitePaneContent.replace(/\$\$\$export-style\$\$\$/, '');
			for(var i=0;i<this.site_samps.length;i++) {
				data += this.site_samps[i][0]+'</td><td>\n';
				data += this.site_samps[i][1]+'</td><td>\n';
				data += this.site_samps[i][2]+'</td><td>\n';
				data += this.site_samps[i][3]+'</td></tr>\n';
				data += '<tr class="'+((i+1==this.site_samps.length)?'':'row'+(i+1)%2)+'"><td>'
			};
		} else {
			sitePaneContent = sitePaneContent.replace(/\$\$\$export-style\$\$\$/, 'display:none');
			//sitePaneContent = sitePaneContent.replace(/\$\$\$export-style\$\$\$/, '');
			//data = '<td><em>&nbsp;&nbsp;&nbsp; no data available</em></td>';
			data = '</td><td colspan="2"><em>- no data available -</em></td><td>';
		};
		sitePaneContent = sitePaneContent.replace(/\$\$\$site-sample-data\$\$\$/, data);
		var json_samps = dojo.toJson(this.site_samps).replace(/"/g, '&quot;');
		sitePaneContent = sitePaneContent.replace(/\$\$\$site-samps\$\$\$/, json_samps);
		//console.log(json_samps);

		//sitePaneContent = sitePaneContent.replace(/dojotype_dialog/g, 'dojoType="dijit.Dialog"');

		/*
		if(this.editMode) {
			$('#show-site'+this.site.id).hide();
			$('#edit-site'+this.site.id).show();
		};
		*/

		this.set('content', sitePaneContent);
		dojo.parser.parse(this.domNode);
		
		if(this.newSite) {
			//this.set("title", 'NEW SITE');
			$(this.domNode).find('#show-'+siteTag).hide();
			$(this.domNode).find('#edit-'+siteTag).show();
			//$(this.domNode).find('#'+siteTag+'-name-head').text('NEW SITE');
			$(this.domNode).find('#'+siteTag+'-edit-control').hide();
			console.log('NewSite:',siteTag);
			console.log('domNode.id:',this.domNode.id);
			
		};
		
		//this.refresh();
		//if(this.loaded) initForm(siteTag);

	},

	setSite: function(site) {
		if(parseInt(site)===site) {
			if(parseInt(site)!=0) {
				var siteId = parseInt(site);
				this.site = this.getSite(siteId);
			} else {
				//NEW SITE
				this.newSite = true;
				this.site = {id:0,
										name:'',
										code:'',
										latitude:'',
										longitude:'',
										lat_long_datum_id:'',
										elevation_m:'',
										vertical_datum_id:'',
										local_x:'',
										local_y:'',
										local_projection_id:'',
										pos_accuracy_m:'',
										state:'',
										county:'',
										comments:'',
										description:'',
										};
				this.set('id', 'site0');
				this.site_stats = [];
				this.site_var_stats = [];
				this.site_samps = [];
			};
		} else {
			if(site && site.id && site.code && site.idx)
				this.site = site;
			else
				this.site = this.getSite(0);
		};
		if(!this.newSite) {
			this.set('id', 'site'+this.site.id);

			this.siteIdx = this.site.idx;
			this.site_stats = site_stat_data[this.siteIdx];
			this.site_var_stats = site_var_data[this.siteIdx];
			this.site_samps = site_samp_data[this.siteIdx];
		};
		
		this.dialog.attr('id', this.id+'_dialog');
		
		//CREATE Global Ref
    var pane = this;
    eval(this.id+'ref = pane');
		
		this.siteUpdate();
		
	},
	
	getSite: function(siteId) {
		/*
		for(var i=0;i<site_data.length;i++)
			if(site_data[i].id==siteId) 
				return site_data[i];
		*/
		console.log('GET-SITE: '+siteId);
		//console.log('TYPE-OF: '+(typeof siteId));
		siteId = parseInt(siteId);
		var site;
		psites.fetch({query: {id: siteId},
			onItem: function(item) {
				site = $.extend({},item);
				//site = item;
			},
			onError: function(error,request) {
				console.log('ERROR: '+error);
				site = false;
			}
    });
		return site;
	},

	siteSave: function(update_props) {
		console.log('SAVE-SITE:',update_props);
		if(!update_props.hasOwnProperty('id')) {
			console.log('ERROR: MUST HAVE "ID"');
			return false;
		}
		if(this.newSite) 
			this.site['id'] = 0;
		for(prop in update_props) 
			if(this.site.hasOwnProperty(prop)) 
				this.site[prop] = update_props[prop];
		if(!this.site.id) {
			console.log('ERROR: ID=0');
			return false;
		};
		if(this.newSite) {
			try {
				psites.newItem(this.site);
			}
			catch (e) { 
				console.log('ERROR: DUPLICATE KEY');
			};
		} else {
			//var update = this.getSite(parseInt(update_props.id));
			console.log('UPDATE:',update_props.id);
			psites.fetch({query: {id: update_props.id},
				onComplete: function(items,request) {
					var onSaveError = function(error) {
						console.log('SAVE-ERROR: '+error);
					};
					//### UPDATE ATTRIBUTES
					for(prop in items[0])
						if(update_props.hasOwnProperty(prop) && prop!='id')
							psites.setValue(items[0], prop, update_props[prop])
				},
				onError: function(error,request) {
					console.log('ERROR: '+error);
				}
			});
		};
		this.siteUpdate();
		return this.site.id;
		/*
		var new_data = site_data[this.siteIdx];
		for(prop in update_props) 
			if(new_data.hasOwnProperty(prop)) 
				new_data[prop] = update_props[prop];
		if(this.newSite) {
			site_data.push(new_data);
			site_stat_data.push({'vars':0,'count':'NA','first':'NA','last':'NA'});
			site_var_data.push([]);
			site_samp_data.push([]);
		} else {
			site_data[this.siteIdx] = new_data;
		};
		this.siteUpdate();
		window.scrollTo(0,0);
		*/
	},

	siteFormSave: function(form) {
		var new_data = site_data[this.siteIdx];
		var new_ref_data = site_ref_data[this.siteIdx];
		for(fn in new_data) {
			//var fld = form.elements['site['+fn+']'];
			var fld = form.elements['site_'+fn];
			console.log('FIELD >> '+fn);
			if(fld) {
				new_data[fn] = fld.value;
				console.log('UPDATE >> '+fn+' = '+fld.value);
				if(new_ref_data.hasOwnProperty(fn)) {
					if(fld.type=='select-one' && fld.options.length) {
						console.log('SELECT-FIELD:', fn, fld.options[fld.selectedIndex].value);
						new_data[fn] = fld.options[fld.selectedIndex].text;
						new_data[fn+'_id'] = fld.options[fld.selectedIndex].value;
					};
					//else handle other from.element types
				};
			};
		};
		this.siteSave(new_data);
	},
	
	showDialog: function(contentDiv,title) {
		this.dialog.attr('content', $('#'+contentDiv).html());
		var ttl = title || $('#'+contentDiv).attr('title');
		this.dialog.attr('title', ttl);
		this.dialog.show();
	},
	
	onClose: function() {
		//REMOVE Global Ref
		eval('delete '+this.id+'ref');
		//REMOVE dijit widgets
		$(this.domNode).find('*').each(function(i){
      //console.log('EleID: '+this.id);
      var wid = dijit.byNode(this);
      if(wid) wid.destroy();
      wid = dijit.byId(this.id);
      if(wid) wid.destroy();
    });
		return true;
	}

});

voeis.ui.SitePane2.project = voeis.ui.SitePane2.project || {};
