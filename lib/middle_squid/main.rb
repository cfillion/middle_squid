class MiddleSquid
  include Actions
  include Helpers

  def initialize
    @run_was_called = false
    @server = MiddleSquid::HTTP.server
  end

  # Evalutate a configuration file.
  #
  # @api private
  def eval(file, inhibit_run: false)
    @inhibit_run = inhibit_run

    content = File.read file
    instance_eval content, file
  ensure
    @inhibit_run = false
  end

  # Whether {#run} was called.
  #
  # @api private
  def ran?
    @run_was_called
  end

  # Tweak MiddleSquid settings.
  # See {Config} for the list of available options.
  #
  # @example Default values
  #   config do |c|
  #     c.concurrency = false
  #     c.database = 'blacklist.db'
  #     c.index_entries = [:domain, :url]
  #     c.minimal_indexing = true
  #   end
  #
  #   # run proc {|uri, extras| ... }
  # @return [Config]
  def config
    yield Config if block_given?
    Config
  end

  # Start the squid helper and the internal server.
  #
  # Takes any object that responds to the call method with two arguments:
  # the uri to process and an array of extra data received from squid.
  #
  # @example
  #   run proc {|uri, extras|
  #     # called when a query from squid has been received
  #   }
  # @param callback [#call<URI, Array>]
  # @see http://www.squid-cache.org/Doc/config/url_rewrite_extras/
  def run(callback)
    return if @inhibit_run

    BlackList.deadline!

    @run_was_called = true
    @user_callback = callback

    EM.run {
      EM.open_keyboard Handlers::Input, method(:squid_handler)

      Thin::Logging.logger = Logger.new STDERR
      Thin::Logging.level = Logger::WARN

      server = Thin::Server.new SERVER_HOST, 0, method(:http_handler),
        :backend => Handlers::HTTP,
        :signals => false

      server.start

      @server.start
    }
  end

  private
  def squid_handler(line)
    parts = line.split

    chan_id = Config.concurrency ? parts.shift : nil
    url, *extras = parts

    # squid sends https url in the format "domain:port", without the scheme
    # when SslBump is disabled (= we can't redirect/intercept the request)
    accept if url && !url.include?('://')

    uri = URI.parse url
    raise InvalidURI if !uri || !uri.host

    @user_callback.call uri, extras

    accept # default action
  rescue Action => action
    chan_id ? "#{chan_id} #{action.line}" : action.line if action.line
  rescue InvalidURI, Addressable::URI::InvalidURIError
    warn "[MiddleSquid] invalid uri received: '#{url}'\n\tin '#{line}'"
  end
end
