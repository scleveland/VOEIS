dojo.provide("yogo.ui.MenuLink");
dojo.provide("yogo.ui.MenuLinkBlankTarget");
dojo.require("dijit.MenuItem");

dojo.declare("yogo.ui.MenuLink", dijit.MenuItem, {
    href: "",
    onClick: function(evt) {
        if(this.target == "_blank"){
          window.open(this.href,'_blank');
        }
        else{
          if(this.href) {
              window.location = this.href;
          }
        }
    }
});


dojo.declare("yogo.ui.MenuLinkBlankTarget", dijit.MenuItem, {
    href: "",
    onClick: function(evt) {

          if(this.href) {
              window.open(this.href,'_blank');
          }
    }
});