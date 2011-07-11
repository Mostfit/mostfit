module Merb::Maintainer::DeploymentHelper

  # helper to deploy code as per the options passed
  def deploy_code(params)

    @branches = @git.branches.local.map(&:full)
    @current_branch = @git.current_branch

    database_backup

    # fetch all remote branches
    @git.fetch('origin')

    branch = (params[:branch_type] == "local") ? params[:local_branch] : params[:remote_branch]
    branch_changed = (@current_branch != branch)
     
    if params[:branch_type] == "local"
      # local branch change
      @git.checkout(branch) if branch_changed
      # pull = fetch (done above) + merge (the git gem's pull() method is buggy, DON'T use it)
      msg = @git.remote('origin').merge(branch)
    elsif params[:branch_type] == "remote"
      # switch to the specified remote branch, ...
      @git.checkout('origin/'+branch)
      # ... create a corresponding local branch from it, ...
      @git.branch(branch).create
      # ... and deploy the new local branch by checking out to it
      @git.checkout(branch)
    end

    if (params[:branch_type] == "local" and not branch_changed and not msg.nil? and not msg == "Already up-to-date.") or (params[:branch_type] == "local" and branch_changed) or (params[:branch_type] == "remote")
      # record deployment in deployment and action histories
      DM_REPO.scope { Maintainer::DeploymentItem.create_from_last_commit }
      log(
        :action => (params[:upgrade_db] == "yes") ? ('deployed_and_upgraded') : ('deployed'),
        :ip     => request.remote_ip,
        :name   => @git.log.first.sha
      )

      if params[:upgrade_db] == "yes"
        instance_take_offline
        database_upgrade
        instance_start
      else
        instance_restart
      end

      refresh_rake_tasks_file
    end

  end

  # helper to rollback code to a particular DeploymentItem
  def rollback_code(params)
    deployment = DM_REPO.scope { Maintainer::DeploymentItem.first(:sha => params[:sha]) }

    # checkout to the rollback commit's branch and reset to that commit
    @git.checkout(deployment.branch) unless deployment.branch == @git.current_branch
    @git.reset_hard(@git.gcommit(params[:sha]))

    # remove appropriate DeploymentItems from db
    rollback_to = DM_REPO.scope { Maintainer::DeploymentItem.first(:sha => params[:sha]) }
    commits_to_trash = DM_REPO.scope { Maintainer::DeploymentItem.all(:time.gt => rollback_to.time) }
    commits_to_trash.destroy

    # log rollback in action history
    log(
      :action => 'rollback',
      :ip     => request.remote_ip,
      :name   => @git.log.first.sha
    )
  end

  # checks whether the currently deployed is behind or up-to-date with the corresponding remote branch
  def deployable?
    repo = File.join(GIT_REPO,".git")
    `git --git-dir=#{repo} remote update`
    status = (`git --git-dir=#{repo} rev-list --max-count=1 refs/heads/#{@git.current_branch}` != `git --git-dir=#{repo} rev-list --max-count=1 refs/remotes/origin/#{@git.current_branch}`)
    return status.to_s
  end

end
