#This module used for crating mostfit.pot file and this file conatin all mostfit view pages pain text.
#This file use for support localization
# Haml gettext parser module
require 'rubygems'
require 'haml'
require 'gettext/tools'

class Haml::Engine
  # Overriden function that parses Haml tags
  # Injects gettext call for plain text action.
  def parse_tag(line)
    tag_name, attributes, attributes_hash, object_ref, nuke_outer_whitespace,
      nuke_inner_whitespace, action, value = super(line)
    @precompiled << "_(\"#{value}\")\n" unless action || value.empty?
    [tag_name, attributes, attributes_hash, object_ref, nuke_outer_whitespace,
        nuke_inner_whitespace, action, value]
  end
  # Overriden function that producted Haml plain text
  # Injects gettext call for plain text action.
  def push_plain(text)
    @precompiled << "_(\"#{text}\")\n"
  end
end

# Haml gettext parser
module HamlParser
  module_function

  def target?(file)
    File.extname(file) == '.haml'
  end
 
  def parse(file, ary = [])
    bypass = ! File.basename(file, '.haml').match(/(vi|zh|zh_HK|id|th)$/).nil?
    bypass = true if ["app/views/client_groups/edit.html.haml"].include?(file)
    puts "HamlParser:#{file}:bypass:#{bypass}"
    return ary if bypass

    haml = Haml::Engine.new(IO.readlines(file).join)
    result = nil
    begin
    code = haml.precompiled
    code = code.gsub("%","")
    code = code.gsub(/(.*#\{(_hamlout.adjust_tabs\(\d+\);\s*)?haml_temp)\s*=\s*(_\(['"].+['"]\))/) { |m| "haml_temp = #{$3}; #{$1}" }
    code = code.split(/$/)
      result = GetText::RubyParser.parse_lines(file, code, ary)
     # result = RubyGettextExtractor.parse_string(haml.precompiled, file, ary)
    rescue Exception => e
      puts "Error:#{file}"
      raise e
    end
    result
  end
GetText::RGetText.add_parser(HamlParser)
end
 


