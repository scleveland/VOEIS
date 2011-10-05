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
	parsedWidgets: [],
	local: {},
	
	protoDivId: 'site_pane_proto',
	style: "margin-top:0;padding-top:0;",
	test: '',
	
	loaded: false,
	executeScripts: true,
	onLoad: function(){
		console.log('load-done-NOW: ');
		console.log('>>>parseOnLoad:',this.parseOnLoad);
		//if(initSiteForm(this.site.id)) this.loaded = true;
		if(window.init_site_form) init_site_form(this.site.id);
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
			if(sitename.length>12) {
				sitename0+='...';
				if(sitename.length>20) sitename0+=sitename.slice(-8);
				else {
					sitename0 = sitename.slice(0,8)+'...';
					sitename0 += sitename.slice(-6);
				};
			};
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
		//if(this.newSite) sitePaneContent = sitePaneContent.replace(/\$\$\$id\$\$\$/g, '0');
		for(var i=0;i<site_properties.length;i++) 
			sitePaneContent = sitePaneContent.replace(new RegExp('\\$\\$\\$'+site_properties[i]['name']+'\\$\\$\\$', 'g'), this.site[site_properties[i]['name']]);
			//$('#show-'+siteTag+' .show_'+site_properties[i]).text(this.site[site_properties[i]]);
			//document.getElementById('show_'+site_properties[i]).value = this.site[site_proper

		//SHOW VARIABLE STUFF
		var data = '';
		if(this.site_var_stats.length>0) {
			for(var i=0;i<this.site_var_stats.length;i++) {
				data += '<a href="javascript:" onclick="dojo.publish(\'voeis/project/variable\', [';
				data += this.site_var_stats[i].varid+',\''+this.site_var_stats[i].varname+'\','+this.site.id+']);">';
				data += '<strong>'+this.site_var_stats[i].varname+'</strong></a></td><td class="smfont">\n';
				data += this.site_var_stats[i].varunits+'</td><td class="smfont">\n';
				data += this.site_var_stats[i].count+'</td><td class="smfont">\n';
				data += this.site_var_stats[i].first+'</td><td class="smfont">\n';
				data += this.site_var_stats[i].last+'</td></tr>\n';
				data += '<tr class="'+((i+1==this.site_stats.length)?'':'row-lt'+(i+1)%2)+'"><td>'
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
				data += '<a href="javascript:" onclick="dojo.publish(\'voeis/project/sample\', [';
				data += this.site_samps[i][0]+',\'Sample: '+this.site_samps[i][1]+'\']);">';
				data += '<strong>'+this.site_samps[i][1]+'</strong></a></td><td>\n';
				data += this.site_samps[i][2]+'</td><td>\n';
				data += this.site_samps[i][3]+'</td><td class="time">\n';
				data += this.site_samps[i][4]+'</td></tr>\n';
				data += '<tr class="'+((i+1==this.site_samps.length)?'':'row-lt'+(i+1)%2)+'"><td>'
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

		this.purgeContent();
		this.set('content', sitePaneContent);
		this.parsedWidgets = dojo.parser.parse(this.domNode);
    if(window.pane_update) pane_update(this);
		
		if(this.newSite) {
			//this.set("title", 'NEW SITE');
			$(this.domNode).find('#show-'+siteTag).hide();
			$(this.domNode).find('#edit-'+siteTag).show();
			//$(this.domNode).find('#'+siteTag+'-name-head').text('NEW SITE');
			$(this.domNode).find('#'+siteTag+'-edit-control').hide();
			$(this.domNode).find('#'+siteTag+'-provenance-row').hide();
			console.log('NewSite:',siteTag);
			console.log('domNode.id:',this.domNode.id);
			
		};
		
		//this.refresh();
		//if(this.loaded) initForm(siteTag);

	},

	setSite: function(site) {
		if(parseInt(site)==site) {	//integer?
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
										lat_long_datum:'',
										lat_long_datum_id:null,
										elevation_m:null,
										vertical_datum:'',
										vertical_datum_id:null,
										local_x:null,
										local_y:null,
										local_projection:'',
										local_projection_id:null,
										pos_accuracy_m:null,
										state:'',
										county:'',
										comments:'',
										description:'',
										his_id:null,
										time_zone_offset:'-7.0',
										updated_at:pnow,
										updated_by:puser,
										updated_comment:'--',
										created_at:pnow,
										deleted_at:null,
										idx:0,
										data_vars:0,
										data_count:'NA',
										data_start:'NA',
										data_end:'NA'
										};
				this.set('id', 'site0');
			};
		} else {
			if(site && site.id && site.code && site.idx)
				this.site = site;
			else
				this.site = this.getSite(1);
		};
		this.siteIdx = this.site.idx;
		this.site_stats = [];
		this.site_var_stats = [];
		this.site_samps = [];
		if(!this.newSite) {
			this.set('id', 'site'+this.site.id);

			if(site_stat_data[this.siteIdx]) this.site_stats = site_stat_data[this.siteIdx];
			if(site_var_data[this.siteIdx]) this.site_var_stats = site_var_data[this.siteIdx];
			if(site_samp_data[this.siteIdx]) this.site_samps = site_samp_data[this.siteIdx];
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
		//console.log('TYPE-OF: '+(typeof siteId));
		var site;
		var id = siteId || this.site.id;
		//siteId = parseInt(id);
		siteId = ''+id;
		console.log('GET-SITE: '+siteId);
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
		if(!update_props.hasOwnProperty('id') || update_props.id==0) {
			console.log('ERROR: MUST HAVE "ID"');
			return false;
		}
		if(!this.newSite && this.site.id!=update_props.id) {
			console.log('ERROR: WRONG "ID"');
			return false;
		}

		//UPDATE STORE
		
		if(this.newSite) {
			//###NEW SITE
			console.log('NEW:',update_props.id,this.site);
			this.site.idx = site_data.length;
			this.siteIdx = this.site.idx;
			var newsite = {};
			for(prop in this.site) 
				if(update_props.hasOwnProperty(prop)) 
					newsite[prop] = update_props[prop].toString();
				else
					if(this.site[prop]==null) newsite[prop] = null;
					else newsite[prop] = this.site[prop].toString();
			try {
				console.log('>>>CREATE NEW:',newsite);
				newsite['id'] = parseInt(newsite.id);
				psites.newItem(newsite);
			}
			catch (e) { 
				console.log('ERROR: DUPLICATE KEY');
			};
			//##UPDATE STORE ARRAY
			//site_data.push(this.site);
			site_stat_data.push({'vars':0,'count':'NA','first':'NA','last':'NA'});
			site_var_data.push([]);
			site_samp_data.push([]);
			//##UPDATE PMARKERS
			dojo.publish('voeis/project/map/new',[update_props.id]);
			//dojo.publish('voeis/project/map/clear',[]);
		} else {
			//###UPDATE SITE
			//var update = this.getSite(parseInt(update_props.id));
			console.log('UPDATE:',update_props.id,this.site);
			psites.fetch({query: {id: parseInt(update_props.id)},
				onComplete: function(items,request) {
					var onSaveError = function(error) {
						console.log('SAVE-ERROR: '+error);
					};
					//### UPDATE ATTRIBUTES
					for(prop in update_props)
						if(items[0].hasOwnProperty(prop) && prop!='id')
							psites.setValue(items[0], prop, update_props[prop].toString());
				},
				onError: function(error,request) {
					console.log('ERROR: '+error);
				}
			});
			//##UPDATE PMARKERS
			dojo.publish('voeis/project/map/update',[update_props.id]);
		};
		//UPDATE LOCAL SITE
		this.site = this.getSite(update_props.id);
		this.siteUpdate();
    //###SCROLL TO TOP
    //window.scrollTo(0,0);
    $('html #main_container').animate({scrollTop:0}, 'slow');//IE, FF
    $('body #main_container').animate({scrollTop:0}, 'slow');//chrome, don't know if safary works
		return this.site.id;
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
		var ttl = title || $('#'+contentDiv).attr('title') || 'unamed DIALOG';
		this.dialog.attr('title', ttl);
		this.dialog.show();
	},
	
	purgeContent: function() {
		//REMOVE dijit widgets
		if(this.parsedWidgets) 
			for(var i=0;i<this.parsedWidgets.length;i++) {
				//console.log('Wid ID: '+this.parsedWidgets[i].id);
				this.parsedWidgets[i].destroyRecursive(false);
			};
		//REMOVE any dom nodes left
		//NOTE: this may not be needed-- DOJO by handle
		var toDel = this.containerNode.childNodes;
		if(toDel) 
			for(var i=0;i<toDel.length;i++) {
				//console.log('Node: '+toDel[i].nodeName+' ('+toDel[i].id+')');
				this.containerNode.removeChild(toDel[i]);
			};
	},
	
	onClose: function() {
		//REMOVE Global Ref
		eval('delete '+this.id+'ref');
		console.log('CLOSE:',this.domNode,this.containerNode)
		this.purgeContent();
		
		//dojo.byId(this.id);
		//dijit.byId(this.id)
		//this.destroyRecursive();
		return true;
	}

});

voeis.ui.SitePane2.project = voeis.ui.SitePane2.project || {};
