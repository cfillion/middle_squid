# MiddleSquid

MiddleSquid is a redirector, url mangler and webpage interceptor for the squid HTTP proxy.

**Features**

- Configuration is done by writing a simple ruby script
- Supports plain-text domains/urls blacklists
- Can intercept and modify any HTTP request or response
- Works with HTTPS
    if [SslBump](http://wiki.squid-cache.org/Features/SslBump) is enabled.

## Installation & Setup

Assuming [Squid](http://www.squid-cache.org/) is installed and running as user 'proxy'.
These instructions were written for [ArchLinux](https://www.archlinux.org/).
Some adaptation to your favorite operating system may be necessary, at your
discretion.

**Dependencies:**

- Squid version 3.4 or newer
- Ruby version 2.1 or newer

### Step 1: Set a home folder for user 'proxy'

```sh
sudo mkdir /home/proxy
sudo chown proxy:proxy /home/proxy
sudo usermod --home /home/proxy proxy
```

### Step 2: Install MiddleSquid

```sh
sudo su - proxy

gem install middle_squid
echo '# the configuration will be here' > middle_squid_config.rb

exit
```

### Step 3: Create launcher script

Create the file `/usr/local/bin/middle_squid_wrapper.sh`:

```sh 
#!/bin/sh

GEM_HOME=$(ruby -e 'puts Gem.user_dir')
exec $GEM_HOME/bin/middle_squid $*
```

### Step 4: Setup Squid

Add this line to your `/etc/squid/squid.conf`:

```rc
url_rewrite_program /usr/bin/sh /usr/local/bin/middle_squid_wrapper.sh -C /home/proxy/middle_squid_config.rb
```

Finish with `sudo squid -k reconfigure`. Check `/var/log/squid/cache.log` for errors.

## Configuration

MiddleSquid is configured by the ruby script specified in the command line by the `-C` or `--config-file` argument.

The script must call the `run` method at the very end:

```ruby
run proc {|uri, extras|
  # decide what to do with uri
}
```

The argument must be an object that responds to the `call` method and taking two arguments:
the uri to process and an array of extra data received from squid
(see url_rewrite_extras in
[squid's documentation](http://www.squid-cache.org/Doc/config/url_rewrite_extras/)).

Write this in the file `/home/proxy/middle_squid_config.rb` we have created earlier:

```ruby
run proc {|uri, extras|
  redirect_to 'http://duckduckgo.com' if uri.host =~ /google\.com$/
}
```

Run `sudo squid -k reconfigure` again to restart all MiddleSquid processes.
You sould now be redirected to http://duckduckgo.com each time you visit
http://google.com (the non-HTTPS version) using your Squid proxy.

### Black Lists

While it may be fun to redirect yourself to an alternate search engine,
MiddleSquid is more useful at blocking annoying advertisements and tracking
services that are constantly watching your whereabouts.

MiddleSquid can scan any black list collection distributed in plain-text format
and compatible with SquidGuard or Dansguardian, such as:

- [Shalla's Blacklists](http://www.shallalist.de/) (free for personnal use)
- [URLBlackList.com](http://www.urlblacklist.com/) (commercial)

Replace the previous configuration in `/home/proxy/middle_squid_config.rb`
by this one:

```ruby
config do |c|
  c.database = '/home/proxy/blacklist.db'
end

adv     = BlackList.new 'adv'
tracker = BlackList.new 'tracker'

run proc {|uri, extras|
  if adv.include? uri
    redirect_to 'http://your.webserver/block_pages/advertising.html'
  end

  if tracker.include? uri
    redirect_to 'http://your.webserver/block_pages/tracker.html'
  end
}
```

Next we have to download a blacklist and ask MiddleSquid to index its content
in the database for fast access.

```sh
sudo su - proxy

# Download Shalla's Blacklists
wget "http://www.shallalist.de/Downloads/shallalist.tar.gz" -O shallalist.tar.gz
tar xzf shallalist.tar.gz
mv BL ShallaBlackList

# Construct the blacklist database
/usr/local/bin/middle_squid_wrapper.sh build ShallaBlackList -C /etc/squid/middle_squid.rb

exit
```

The `build` command above may take a while to complete. Once it's done, re-run `squid -k reconfigure` and
enjoy an internet without ads or tracking beacons.

### Content Interception

TODO

## Documentation

MiddleSquid's documentation is hosted at
[http://rubydoc.info/gems/middle_squid/MiddleSquid](http://rubydoc.info/gems/middle_squid/MiddleSquid).

- [List of predefined actions](http://rubydoc.info/gems/middle_squid/MiddleSquid/Actions)
- [List of predefined helpers](http://rubydoc.info/gems/middle_squid/MiddleSquid/Helpers)
- [List of configuration settings](http://rubydoc.info/gems/middle_squid/MiddleSquid/Config)

## Changelog

### v0.1 (00/00/2014)

First public release.

## Future Plans

TODO

## Contributing

1. [Fork it](https://github.com/cfillion/middle_squid/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Test your changes (`rake`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request
