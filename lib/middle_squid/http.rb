module MiddleSquid::HTTP
  IGNORED_HEADERS = [
    'Connection',
    'Content-Encoding',
    'Content-Length',
    'Host',
    'Transfer-Encoding',
    'Version',
  ].freeze

  def self.server;
    @server ||= Server.new
  end

  def self.sanitize_headers!(dirty)
    clean = {}
    dirty.each {|key, value|
      key = key.split('_').map(&:capitalize).join('-')
      next if IGNORED_HEADERS.include? key

      clean[key] = value
    }

    dirty.clear
    dirty.merge! clean
  end
end
