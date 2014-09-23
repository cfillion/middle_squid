class MiddleSquid
  PURGE_DELAY = 10

  def initialize
    @custom_actions = {}
    @tokens = {}
  end

  def eval(file, inhibit_run: false)
    @inhibit_run = inhibit_run

    content = File.read file
    instance_eval content, file
  ensure
    @inhibit_run = false
  end

  def config
    yield Config
  end

  def run(callback)
    return if @inhibit_run

    BlackList.deadline!
    @user_callback = callback

    EM.run {
      EM.open_keyboard Handlers::Input, method(:squid_handler)
    }
  end

  def action(line)
    raise Action.new(line)
  end

  def accept
    action 'ERR'
  end

  def drop
    action nil
  end

  def redirect_to(url, status: 301)
    action "OK status=#{status} url=#{URI.escape url}"
  end

  def replace_by(url = nil)
    unless url
      token = SecureRandom.uuid
      @tokens[token] = Proc.new

      EM.add_timer(PURGE_DELAY) {
        @tokens.delete token
      }

      url = "http://#{@srv_host}:#{@srv_port}/#{token}"
    end

    action "OK rewrite-url=#{URI.escape url}"
  end

  def intercept(&block)
    raise ArgumentError, 'no block given' unless block_given?

    replace_by &block
  end

  def define_action(name, &block)
    @custom_actions[name] = block
  end

  def method_missing(name, *args)
    custom_action = @custom_actions[name]
    super unless custom_action

    custom_action.call *args
  end

  private
  # @see http://wiki.squid-cache.org/Features/Redirectors
  def squid_handler(line)
    parts = line.split

    chan_id = Config.concurrency ? parts.shift : nil
    url, *extras = parts

    uri = Addressable::URI.parse url

    @user_callback.call uri, extras

    accept # default action
  rescue Action => action
    chan_id ? "#{chan_id} #{action.line}" : action.line if action.line
  end
end
