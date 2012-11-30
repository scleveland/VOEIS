dojo.provide("voeis.voeis_util");
 
dojo.require("dijit.form.ValidationTextBox");
dojo.require("dijit.form.SimpleTextarea"); 
dojo.require("dijit.form.Textarea"); 
dojo.require("dijit.Tooltip");
dojo.require("dojox.grid.EnhancedGrid");
dojo.require("dojox.grid.enhanced.plugins.NestedSorting");
dojo.require("dojox.grid.enhanced.plugins.Filter");
dojo.require("dojox.grid.enhanced.plugins.IndirectSelection");
dojo.require("dojo.parser");
dojo.require("dijit.Dialog");


//###############################
//MONKEY-PATCH EnhancedGrid
//provide rowSelect to override clickSelectEvent
(function(){
  // NEW PROPERTY: rowSelect (clickSelectEvent?)
  dojox.grid.EnhancedGrid.prototype.rowSelect = true;
  var oldSelect_clickSelectEvent = dojox.grid.Selection.prototype.clickSelectEvent;
  
  //OVERRIDE clickSelectEvent to DISABLE Row-Select if rowSelect=false
  dojox.grid.Selection.prototype.clickSelectEvent = function(){
    if(this.grid.rowSelect) oldSelect_clickSelectEvent.apply(this,arguments);
  };
})();

// ###############################
// CREATE ValidationTextarea
dojo.provide("dijit_ext.ValidationTextarea"); 
dojo.declare( 
  "dijit_ext.ValidationTextarea", 
  [dijit.form.ValidationTextBox,dijit.form.SimpleTextarea], 
{ 
  regExp: "(.|\\s)*",
  tooltipPosition: ["after"],
  invalidMessage: "This value is required.",
  postCreate: function() {
      this.inherited(arguments);
  },
  validate: function() {
      if (arguments.length==0) {
          return this.validate(false);
      }
      return this.inherited(arguments);
  },
  onFocus: function() {
      if (!this.isValid()) {
          this.displayMessage(this.getErrorMessage());
      }
  },
  onBlur: function() {
      this.validate(false);
  }
});

// ###############################
// NICE Dijit ConfirmDialog
function confirmDialog(title, body, callbackFn, options) {
  var theDialog = new dijit.Dialog({
    id: 'confirmDialog',
    title: title,
    draggable: false,
    style: 'width:220px;',
    onHide: function() {
      theDialog.destroyRecursive();
    }
  });
  for(var prop in options) theDialog.attr(prop,options[prop]);
  
  var callback = function(yes) {
    theDialog.hide();
    theDialog.destroyRecursive(false);
    callbackFn(yes);
  };
  
  var message = dojo.create("p", {
    style: {
      marginTop: "5px"
    },
    innerHTML: body
  });
  var btnsDiv = dojo.create("div", {
    style: {
      textAlign: "center"
    }
  });
  var okBtn = new dijit.form.Button({label: theDialog.buttonOk, 
    id: "confirmDialogOKButton", 
    style: "margin:5px 10px;",
    onClick: function(){ callback(true) } });
  var cancelBtn = new dijit.form.Button({label: theDialog.buttonCancel, 
    id: "confirmDialogCancelButton", 
    style: "margin:5px 10px;",
    onClick: function(){ callback(false) } });
  
  theDialog.containerNode.appendChild(message);
  theDialog.containerNode.appendChild(btnsDiv);
  btnsDiv.appendChild(okBtn.domNode);
  btnsDiv.appendChild(cancelBtn.domNode);

  theDialog.show();
};


//#####################
// FLOT-PLOT FUNCTIONS
var plotutils = {
  // CONSTANTS
  date_format: 'yyyy-mm-dd HH:MM:ss', // format for create/update dates
  plot_default: 0,  // default plot-graph if not in call
  // SET DEFAULT PLOT-GRAPH
  setPlot: function(plot) {
    if(!plot) return;
    this.plot_default = plot;
  },
  // RETURN LIMITS FROM ARRAY OF ITEMS (grid.selection)
  selectionLimits: function(items,plot) {
    var myplot = plot || this.plot_default;
    if(!items || !myplot) return;
    var pdata = myplot.getData()[0].data;
    var selx = items.map(function(item){return pdata[item._0][0]});
    var first = Math.min.apply(Math, selx);
    var last = Math.max.apply(Math, selx);
    var first_item = items[selx.indexOf(first)];
    var last_item = items[selx.indexOf(last)];
    return {0:first_item,1:last_item,values:[first,last]};
  },
  // HIGHLIGHT SELECTION ARRAY (grid.selection)
  highlightItems: function(items,series,plot) {
    var myplot = plot || this.plot_default;
    if(!items || !myplot) return;
    var ser = series || 0;
    var pdata = myplot.getData()[ser].data;
    for(var i=0;i<items.length;i++){
      if(items[i])
				myplot.highlight(ser,items[i]._0);
			//###SOMETIMES GETTING: cannot read property '_0' of null !!
    };
  },
  // HIGHLIGHT RANGE OF GRAPH POINTS
  highlightRange: function(start,end,series,plot) {
    var myplot = plot || this.plot_default;
    if(!myplot) return;
    if(end<start) return;
    var ser = series || 0;
    for(var i=start;i<=end;i++){
      myplot.highlight(ser,i);
    };
  }
}

