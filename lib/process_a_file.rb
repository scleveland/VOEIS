# Process an uploaded file for use with Resque
# 
# To use
#   Resue.enqueue(ProcessAFile, project_id,file, data_stream_template_id, site_id, start_line, sample_type, sample_medium, user_id, project_job_id)
class ProcessAFile
  @queue = :process_file
  
  def self.perform(project_id,file, data_stream_template_id, site_id, start_line, sample_type, sample_medium, user_id, project_job_id)
    # Get the user and the project associated with this action
    puts user = User.get(user_id)
    project = Project.get(project_id)
    project.managed_repository do
      job = Voeis::Job.get(project_job_id)
      job.status = "running"
      job.save
    end
    # Perform the action
    results = nil
    project.managed_repository {
      results =  Voeis::DataValue.parse_logger_csv(file, data_stream_template_id, site_id, start_line.to_i, sample_type,sample_medium, user_id)
      Voeis::Site.get(site_id).update_site_data_catalog
    }
    project.managed_repository do
      job = Voeis::Job.get(project_job_id)
      job.status = "complete"
      job.completed_time = Time.now
      job.results = results
      puts "*****************************Job Errors:"
      puts job.errors.inspect()
      job.save
    end
    # Message the user when action is complete.
    puts results
    puts "****** USER EMAIL #{user.email}  **************"
    puts VoeisMailer.email_user(user.email, "From VOEIS:: Your Job (id:#{job.id}) is complete!", results.to_s)
  end
end