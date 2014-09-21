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

    @user_callback = callback

    EM.run {
      EM.open_keyboard Input, method(:squid_handler)
    }
  end

  def action(type, *params)
    raise Action.new(type, params)
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
    action :intercept, block
  end

  private
  # @see http://wiki.squid-cache.org/Features/Redirectors
  def squid_handler(line)
    chan_id, url, *extras = line.split
    uri = Addressable::URI.parse url

    @user_callback.call uri, extras

    accept
  rescue Action => action
    case action.type
    when :accept
      puts "#{chan_id} ERR"
    when :drop
      # no output: see #drop documentation
    when :redirect
      puts "#{chan_id} #{gen_redirect action.params[0], action.params[1]}"
    when :replace
      puts "#{chan_id} #{gen_replace action.params[0]}"
    when :intercept
      token = SecureRandom.uuid
      @tokens[token] = action.params[0]

      EM.add_timer(PURGE_DELAY) {
        # in case the server never get the request
        @tokens.delete token
      }

      puts "#{chan_id} #{gen_replace "http://127.0.0.1:8918/#{token}"}"
    else
      raise Error, 'invalid action'
    end
  end

  def gen_replace(new_url)
    "OK rewrite-url=#{URI.escape new_url}"
  end

  def gen_redirect(status, new_url)
    "OK status=#{status} url=#{URI.escape new_url}"
  end
end