//#####################
// DOJO STORE FUNCTIONS
var datastore = {
  // CONSTANTS
  date_format: 'yyyy-mm-dd HH:MM:ss', // format for create/update dates
  store_default: false,  // default store if not in call
  // CONVERT DATASTORE ITEM TO PLAIN ITEM
  item: function(item) {
    var myitem = {};
    for(prop in item)
      myitem[prop] = this.value(item[prop]);
    return myitem;
  },
  // CONVERT DATASTORE VALUE TO PLAIN VALUE
  value: function(val) {
    if(val!=null && typeof val=='object' && val.hasOwnProperty(0))
      return val[0];
    return val;
  },
  // SET DEFAULT STORE
  set_store: function(store) {
    var this_store = store || this.store_default;
    var err = 'ERROR:'
    if(this_store && this_store.setValue) return this_store;
    if(this_store.setValue) err += ' NO R/W STORE SET!'
    else err += ' NO STORE SET!'
    console.log(err);
    throw err;
    return;
  },
  // SET IDX IF THE STORE HAS IT??!
  set_idx: function(item, item_store) {
    //var store = item_store || this.store_default;
    var store = this.set_store(item_store);
    if(item.hasOwnProperty('idx') || 
        store._arrayOfAllItems[0] && 
        store._arrayOfAllItems[0].hasOwnProperty('idx')) 
      item['idx'] =  store._arrayOfAllItems.length;
    return item;
  },
  // COUNT (# Items)
  count: function(item_store) {
    var store = this.set_store(item_store);
    var count = -1;
    store.fetch({query: {}, onBegin: function(size,request){
      count = size;
    }, start: 0, count: 0});
    return count;
  },
  // DOJO STORE RAW FETCH QUERY
  fetch_raw: function(query, item_store) {
    var store = this.set_store(item_store);
    var myitems = 0;
    store.fetch({query: query,
      onComplete: function(items,request) {
        console.log('FETCH ITEMS:',items);
        myitems = items;
      },
      onError: function(error,request) {
        console.log('STORE ERROR: ',error.message);
      }
    });
    return myitems;
  },
  // DOJO STORE FETCH QUERY (no array wrapping)
  fetch: function(query, item_store) {
    var store = this.set_store(item_store);
    var items = this.fetch_raw(query, store);
    if(items && items.length) {
      for(var i=0;i<items.length;i++) 
        items[i] = this.item(items[i]);
      return items;
    };
    console.log('DATASTORE: no items found');
    return 0;
  },
  // DOJO STORE RAW FETCH ID
  get_raw: function(id, item_store) {
    //var store = this.set_store(item_store);
    var store = item_store || this.store_default;
    var myid = parseInt(id.toString());
    var q = {id: myid};
    var items = this.fetch_raw(q, store);
    if(items && items.length) return items[0];
    console.log('DATASTORE: found no item- ID:',myid);
    return 0;
  },
  // DOJO STORE FETCH (no array wrapping)
  get: function(id, item_store) {
    //var store = this.set_store(item_store);
    var store = item_store || this.store_default;
    var item = this.get_raw(id, store);
    if(item) return this.item(item);
    return 0;
  },
  // CREATE NEW ITEM IN DOJO STORE
  new: function(item, item_store) {
    var store = this.set_store(item_store);
    item = this.set_idx(item, store);
    //item['used'] = false;
    d = new Date();
    item['created_at'] = d.format(this.date_format);
    item['updated_at'] = d.format(this.date_format);
    try {
      console.log('>>>STORE CREATE NEW:',item);
      store.newItem(item);
    } catch (e) { 
      //console.log('STORE ERROR: DUPLICATE KEY',e);
      console.log('STORE ERROR: '+e.message+' -- args:', e.arguments);
    };
    this.saveDirty('SAVED',store);
    return item;
  },
  // UPDATE DOJO STORE FROM NEW_ITEM (MUST HAVE ID)
  update: function(new_item, item_store) {
    var store = this.set_store(item_store);
    var upd_item;
    //d = new Date();
    //new_item['updated_at'] = d.format(this.date_format);
    //item['updated_at'] = dojo.date.locale.format(d,{datePattern:"yyyy-MM-dd", timePattern:"HH:mm:ssZ"});
    store.fetch({query: {id: parseInt(new_item.id.toString())},
      //onComplete: function(items,request) 
      onItem: function(item) {
        //### UPDATE ATTRIBUTES
        for(prop in new_item)
          if(item.hasOwnProperty(prop) && prop!='id')
            if(new_item[prop]==null) store.setValue(item, prop, null);
            else store.setValue(item, prop, datastore.value(new_item[prop]));
        upd_item = item;
        if(item.hasOwnProperty('updated_at')){
          d = new Date();
          store.setValue(item, prop, d.format(this.date_format));
          item['updated_at'] = d.format(this.date_format);
        };
        upd_item = item;
      },
      onError: function(error,request) {
        console.log('ITEM UPDATE ERROR:',error);
      }
    });
    this.saveDirty('UPDATED',store);
    return upd_item;
  },
  // NEW OR UPDATE ITEM IN DOJO STORE
  new_upd: function(item, item_store) {
    var store = this.set_store(item_store);
    var id = parseInt(item.id.toString());
    console.log('NEW-UPD:',item, store);
    if(store._itemsByIdentity && store._itemsByIdentity[id])
      return this.update(item, store);
    else
      return this.new(item, store);
  },
  // DELETE ITEM IN DOJO STORE
  delete: function(item, item_store) {
    var store = this.set_store(item_store);
    if(typeof item=='number')
      item = this.get_raw(item);
    try {
      store.deleteItem(item);
    }
    catch (e) { 
      console.log('STORE ERROR: '+e.message+' -- args:', e.arguments);
    };
    this.saveDirty('DELETED',store);
  },
  saveDirty: function(mess,item_store) {
    var store = this.set_store(item_store);
    if(store.isDirty())
      store.save({
        onComplete: function() { console.log('STORE ITEM '+mess) },
        onError: function(error) { console.log('STORE '+mess+' ERROR:',error.message) }
      });
	},
	formats: {
    dateTime: function(value) {
      if(value==null || value=='') return '-';
      // Format DateTime string
      console.log('DATE:',value);
      var d = new Date(value);
      //var fmt = d.getMonth()+'/'+d.getFullYear()
      return dojo.date.locale.format(d,{datePattern:"yyyy-MM-dd", timePattern:"HH:mm:ss z"});
      //return d.format("yyyy-mm-dd HH:MM:ss "+tz);
    },
    dataDateTime: function(item) {
      if(item==null || item=='') return '-';
      // FORMAT LocalDateTime string for DataValue item
      //###FORMAT utc offset value: -7.5 = "-07:30" // 3.75 = "+03:45"
      var tzstr = item.utc_offset.toString();
      var tz0 = tzstr.split('.');
      var tz = (tz0[0][0]=='-' ? '-' : '+')+('00'+Math.abs(tz0[0])).slice(-2)+':';
      tz += tz0.length>1 ? (tz0[1]*6).toString().slice(0,2) : '00';
      //var d0 = new Date(item.date_time_utc.toString());
      //var d = new Date(d0.format("UTC:yyyy-mm-dd'T'HH:MM:ss"+tz));
      //var d = new Date(item.local_date_time.toString());
      //var dt = item.local_date_time.toString().slice(0,10);
      //var tm = item.local_date_time.toString().slice(11,19);
      var dt = item.local_date_time.toString().match(/\d\d\d\d-\d\d-\d\d/).toString();
      var tm = item.local_date_time.toString().match(/\d\d:\d\d:\d\d/).toString();
      //console.log('GRID-DATE:',item.date_time_utc.toString(),item.local_date_time.toString(),item.utc_offset.toString());
      //return d.format("yyyy-mm-dd HH:MM:ss "+tz);
      return dt+' '+tm+' '+tz;
    },
    trueFalse: function(value) {
      var checked_img = '<img src="/images/true.png" />';
      var blank_img = '<img src="/images/blank.gif" width="16" height="16" />';
      if(value) return checked_img;
      return blank_img;
    }
  }
};

//***** REFRESH A TAB BY TAB-ID *****
var refreshTab = function(tabId) {
  var pane = dojo.byId(tabId);
  console.log('REFRESH:',tabId,pane);
  if(pane) {
    pane = dijit.byNode(pane);
    pane.refresh();
    return pane;
  };
  return false;
};

