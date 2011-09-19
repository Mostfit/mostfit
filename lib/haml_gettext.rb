# Haml gettext module providing gettext translation for all Haml plain text calls
require 'i18n/gettext'

class Haml::Engine
  include I18n::Gettext::Helpers
  # Inject _ gettext into plain text and tag plain text calls
  #After getting all Haml plain text we are checking each word conversion in .po file using I18n::Gettext::Helpers gettext() method
  def push_plain(text)
    po_file_text = gettext(text, options = {})
    text  = po_file_text if po_file_text
    super(text)
  end
  
  def parse_tag(line)
    tag_name, attributes, attributes_hash, object_ref, nuke_outer_whitespace,
      nuke_inner_whitespace, action, value = super(line)
    value = (value) unless action || value.empty?
    [tag_name, attributes, attributes_hash, object_ref, nuke_outer_whitespace,
        nuke_inner_whitespace, action, value]
  end
end

