class String
  def to_cron_entry
    parts = self.split("\t")
    {
      :minute   => parts[0],
      :hour     => parts[1],
      :day      => parts[2],
      :month    => parts[3],
      :weekday  => parts[4],
      :command  => parts[5]
    }
  end
end
class CronEdit::Crontab
  def list_maintainer
    self.list.delete_if { |k,v| not /^maintainer/ =~ k }
  end
end
