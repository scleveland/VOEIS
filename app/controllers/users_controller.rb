class UsersController < InheritedResources::Base
  respond_to :html, :json

  defaults :resource_class => User,
           :collection_name => 'users',
           :instance_name => 'user'

  def update
    if current_user.id == params[:id].to_i || current_user.admin?
      # Remove these if they were sent.
      if params[:user].empty?
        params[:user].delete(:password)
        params[:user].delete(:password_confirmation)
      end
      if !current_user.admin?
        params[:user].delete(:system_role)
      end
      user= User.get(params[:id].to_i)      
      respond_to do |format|
        if user.update(params[:user])
         format.html do
           flash[:notice] = "User has been updated!"
           redirect_to(:back)
         end
        else
          format.html do
             flash[:alert] = "User could not be updated:" + user.errors.inspect()
             redirect_to(:back)
           end
        end
      end
    else
      respond_to do |format|
         format.html do
           flash[:alert] = "You don't have permission to modify this user!"
           redirect_to(:back)
         end
      end
    end
  end
  
  def edit
    
    edit!
  end
  
  def forgot_password
    
  end
  
  def email_reset_password
    @message = ""
    @result = false
    user = User.first(:login => params[:username], :email=>params[:email])
    if user.nil?
      @message = "We could not find a user matching the combination for username:#{params[:username]} and email address:#{params[:email]}"
    else
      o =  [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten;  
      string  =  (0..50).map{ o[rand(o.length)]  }.join;
      user.password = string[0..10]
      user.password_confirmation = string[0..10]
      if user.save
        @message = "You reset password will be emailed to you."
        VoeisMailer.email_user(user.email, "VOEIS Password Rest", "Your VOEIS password has been reset to: #{string[0..10]}\n\nIf this was not you please contact the VOEIS Administrator\n\nThank You,\n VOEIS" )
        @result = true
      else
        @message = "We were unable to reset your password - please contact an Administrator for assistance."
      end
    end  
  end
  
  def change_password
    if current_user.id == params[:id].to_i || current_user.admin?
      user = User.get(params[:id])
      code = {:message => "Password Change Failed"}
      if params[:password] == params[:confirmation]
        user.password = params[:password]
        user.password_confirmation = params[:confirmation]
        user.save
        code = {:message =>"Password Change Was Successful"}
      end
      respond_to do |format|
        format.json do
          render :json => code.as_json, :callback => params[:jsoncallback]
        end
      end
    else
      respond_to do |format|
         format.html do
           flash[:alert] = "You don't have permission to modify this user!"
           redirect_to(:back)
         end
      end
    end
  end

  def destroy
    @user = resource_class.get(params[:id].to_i)
    if @user.eql?(current_user)
      flash[:notice] = "You can't destroy yourself"
      redirect_to(users_url)
    else
      destroy!
    end
  end

  def api_key_update
    if current_user.id == params[:id].to_i || current_user.admin?
      @user = resource_class.get(params[:id])
      if @user.generate_new_api_key!
        flash[:notice] = "Updated API Key"
      else
        flash[:error] = "Failed to update API Key"
      end
      respond_to do |format|
        format.js
        format.html do
          redirect_to(:back)
        end
      end
    else
      respond_to do |format|
         format.html do
           flash[:alert] = "You don't have permission to modify this user!"
           redirect_to(:back)
         end
      end
    end
  end

  protected

  def resource
    @user ||= resource_class.get(params[:id])
  end

  def collection
    @users ||= resource_class.paginate(:page => params[:page], :per_page => 20, :order => 'login')
  end

  def resource_class
    User.access_as(current_user)
  end

end
