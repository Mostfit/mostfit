class Maintainer::DeploymentItem

  include DataMapper::Resource
  
  property :id,       Serial
  property :sha,      String,   :nullable => false, :length => 40
  property :message,  Text,     :nullable => false
  property :time,     DateTime, :nullable => false
  property :branch,   String,   :nullable => false, :default => "master"

  def self.create_from_last_commit
    git = Git.open(GIT_REPO)
    DM_REPO.scope {
      Maintainer::DeploymentItem.create(
        :sha     => git.log.first.sha,
        :message => git.log.first.message,
        :time    => Time.now,
        :branch  => git.current_branch
      )
    }
  end
  
end
