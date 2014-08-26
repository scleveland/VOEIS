#$:.unshift(File.expand_path('./lib', ENV['rvm_path']))

#require "rvm/capistrano" 
require "bundler/capistrano"

set :application, "voeis"
#set :rvm_ruby_string, 'ruby-1.9.2-p180@passenger'
#set :rvm_type, :system  
#set :bundle_cmd,      "/usr/local/rvm/gems/ruby-1.9.2-p180/bin/bundle"
set :rvm_ruby_string, 'ruby-1.9.2-p320@passenger'
set :rvm_type, :system  
set :bundle_cmd,      "/usr/local/rvm/gems/ruby-1.9.2-p320/bin/bundle"
set :scm, :git
set :repository,  "git://github.com/yogo/VOEIS.git"
set :shell, "/bin/bash"
set :use_sudo,    false
set :deploy_via, :remote_cache
set :copy_exclude, [".git"]
set :user, "root"
#set :user, "sean.cleveland"
set :deploy_to, "/var/rails"
#set :deploy_to, "/var/voeis"

set :workers, { "process_file" => 2 }

desc "Setup Development Settings"
task :development do
  set :branch, "master"
  role :web, "voeis-dev.rcg.montana.edu"
  role :app, "voeis-dev.rcg.montana.edu"
  role :db,  "voeis-dev.rcg.montana.edu", :primary => true
end

desc "Setup Production Settings"
task :production do

  set :branch, "production"
  role :web, "voeis4.rcg.montana.edu"
  role :app, "voeis4.rcg.montana.edu"
  role :db,  "voeis4.rcg.montana.edu", :primary => true

end

desc "Setup Production Settings"
task :voeis2 do
  set :rvm_ruby_string, 'ruby-1.9.2-p180@unicorn'
  set :bundle_cmd,      "/usr/local/rvm/gems/ruby-1.9.2-p180@global/bin/bundle"
  set :branch, "production"
  role :web, "voeis2.rcg.montana.edu"
  role :app, "voeis2.rcg.montana.edu"
  role :db,  "voeis2.rcg.montana.edu", :primary => true

end

desc "Setup Production Settings"
task :voeis4 do
  set :rvm_ruby_string, 'ruby-1.9.2-p320@unicorn'
  set :bundle_cmd,      "/usr/local/rvm/gems/ruby-1.9.2-p320@global/bin/bundle"
  set :branch, "production"
  role :web, "voeis4.rcg.montana.edu"
  role :app, "voeis4.rcg.montana.edu"
  role :db,  "voeis4.rcg.montana.edu", :primary => true
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
    run "cd #{current_path}; RAILS_ENV=production bundle exec yard doc "
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
    run "mkdir -p #{deploy_to}/#{shared_dir}/assets/data"
  end

  task :symlink do
    run "ln -nfs #{deploy_to}/#{shared_dir}/assets/files #{release_path}/public/files"
    run "ln -nfs #{deploy_to}/#{shared_dir}/assets/images #{release_path}/public/images"
    run "ln -nfs #{deploy_to}/#{shared_dir}/assets/temp_data #{release_path}/temp_data"
    run "ln -nfs #{deploy_to}/#{shared_dir}/assets/data #{release_path}/data"
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
  task :web_stop do
    run "bash -l -c 'cd #{current_release}; RAILS_ENV=production bundle exec resque-web -K'"
  end
  
  desc "Start resque web interface"
  task :web_start do
    run "bash -l -c 'cd #{current_release}; RAILS_ENV=production bundle exec resque-web'"
  end
  
  desc "Restart Resque Workers"
  task :restart_workers, :roles => :db do
    run_remote_rake "resque:restart_workers"
  end

  desc "Restart Resque scheduler"
  task :restart_scheduler, :roles => :db do
    run_remote_rake "resque:restart_scheduler"
  end
end


##
# Rake helper task.
# http://pastie.org/255489
# http://geminstallthat.wordpress.com/2008/01/27/rake-tasks-through-capistrano/
# http://ananelson.com/said/on/2007/12/30/remote-rake-tasks-with-capistrano/
def run_remote_rake(rake_cmd)
  rake_args = ENV['RAKE_ARGS'].to_s.split(',')
  cmd = "cd #{fetch(:latest_release)} && #{fetch(:rake, "rake")} RAILS_ENV=#{fetch(:rails_env, "production")} #{rake_cmd}"
  cmd += "['#{rake_args.join("','")}']" unless rake_args.empty?
  run cmd
  set :rakefile, nil if exists?(:rakefile)
end




# These are one time setup steps
after "deploy:setup",       "assets:setup"

# This happens every deploy
after "deploy:update_code", "db:symlink"
after "deploy:update_code", "assets:symlink"
after "deploy:update_code", "docs:publish"
#after "deploy:update_code", "jobs:restart_workers"
#after "deploy:update_code", "jobs:web_stop"
#after "jobs:web_stop", "jobs:web_start"
