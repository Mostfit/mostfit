module Merb
  module AdminHelper

    APP_ROOT = (Merb::Config[:merb_root]).to_s

    def revision
      if Kernel.const_defined?("Grit")
        repo = Grit::Repo.new(APP_ROOT)
        repo ? repo.commits.first.sha : "unknown" #maybe show the short SHA1, but that should preferably come from the library in-use
      else
        "not available"
      end
    end
  end
end # Merb
