dojo.provide("voeis.ui.SitePane2");
dojo.require("dojox.layout.ContentPane");
dojo.require("dijit.Dialog");
dojo.require("dijit.layout.ContentPane");
//changed to DOJOX.layout.ContentPane -- to allow JS
//had to do this on openVarTab (in proj_show) as well

dojo.declare("voeis.ui.SitePane2", dijit.layout.ContentPane, {
	project: '',
	site: '',
	siteName: '',
	siteIdx: 0,
	newSite: false,
	closable: true,
	editMode: false,
	preload: true,
	parseOnLoad: false,
	doLayout: false,
	cleanContent: true,
	parsedWidgets: [],
	local: {},
	queryCount: 0,
	
	style: "margin-top:0;padding:8px 0 0 10px;overflow:auto;",
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

	siteUpdate: function(properties) {

		if(this.newSite) {
			var sitename = 'NEW SITE';
			this.set("title", sitename);
		} else {
			var sitename = this.site.name.toString();
			if(this.editMode) {
				var sitename0 = 'Edit: Site-'+this.site.id;
				this.set("title", sitename0);
			} else {
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
		};
		
		if(properties) {
			for(prop in properties) {
				if(this.site.hasOwnProperty(prop)) {
					this.site[prop] = properties[prop]==null ? '' : properties[prop];
				}
			};
		};
		
		var siteTag = this.id;
		//var sitePane = document.getElementById(this.paneDivId).cloneNode(true);
		//sitePane = sitePane.nodeValue;
		//var sitePaneContent = $('#'+this.protoDivId).html();
		var sitePaneContent = window.site_pane_proto2;
		if(this.editMode) sitePaneContent = window.site_pane_proto1;
		
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
				data += this.site_var_stats[i].varid+',\''+this.site_var_stats[i].varname+'\',';
				data += this.site.id+',\''+this.id+'_tabs\']);">';
				data += '<strong>'+this.site_var_stats[i].varname+' ['+this.site_var_stats[i].varid;
				data += ']</strong></a></td><td class="smfont">\n';
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
		/***
		data = '';
		if(this.site_samps.length>0) {
			sitePaneContent = sitePaneContent.replace(/\$\$\$export-style\$\$\$/, '');
			for(var i=0;i<this.site_samps.length;i++) {
				data += '<a href="javascript:" onclick="dojo.publish(\'voeis/project/sample\', [';
				data += this.site_samps[i][0]+',\'Sample: '+this.site_samps[i][1]+'\',\''+sitename +'\']);">';
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
		***/
		sitePaneContent = sitePaneContent.replace(/\$\$\$site-sample-count\$\$\$/, this.site_samps[0]);
		sitePaneContent = sitePaneContent.replace(/\$\$\$site-sample-start\$\$\$/, this.site_samps[1]);
		sitePaneContent = sitePaneContent.replace(/\$\$\$site-sample-stop\$\$\$/, this.site_samps[2]);
		
		//DATA QUERY FORM STUFF
		sitePaneContent = sitePaneContent.replace(/\$\$\$site-variable-count\$\$\$/, this.site_var_stats.length.toString());
		data = '';
		var dates1 = [], dates2 = [];
		for(var i=0;i<this.site_var_stats.length;i++) {
			data += '<option value="'+this.site_var_stats[i].varid+'">';
			data += this.site_var_stats[i].varname+' ['+this.site_var_stats[i].varid+']: ';
			data += this.site_var_stats[i].varunits;
			if(parseInt(this.site_var_stats[i].count)) {
				data += '  ['+this.site_var_stats[i].first+'&ndash;'+this.site_var_stats[i].last+']';
				dates1.push(new Date(this.site_var_stats[i].first));
				dates2.push(new Date(this.site_var_stats[i].last));
			};
			data += '</option>\n';
		};
		sitePaneContent = sitePaneContent.replace(/\$\$\$site-variable-select\$\$\$/, data);
		siteDate01 = (dates1.length) ? new Date(Math.min.apply(null,dates1)) : 0;
		siteDate02 = (dates2.length) ? new Date(Math.max.apply(null,dates2)) : 0;
		siteDate1 = siteDate01 ? siteDate01.format('m/dd/yyyy') : '';
		siteDate2 = siteDate02 ? siteDate02.format('m/dd/yyyy') : '';
		siteDate3 = siteDate02 ? new Date(siteDate02.valueOf()-(1000*60*60*24)).format('isoDate') : '';
		siteDate4 = siteDate02 ? siteDate02.format('isoDate') : '';
		sitePaneContent = sitePaneContent.replace(/\$\$\$site-data-start\$\$\$/, siteDate1);
		sitePaneContent = sitePaneContent.replace(/\$\$\$site-data-end\$\$\$/, siteDate2);
		sitePaneContent = sitePaneContent.replace(/\$\$\$site-date-start\$\$\$/, siteDate3);
		sitePaneContent = sitePaneContent.replace(/\$\$\$site-date-end\$\$\$/, siteDate4);
		
		//sitePaneContent = sitePaneContent.replace(/dojotype_dialog/g, 'dojoType="dijit.Dialog"');

		//this.setEdit(this.editMode);

		//NOW PARSE WIDGETS
		this.purgeContent();
		this.set('content', sitePaneContent);
		this.parsedWidgets = dojo.parser.parse(this.domNode);
    //if(window.pane_update) pane_update(this);
		
		if(this.newSite) {
			//this.set("title", 'NEW SITE');
			//$(this.domNode).find('#'+siteTag+'-name-head').text('NEW SITE');
			///$(this.domNode).find('#show-'+siteTag).hide();
			///$(this.domNode).find('#edit-'+siteTag).show();
			$(this.domNode).find('#'+siteTag+'-provenance-row').hide();
			///$(this.domNode).find('#'+siteTag+'-toolbar').hide();
			$(this.domNode).find('#'+siteTag+'-detail-label').hide();
			///$(this.domNode).find('#'+siteTag+'-edit-buttons').hide();
			///$(this.domNode).find('#'+siteTag+'_tabs .dijitTabContainerTop-tabs').hide()
			//setTimeout(function(){
			//	//console.log('SiteGridW:',gridW);
			//	var editPane = dijit.byId('edit-'+siteTag);
			//	var editPane = window[siteTag+'editref']
			//	dijit.byId(siteTag+'_tabs').selectChild(editPane);
			//},200);
			console.log('NewSite:',siteTag);
			console.log('domNode.id:',this.domNode.id);
			
		};
		
		//this.refresh();
		//if(this.loaded) initForm(siteTag);
	},

	setEdit: function(editMode0) {
		var editMode = editMode0 || true;
		if(editMode) {
			$(this.domNode).find('#show-'+this.id).hide();
			$(this.domNode).find('#edit-'+this.id).show();
		} else {
			$(this.domNode).find('#edit-'+this.id).hide();
			$(this.domNode).find('#show-'+this.id).show();
		};
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
										provenance_comment:'',
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
				this.set('id', 'site0edit');
				var this_site = this.site;
				psites.fetch({sort:[{attribute:'id',descending:true}],onComplete:function(items,request){
					if(items.length) {
						//console.log('LAST SITE:',items[0].name.toString());
						this_site.latitude = items[0].latitude.toString();
						this_site.longitude = items[0].longitude.toString();
					};
				}});
				
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
			if(this.editMode) this.set('id', 'site'+this.site.id+'edit');
			else this.set('id', 'site'+this.site.id);

			if(site_stat_data[this.siteIdx]) this.site_stats = site_stat_data[this.siteIdx];
			if(site_var_data[this.siteIdx]) this.site_var_stats = site_var_data[this.siteIdx];
			//if(site_samp_data[this.siteIdx]) this.site_samps = site_samp_data[this.siteIdx];
			if(site_samp_data[this.siteIdx]) this.site_samps = site_samp_data[this.siteIdx];
		};
		
		this.dialog.attr('id', this.id+'_dialog');
		
		//CREATE Global Ref
    var pane = this;
    //eval(this.id+'ref = pane');
		window[this.id+'ref'] = pane;
		
		this.siteUpdate();
		if(!this.newSite) {
			global_resize[this.id] = this.resize;
			this.resize();
		};
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

  submitDataQuery: function() {
    var qstring = [];
    var form = dojo.byId(this.id+'_query');
    if(!form) return;
    for(var i=0; i<form.elements.length; i++) {
      var fld = form.elements[i];
      if(fld.value && fld.name && fld.type!='submit' && fld.type!='button') 
        qstring.push(fld.name+'='+fld.value);
    };
    qstring = qstring.join('&');
    dojo.publish('voeis/project/dataquery/results', [this.site.id, qstring]);
  },

  updateQuerySize: function() {
    //
    var site_id = this.id;
    $('#'+site_id+'-query-size-wait').show();
    dijit.byId(site_id+'-query-submit').set('disabled',true);
    dijit.byId(site_id+'-query-export').set('disabled',true);
    $('#'+site_id+'-query-size').html('0');
    var qsize = 0;
    var form_data = $('#'+site_id+'_query').serializeFormJSON();
    var params = $.map(form_data, function(n, i){
        return  i + "=" + n;
    }).join("&");
    var query_size_url = root_path + "/samples/quick_count.json?" + params;
    $.get(query_size_url, function(data){
        var qsize0 = parseInt(data["count"]);
        //var qsize0 = data["count"];
        console.log('QSIZE0 = '+qsize0);
        if(qsize0) qsize = qsize0;
        //alert("This search yields " + data["count"] + " records.");
        //error_dialog.pop("<br/>This query yields "+data["count"]+" records.<br/><br/>",0,'QUERY SIZE');
        $('#'+site_id+'-query-size').html(qsize.toString());
        $('#'+site_id+'-query-size-wait').hide();
        if(qsize>0) {
          dijit.byId(site_id+'-query-submit').set('disabled',false);
          dijit.byId(site_id+'-query-export').set('disabled',false);
        };
    });
    return qsize;
  },

	resize: function() {
		var Hoffset = 80;
		var editHoffset = 131;
		resizeTabs(this.id+'_tabs',Hoffset,'90%');
		if(this.editMode) {
			var paneH = (global_resize.winH-editHoffset)+'px';
			$('#edit-site'+this.site.id+'edit').css('height',paneH);
		};
	},
	
	purgeContent: function() {
		//REMOVE dijit widgets
		if(this.parsedWidgets) {
			//for(var i=this.parsedWidgets.length-1;i>=0;i--) {}
			for(var i=0;i<this.parsedWidgets.length;i++) {
				//console.log('Wid ID: '+this.parsedWidgets[i].id);
				this.parsedWidgets[i].destroyRecursive(false);
			};
		};
		//REMOVE any dom nodes left
		//NOTE: this may not be needed-- DOJO by handle
		var toDel = this.containerNode.childNodes;
		if(toDel) 
			for(var i=0;i<toDel.length;i++) {
				//console.log('Node: '+toDel[i].nodeName+' ('+toDel[i].id+')');
				this.containerNode.removeChild(toDel[i]);
			};
		//REMOVE resize reference
		delete global_resize[this.id];
	},

	closeTab: function(tabsId) {
    console.log('CLOSE TAB:',this.id.toString());
    var tabs = dijit.byId((tabsId)? tabsId : 'tab_browser');
    var sitePane = this;
    if(sitePane) {
      tabs.removeChild(sitePane);
      sitePane.onClose();
      sitePane.destroyRecursive();  
    };
	},

	onClose: function() {
		//REMOVE Global Ref
		//eval('delete '+this.id+'ref');
		delete window[this.id+'ref'];
		console.log('CLOSE:',this.domNode,this.containerNode)
		this.purgeContent();
		//dojo.byId(this.id);
		//dijit.byId(this.id)
		//this.destroyRecursive();
		return true;
	}

});

voeis.ui.SitePane2.project = voeis.ui.SitePane2.project || {};
