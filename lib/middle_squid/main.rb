class MiddleSquid
  PURGE_DELAY = 10

  def initialize
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

  def define_action(name, &block)
    self.class.send :define_method, name, &block
  end

  def accept
    action :accept
  end

  def drop
    action :drop
  end

  def redirect_to(url, status = 301)
    action :redirect, status, url
  end

  def replace_by(url)
    action :replace, url
  end

  def intercept(&block)
    raise ArgumentError, 'no block given' unless block_given?

    token = SecureRandom.uuid
    @tokens[token] = block

    EM.add_timer(PURGE_DELAY) {
      @tokens.delete token
    }

    replace_by "http://#{@srv_host}:#{@srv_port}/#{token}"
  end

  def action(type, *params)
    raise Action.new(type, params)
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
    case action.type
    when :accept
      gen_line chan_id, 'ERR'
    when :drop
      # no output: see #drop documentation
    when :redirect
      status, new_url = action.params
      gen_line chan_id, "OK status=#{status} url=#{URI.escape new_url}"
    when :replace
      new_url = action.params.first
      gen_line chan_id, "OK rewrite-url=#{URI.escape new_url}"
    else
      raise Error, 'invalid action'
    end
  end

  def gen_line(chan_id, line)
    chan_id ? "#{chan_id} #{line}" : line
  end
end
