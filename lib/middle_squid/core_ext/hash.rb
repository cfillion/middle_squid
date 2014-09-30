class Hash
  IGNORED_HEADERS = [
    'Connection',
    'Content-Encoding',
    'Content-Length',
    'Host',
    'Transfer-Encoding',
    'Version',
  ].freeze

  DASH = '-'.freeze
  UNDERSCORE = '_'.freeze

  def sanitize_headers!
    clean = {}
    each {|key, value|
      key = key.tr UNDERSCORE, DASH
      key = key.split(DASH).map(&:capitalize).join(DASH)

      next if IGNORED_HEADERS.include? key

      clean[key] = value
    }

    clear
    merge! clean
  end
end
