# This is really an example class for someone to template off of
# 
# To use
#   Delayed::Job.enqueue(ProcessAFile.new(a_user,a_project,path_to_csv,template_id,site_id))
class ProcessAFile
  attr_accessor :project_id
  attr_accessor :user_id
  attr_accessor :file_path
  attr_accessor :data_stream_template_id
  attr_accessor :site_id
  attr_accessor :start_line
  attr_accessor :sample_type
  attr_accessor :sample_medium
  
  def initialize(project,file, data_stream_template_id, site_id, start_line, sample_type, sample_medium, user)
    self.project_id = project.id
    self.user_id = user.id
    self.file_path = file
    self.data_stream_template_id = data_stream_template_id
    self.site_id = site_id
    self.start_line = start_line
    self.sample_type = sample_type
    self.sample_medium = sample_medium
  end
  
  def perform
    # Get the user and the project associated with this action
    user = User.get(self.user_id)
    project = Project.get(self.project_id)
    
    # Perform the action
    project.managed_repository {
      Voeis::DataValue.parse_logger_csv(self.file_path, self.data_stream_template_id, self.site_id, self.start_line, self.sample_type,self.sample_medium, self.user_id)
    }
    
    # Message the user when action is complete.
    VoeisMailer.email(user.login, "Job complete", "Your job completed successfully.")
  end
end