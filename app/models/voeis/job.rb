class Voeis::Job
  include DataMapper::Resource
  include Facet::DataMapper::Resource

  property :id, Serial
  property :delayed_job_id, Integer, :required => false, :default=>-1
  property :job_type, String, :required => true
  property :job_parameters, Text, :required=> true
  property :results, Text, :required => false
  property :status, String, :required => true, :default => "queued" #[queued, running, complete, failed, canceled]
  property :submitted_at, DateTime, :required=>true
  property :completed_time, DateTime, :required => false
  property :user_id, Integer, :required => true

  def check_status
    unless self.status == "complete"
      dj = nil
      DataMapper.repository("default") do
        dj = Delayed::Job.get(self.delayed_job_id)
      end
      if dj.nil? #delayed job no longer exists so it is complete
        self.status = "complete"
        self.save
      else
        unless dj.locked_at.nil?
          self.status = "running"
          self.save
        else
          self.status = "queued"
          self.save
        end
        unless dj.failed_at.nil?
          self.status = "failed"
          self.save
        end
      end
    end
    return self.status
  end
  
  def user_name
    login= ""
    DataMapper.repository('default') do
      login = User.get(self.user_id).login
    end
    return login
  end
end