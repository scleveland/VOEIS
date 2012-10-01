# Yogo Data Management Toolkit
# Copyright (c) 2010 Montana State University
#
# License -> see license.txt
#
# FILE: routes.rb
#
#

require 'resque/server' 


Yogo::Application.routes.draw do
  
  #Project Namespace
  resources :projects do
    member do
      post :upload
      get  :collect_data
    end
    collection do
      get  :search
      post :export
      post :publish_his
      get  :get_user_projects
      get  :admin
    end
    resources :memberships
    #Voeis Project Models scope
    scope :module => "voeis" do
      resources :search do
        collection do
          post :export
          get :download_deq
          get :quick_count
        end
      end
      resources :sites do
        collection do
          post :save_site
          get :versions
          get :site_samples
          get :graphs
        end
      end
      resources :data_streams do
        collection do
          get  :add
          get  :query
          get  :data_stream_sensor_variables
          get  :site_data_streams
          post :pre_upload
          post :create_stream
          post :search
          post :upload
          post :export
          post :data
        end
      end
      resources :vertical_datum_c_vs do
        collection do
          get :list
          get :versions
        end
      end
      resources :spatial_references do
        collection do
          get :list
          get :versions
        end
      end
      resources :variable_name_c_vs do
        collection do
          get :list
          get :versions
        end
      end
      resources :quality_control_levels do
        collection do
          get :list
          get :versions
        end
      end
      resources :sample_type_c_vs do
        collection do
          get :list
          get :versions
        end
      end
      resources :value_type_c_vs do
        collection do
          get :list
          get :versions
        end
      end
      resources :data_type_c_vs do
        collection do
          get :list
          get :versions
        end
      end
      resources :sample_medium_c_vs do
        collection do
          get :list
          get :versions
        end
      end
      resources :variables do
        collection do
          get :list
          get :versions
        end
      end
      resources :meta_tags
      resources :data_sets do
        collection do
          get :proto
          
        end
        get :export
      end
      resources :scripts do
        collection do
          get :list
          get :versions
        end
      end
      resources :spatial_offsets
      resources :labs
      resources :units
      resources :apivs do
        collection do
          get :dojo_variables_for_tree
          post :create_project_site
          post :create_project_variable
          post :update_project_site
          put :update_project_variable
          put :update_voeis_variable
          get :get_project_sites
          get :get_voeis_sites
          get :get_voeis_sites
          get :get_project_site
          get :get_project_data_templates
          get :get_project_data_summary
          get :get_project_variables
          get :get_project_variable
          get :get_voeis_variables
          get :get_dojo_voeis_variables
          get :get_project_site_variables
          get :get_project_sample
          get :get_project_samples
          get :get_project_sample_measurements
          get :get_data_stream_data
          get :get_project_site_data
          get :get_project_site_sensor_data_last_update
          get :get_project_variable_data
          get :get_project_variable_data_count    
          get :get_project_site_variable_data_count    
          get :get_project_site_variable_data
          get :get_project_site_sensor_values_by_variable
          get :get_project_site_sensor_values_count_by_variable   
          get :get_project_site_sample_values_by_variable
          get :get_project_site_sample_values_count_by_variable     
          get :get_project_site_sample_data_last_update    
          post :upload_logger_data
          post :upload_data
          post :create_project_sample
          post :create_project_sample_measurement
          post :import_voeis_variable_to_project
          post :create_project_sensor_value
          post :create_project_sensor_type
          post :create_project_data_stream
          post :create_project_data_stream_column
          post :create_project_data_set
          post :add_data_to_project_data_set
          post :remove_data_from_project_data_set
          post :upload_simulation
          get  :get_project_data_stream_data
          get :get_job_status
          get :get_project_jobs
          get :get_project_data_set_data
          get :get_project_data_sets
        end
      end
      resources :sensor_values do
        collection do
          get   :new_field_measurement
          post   :create_field_measurement
        end
      end
      resources :sensor_types
      resources :jobs
      resources :data_stream_columns
      resources :samples do
        collection do
          get   :query
          get   :site_sample_variables
          post  :export
          get   :search
          post  :search
        end
      end
      resources :sample_materials
      resources :lab_methods
      resources :field_methods
      resources :sources
      resources :logger_imports do
        collection do
          post :pre_upload
          post :create_stream
          post :upload
          post :export
          get  :field_measurement
          get  :pre_process_logger_file_upload
          post :store_logger_data_from_file
          post  :pre_process_logger_file
        end
      end
      resources :data_values do
        collection do
          get :versions
          get :pre_process
          post :batch_update
          post  :pre_process_samples_file
          get  :pre_process_samples_file_upload
          post :store_samples_and_data_from_file
          get  :pre_process_samples
          get  :pre_process_sample_file_upload
          post :pre_process_sample_file
          get  :pre_process_samples_and_data
          get  :pre_process_varying_samples_with_data
          post :pre_upload
          post :pre_upload_samples_and_data
          post :pre_upload_varying_samples_with_data
          post :store_sample_data
          post :store_samples_and_data
          post :store_varying_samples_with_data
        end
      end
    end
  end

  #HIS namespace
  namespace :his do
    resources :data_type_c_vs
    resources :censor_code_c_vs
    resources :sources
    resources :methods
    resources :variables
    resources :sites
    resources :data_values
  end

  resources :users do
    collection do
      post :api_key_update
      post :change_password
      get :reset_password
      post :email_reset_password
    end
    resources :memberships
  end

  #Global Namespace
  resources :roles
  resources :units
  resources :sources
  resources :spatial_offset_types
  resources :visits
  resources :campaigns
  resources :system_roles
  resources :variables
  resources :meta_tags
  resources :memberships
  resources :settings
  resources :search
  resources :vertical_datum_c_vs do
    collection do
      get :versions
    end
  end
  resources :spatial_references do
    collection do
      get :versions
    end
  end
  resources :variable_name_c_vs do
    collection do
      get :versions
    end
  end
  resources :quality_control_levels do
    collection do
      get :versions
    end
  end
  resources :sample_type_c_vs do
    collection do
      get :versions
    end
  end
  resources :value_type_c_vs do
    collection do
      get :versions
    end
  end
  resources :data_type_c_vs do
    collection do
      get :versions
    end
  end
  resources :sample_medium_c_vs do
    collection do
      get :versions
    end
  end
  resources :sample_materials
  resources :sensor_type_c_vs
  resources :logger_type_c_vs
  resources :speciation_c_vs
  resources :general_category_c_vs
  resources :labs
  resources :lab_methods
  resources :field_methods
  resource  :password,                :only => [:show, :update, :edit]
  resources :dashboards,              :only => [:show], :requirements => {:id => /[\w]+/}
  resources :pages,                   :only => [:show], :requirements => {:id => /[\w]+/}
  resources :feedback do
    collection do
      post :email
    end
  end
  resources :voeis_mailer
  
  resource :user_session do
    collection do
      get :get_api_key
    end
  end
  resque_constraint = lambda do |request|
    User.current.admin?
  end

  # constraints resque_constraint do
  #   mount Resque::Server, :at => "/admin/resque"
  # end
  

    # constraints CanAccessResque.matches?() do
    #     mount Resque::Server.new, at: 'resque'
    #   end
    # 
  mount SecureResqueServer.new, :at => "/resque"
  # resource :user_session,   :only => [ :show, :new, :create, :destroy, :get_api_key ], :collection=>{:get_api_key => 'get'}
  match '/logout' => 'user_sessions#destroy', :as => :logout
  match '/login' => 'user_sessions#new', :as => :login
  match '/' => 'pages#show', :id => :home, :as => :root
end

