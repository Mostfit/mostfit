class Numeric
  module Transformer
    REGEX = /(\d)(?=(\d\d\d)+(?!\d))(\.\d+)?/
    def self.with_delimiter(number, format_name = nil, options = {})
      format = (formats[format_name] || default_format)[:number].merge(options)
      number.to_s.gsub(format[:regex]||REGEX, "\\1#{format[:delimiter]}")
    end

    def self.with_precision(number, format_name = nil, options={})
      format = (formats[format_name] || default_format)[:number].merge(options)      
      with_delimiter("%01.#{format[:precision]}f" % number.round_orig, format_name, :delimiter => format[:delimiter], :separator => format[:separator])
    end

    def self.to_currency(number, format_name = nil, options = {})
      format = (formats[format_name] || default_format)[:currency].merge(options)
      format[:format].gsub(/%n/, with_precision(number, format_name, :precision  => format[:precision]) ).gsub(/%u/, format[:unit]||"").strip
    end
  end
end
