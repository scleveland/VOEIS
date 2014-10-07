# resque / redis initializer

require 'resque/server'
require 'process_a_file'
# Resque::Server.use(Rack::Auth::Basic) do |user, password|  
#    password == "secret"  
# end

redis = Redis.new(:host=>'redis.rcg.montana.edu', :port=>6379)
voeis_db = redis.hget('select_dbs', 'voeis')
redis.select(voeis_db)
Resque.redis = redis
