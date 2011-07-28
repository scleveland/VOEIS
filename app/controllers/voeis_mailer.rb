class VoeisMailer < ActionMailer::Base
    default :from => 'voeis.mgmt@gmail.com'
  #forge@msu.montana.edu
  def email_forge(subject, body)
    puts "Im emailing"
    mail(:to => 'forge@msu.montana.edu', 
         :subject => subject, 
         :body => body ).deliver
  end
  
  def email(to, subject = 'From Voeis', message = '')
    @message = message
    mail(:to => to,
         :subject => subject)
  end
  
  def email_user(address, subject, body)
     mail(:to => address, 
         :subject => subject, 
         :body => body ).deliver
  end
  
  def email_rescued_exception(e)
    @requst = ActionDispatch::Request.new(request.env)
    req = "URL       :#{@request.url}\n"
    req << "IP address: #{@request.remote_ip}\n"
    req << "Parameters: #{@request.filtered_parameters.inspect}\n"
    req << "Rails root: #{Rails.root}\n"
    mail(:to =>%w{ sean.b.cleveland@gmail.com pol.llovet@gmail.com thomasheetderks@gmail.com},
         :subject => "Caught Exception Error",
         :body => "\n\nMessage\n__________\n"+e.message+"\n\nRequest\n__________\n"+req+"\n\nBacktrace\n_________\n"+e.backtrace * "\n").deliver
         

         
  end
end