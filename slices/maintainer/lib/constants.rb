module Merb
  module Maintainer
    module Constants

      SLICE_PATH = 'slices/maintainer/'

      DB_CONFIG = YAML.load(File.read(File.join(Merb.root,'config/database.yml')))

      # DEPLOYMENT
      GIT_REPO = '.'

      # DATABASE SNAPSHOTS
      DUMP_FOLDER = File.join(Merb.root,"db/daily/")
      DB_FOLDER = File.join(Merb.root,"db/")

      # HISTORY / DEPLOYMENT
      DM_REPO = DataMapper.repository(:maintainer)

      # TASKS
      CRON_LOG = File.join(Merb.root,SLICE_PATH,"log/cron.log")
      RAKE_TASKS_FILE = File.join(Merb.root,SLICE_PATH,"data/mostfit_rake_tasks")

      # LOGS
      # array of "watchable" file paths (either absolute or relative to the application root)
      WATCHABLE_FILES = ["log/*"]
      DEFAULT_MAX_LINE_COUNT = 40

      MONTHS = %w(January February March April May June July August September October November December)
      WEEKDAYS = %w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)

      DATE_FORMAT_READABLE = "%d %b, %Y"
      DATE_TIME_FORMAT_READABLE = "%l:%M:%S %p, %d %b, %Y"

    end
  end
end
