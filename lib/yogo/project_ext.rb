require 'yogo/project'

module Yogo
  class Project
    extend Permission

    property :is_private,      Boolean, :required => true, :default => false

    has n, :memberships
    has n, :users, :through => :memberships
    has n, :roles, :through => :memberships

    before :destroy, :destroy_cleanup

    def self.extended_permissions
      collection_perms = [ :create_models, :retrieve_models, :update_models, :delete_models, :create_data, :retrieve_data, :update_data, :delete_data ]
      [:manage_users, collection_perms, super].flatten
    end

    private
    def destroy_cleanup
      memberships.destroy
    end
  end
end