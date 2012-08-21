# Process a file that is uploaded - for use with delayed job
# 
# To use
#   Delayed::Job.enqueue(ProcessAFile.new(a_user,a_project,path_to_csv,template_id,site_id))
class ProcessAFileDelayed


  attr_accessor :project_id
  attr_accessor :user_id
  attr_accessor :file_path
  attr_accessor :data_stream_template_id
  attr_accessor :site_id
  attr_accessor :start_line
  attr_accessor :sample_type
  attr_accessor :sample_medium
  attr_accessor :project_job_id
  
  def initialize(project,file, data_stream_template_id, site_id, start_line, sample_type, sample_medium, user, project_job_id)
    self.project_id = project.id
    self.user_id = user.id
    self.file_path = file
    self.data_stream_template_id = data_stream_template_id
    self.site_id = site_id
    self.start_line = start_line
    self.sample_type = sample_type
    self.sample_medium = sample_medium
    self.project_job_id = project_job_id
  end
  
  def self.perform(project_id,file, data_stream_template_id, site_id, start_line, sample_type, sample_medium, user_id, project_job_id)
    # Get the user and the project associated with this action
    puts user = User.get(self.user_id)
    project = Project.get(self.project_id)
    project.managed_repository do
      job = Voeis::Job.get(self.project_job_id)
      job.status = "running"
      job.save
    end
    # Perform the action
    results = nil
    project.managed_repository {
      results =  Voeis::DataValue.parse_logger_csv(self.file_path, self.data_stream_template_id, self.site_id, self.start_line, self.sample_type,self.sample_medium, self.user_id)
      Voeis::Site.get(self.site_id).update_site_data_catalog
    }
    project.managed_repository do
      job = Voeis::Job.get(self.project_job_id)
      job.status = "complete"
      job.completed_time = Time.now
      job.results = results
      job.save
    end
    # Message the user when action is complete.
    puts results
    puts "****** USER EMAIL #{user.email}  **************"
    puts VoeisMailer.email_user(user.email, "From VOEIS:: Your Job is complete!", results.to_s)
  end
end