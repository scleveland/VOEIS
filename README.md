# Welcome to VOEIS


VOEIS is a Data Management System built on Ruby on Rails, DataMapper, Postgres, Redis and the Yogo Data-Management Framework.  VOEIS has dependencies that need to be installed on your system before you can begin developing or using VOEIS.
An alternative to all this setup is to contact rcg-support@montana.edu for a kvm virtual machine that has a basic VOEIS instance setup and run it in virtual box locally or deploy it to a virtual host.
  
1. Ruby must be installed and the latest ruby-1.9.2 release is required - we recommend using rvm http://rvm.io for ruby version management and gemset management combined with bundler.
2. A PostgreSQL server is required and installation instructions and binaries can be found here: http://www.postgresql.org/download/ -- this does not need to be a local server and our instance is on it's own separate  server
3. A Redis http://redis.io instance is required for job queueing, VOEIS uses resque for background jobs-https://github.com/defunkt/resque

Once these dependencies are installed you can proceed with the rest of the VOEIS installation.

## Getting Started with Development or a Server after dependencies are installed

1. Checkout the project:           `git clone git@github.com:yogo/VOEIS.git`
2. Change directories to the code: `cd VOEIS`
3. Install gems:                   `bundle install` - Note that you can choose to create a gemset and use it prior to this
4. Setup database.yml in config/:  Edit the database.yml.start to match your postgres instance and rename this file database.yml
5. Create the database:            `bundle exec rake db:create` NOTE that the user for you database must have db create permissions
6. Seed the application:           `bundle exec rake db:seed` 
7. Start the application:           'bundle exec rails s
8. Go to http://localhost:3000/ and get the VOEIS start page!

### Modify settings for non-local instance

If you want you VOEIS server to be available to other user across the Web you will need modify your VOEIS settings.  This is simple.  
1. Login as an administrator. 
2. Click the 'Datahub' menu item in the upper left corner
3. Select Administration->Settings
4. Uncheck the 'Local Only' option.

NOTE you can also set your application to accept API Keys for programmatic access to data at this time as well by checking the 'Allow Api Key' checkbox.



