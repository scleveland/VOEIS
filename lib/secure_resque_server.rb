require 'resque/server'

class SecureResqueServer < Resque::Server

  before do
    redirect '/' unless !User.current.nil? and User.current.admin?
  end

end