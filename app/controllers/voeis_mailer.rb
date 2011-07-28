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
  
  def email_rescued_exception(error_msg)
    mail(:to =>%w{ sean.b.cleveland@gmail.com pol.llovet@gmail.com thomasheetderks@gmail.com},
         :subject => "Caught Exception Error",
         :body => error_msg).deliver
  end
end