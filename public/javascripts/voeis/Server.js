dojo.provide("voeis.Server");
dojo.require("yogo.xhr.csrf");
dojo.require("dojo.store.JsonRest");
dojo.require("dojo.data.ObjectStore");
dojo.require("voeis.store.Projects");
dojo.require("voeis.store.Sites");
dojo.require("voeis.store.Variables");
yogo.xhr.csrf.load(); // ensure CSRF token is in all xhr requests

dojo.declare("voeis.Server", null, {
    constructor: function(args){
        this.baseUrl = "";
        dojo.mixin(this, args);
    },
    projectsPath: function() {
        return [this.baseUrl, "projects"].join("/");
    },
    projectPath: function(id) {
        return [this.projectsPath(), id].join("/");
    },
    projectSitesPath: function(projectId) {
        return [this.projectPath(projectId), "sites"].join("/");
    },
    projectSitePath: function(projectId, siteId) {
        return [this.projectSitesPath(projectId), siteId].join("/");
    },
    projectMetaTagsPath: function(projectId) {
        return [this.projectPath(projectId), "meta_tags"].join("/");
    },
    projectVariablesPath: function(projectId) {
        return [this.projectPath(projectId), "variables"].join("/");
    },
    projectVariablePath: function(projectId, variableId) {
        return [this.projectVariablesPath(projectId), variableId].join("/");
    },

    /** Stores **/
    projects: function() {
        this._projects = this._projects || voeis.store.Projects(new dojo.store.JsonRest({target:this.projectsPath() + "/"}), this);
        return this._projects;
    },
    projectsDataStore: function() {
        return new dojo.data.ObjectStore({objectStore:this.projects()});
    },

    projectSites: function(projectId) {
        this._projectSites = this.projectSites || {};
        this._projectSites[projectId] = this._projectSites[projectId] || voeis.store.Sites(new dojo.store.JsonRest({target:this.projectSitesPath(projectId) + "/"}), projectId, this);
        return this._projectSites[projectId];
    },
    projectVariables: function(projectId) {
        this._projectVariables = this.projectVariables || {};
        this._projectVariables[projectId] = this._projectVariables[projectId] || voeis.store.Variables(new dojo.store.JsonRest({target:this.projectVariablesPath(projectId) + "/"}), projectId, this);
        return this._projectVariables[projectId];
    },
    projectSitesDataStore: function(projectId) {
        return new dojo.data.ObjectStore({objectStore:this.projectSites(projectId)});
    },
    projectVariablesDataStore: function(projectId) {
        return new dojo.data.ObjectStore({objectStore:this.projectVariables(projectId)});
    },
    
    globalVariablesDataStore: function(){
        var url = location.href;
        var baseURL = url.substring(0, url.indexOf('/', 14));
        return new dojo.data.ObjectStore({objectStore: new dojo.store.JsonRest({target:baseURL + '/variables'})});
    },
    globalMetaTagDataStore: function(){
        var url = location.href;
        var baseURL = url.substring(0, url.indexOf('/', 14));
        return new dojo.data.ObjectStore({objectStore: new dojo.store.JsonRest({target:baseURL + '/meta_tags'})});
    }
    
});

voeis.Server.DEFAULT = new voeis.Server();

voeis.Server.BackboneSync = function(method, model, success, error) {
    var methodFor = {
        'create': function(model) { return 'add'; },
        'update': function(model) { return 'put'; },
        'read': function(model) { 
            return (model instanceof Backbone.Collection) ? 'query' : 'get'
        },
        'delete': function(model) { return 'delete' }
    };

    var argsFor = {
        'add': function(model) {
            return [model.toJSON()];
        },
        'put': function(model) {
            return [model.id, model.toJSON()];
        },
        'read': function(model) {
            return [model.id];
        },
        'delete': function(model) {
            return [model.id];
        },
        'query': function(model) {
            return [model.query || ""];
        }
    };

    var objectStore = model.objectStore;

    var storeMethod = methodFor[method](model);
    var storeArgs = argsFor[storeMethod](model);
    
    var result = objectStore[storeMethod].apply(objectStore, storeArgs);
    result.addCallbacks(success, error);
}
