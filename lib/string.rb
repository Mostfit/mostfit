class String
  def humanize
    self.to_s.gsub("_", " ").capitalize
  end
end
class Symbol
  def humanize
    self.to_s.humanize
  end
end
