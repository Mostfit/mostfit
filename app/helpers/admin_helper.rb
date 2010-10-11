module Merb
  module AdminHelper

    APP_ROOT = (Merb::Config[:merb_root]).to_s

    def revision
      repo = Grit::Repo.new(APP_ROOT)
      repo ? repo.commits.first.sha : "unknown" #maybe show the short SHA1, but that should preferably come from the library in-use
    end

  end
end # Merb
