$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require "rvm/capistrano" 
require "bundler/capistrano"

set :application, "voeis"
set :rvm_ruby_string, 'ruby-1.9.2-p180@passenger'
set :bundle_cmd,      "/usr/local/rvm/gems/ruby-1.9.2-p180/bin/bundle"
set :scm, :git
set :repository,  "git://github.com/yogo/VOEIS.git"
set :shell, "/bin/bash"
set :use_sudo,    false
set :deploy_via, :remote_cache
set :copy_exclude, [".git"]
set :user, "rails"
#set :user, "sean.cleveland"
set :deploy_to, "/var/rails"
#set :deploy_to, "/var/voeis"

set :workers, { "process_file" => 2 }

desc "Setup Development Settings"
task :development do
  set :branch, "resque"
  role :web, "voeis-dev.rcg.montana.edu"
  role :app, "voeis-dev.rcg.montana.edu"
  role :db,  "voeis-dev.rcg.montana.edu", :primary => true
end

desc "Setup Production Settings"
task :production do

  set :branch, "production"
  role :web, "voeis.rcg.montana.edu"
  role :app, "voeis.rcg.montana.edu"
  role :db,  "voeis.rcg.montana.edu", :primary => true

end

desc "Setup Production Settings"
task :production2 do

  set :branch, "production"
  role :web, "voeis2.rcg.montana.edu"
  role :app, "voeis2.rcg.montana.edu"
  role :db,  "voeis2.rcg.montana.edu", :primary => true

end

namespace :deploy do

  task :start, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end

  task :stop, :roles => :app do
    # Do nothing.
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end
end

namespace :db do
  desc "Seed initial data"
  task :seed, :roles => :app do
    run "bash -c 'cd #{current_path} && RAILS_ENV=production rake db:seed'"
  end

  desc  "Clear out test data"
  task :clear, :roles => :app do
    run "bash -c 'cd #{current_path} && bundle exec rake db:drop:all'"
  end

  task :symlink do
    run "ln -nfs #{deploy_to}/#{shared_dir}/config/database.yml #{release_path}/config/database.yml"
  end
  
  desc "Get the remote database and save it locally"
  task :get_remote_database do
    db.run_backup_task
    db.download_backup_files
  end
  
  task :download_backup_files do
    download("#{current_path}/db/backup/", "db/backup/", :recursive => true)
  end
  
  task :run_backup_task do
    run "cd #{current_path}; bundle exec rake yogo:db:backup RAILS_ENV=production"
  end
  
  task :auto_upgrade do
    run "cd #{current_path}; bundle exec rake yogo:db:auto_upgrade RAILS_ENV=production"
  end
end

namespace :docs do
  task :generate do
    run "cd #{current_path}; bundle exec rake yard RAILS_ENV=production"
  end
  
  task :publish do
    run "ln -nfs #{release_path}/doc #{release_path}/public/doc"
  end
end

namespace :assets do
  task :setup do
    run "mkdir -p #{deploy_to}/#{shared_dir}/assets/files"
    run "mkdir -p #{deploy_to}/#{shared_dir}/assets/images"
    run "mkdir -p #{deploy_to}/#{shared_dir}/assets/temp_data"
  end

  task :symlink do
    run "ln -nfs #{deploy_to}/#{shared_dir}/assets/files #{release_path}/public/files"
    run "ln -nfs #{deploy_to}/#{shared_dir}/assets/images #{release_path}/public/images"
    run "ln -nfs #{deploy_to}/#{shared_dir}/assets/temp_data #{release_path}/temp_data"
  end
end

namespace :jobs do
  desc "Start up worker jobs"
  task :start do
    #run "bash -l -c 'cd #{current_release}; RAILS_ENV=production bundle exec rake jobs:work >> log/delayed_worker.log'"
    run "bash -l -c 'cd #{current_release}; RAILS_ENV=production bundle exec rake resque:work QUEUE=* COUNT=1"  
  end
  
  desc "Stop the remote worker jobs"
  task :stop do
    run "bash -l -c 'cd #{current_release}; RAILS_ENV=production bundle exec rake jobs:stop'"
  end
  
  desc "Stop resque web interface"
  task :web-stop do
    run "bash -l -c 'cd #{current_release}; RAILS_ENV=production bundle exec resque-web -K'"
  end
  
  desc "Start resque web interface"
  task :web-start do
    run "bash -l -c 'cd #{current_release}; RAILS_ENV=production bundle exec resque-web'"
  end
end

# These are one time setup steps
after "deploy:setup",       "assets:setup"

# This happens every deploy
after "deploy:update_code", "db:symlink"
after "deploy:update_code", "assets:symlink"
after "deploy:update_code", "docs:publish"
after "deploy:update_code", "resque:stop"
after "resque:stop", "resque:start"
after "deploy:update_code", "job:web-stop"
after "job:web-stop", "job:web-start"

after "deploy:restart", "resque:restart"