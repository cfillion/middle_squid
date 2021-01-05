# MiddleSquid

[![Gem Version](https://badge.fury.io/rb/middle_squid.svg)](http://badge.fury.io/rb/middle_squid)
[![Test status](https://github.com/cfillion/middle_squid/workflows/test/badge.svg)](https://github.com/cfillion/middle_squid/actions)
[![Dependency Status](https://gemnasium.com/cfillion/middle_squid.svg)](https://gemnasium.com/cfillion/middle_squid)
[![Code Climate](https://codeclimate.com/github/cfillion/middle_squid/badges/gpa.svg)](https://codeclimate.com/github/cfillion/middle_squid)
[![Coverage Status](https://img.shields.io/coveralls/cfillion/middle_squid.svg)](https://coveralls.io/r/cfillion/middle_squid?branch=master)

MiddleSquid is a redirector, url mangler and webpage interceptor for the Squid HTTP proxy.

**Features**

- Configuration is done by writing a ruby script
- Supports plain-text domains/urls blacklists
- Can intercept and modify any HTTP request or response
- Works with HTTPS
    if [SslBump](http://wiki.squid-cache.org/Features/SslBump) is enabled.

## Installation & Setup

Assuming [Squid](http://www.squid-cache.org/) is installed and running as user 'proxy'.
These instructions were written for [Arch Linux](https://www.archlinux.org/).
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
echo 'run lambda {|uri, extras| }' > middle_squid_config.rb

exit
```

### Step 3: Create a launcher script

Create the file `/usr/local/bin/middle_squid_wrapper.sh`:

```sh 
#!/bin/sh

GEM_HOME=$(ruby -e 'puts Gem.user_dir')
exec $GEM_HOME/bin/middle_squid $*
```

### Step 4: Setup Squid

Add these lines to your `/etc/squid/squid.conf`:

```squidconf
url_rewrite_program /usr/bin/sh /usr/local/bin/middle_squid_wrapper.sh start -C /home/proxy/middle_squid_config.rb

# required to fix HTTPS sites (if SslBump is enabled)
acl fix_ssl_rewrite method GET
acl fix_ssl_rewrite method POST
url_rewrite_access allow fix_ssl_rewrite
url_rewrite_access deny all
```

Finish with `sudo squid -k reconfigure`. Check `/var/log/squid/cache.log` for errors.

## Configuration

MiddleSquid is configured by the ruby script specified in the command line by the `-C` or `--config-file` argument.

The script must call the `run` method:

```ruby
run lambda {|uri, extras|
  # decide what to do with uri
}
```

The argument must be an object that responds to the `call` method and taking two arguments:
the URI to process and an array of extra data received from squid
(see url_rewrite_extras in
[squid's documentation](http://www.squid-cache.org/Doc/config/url_rewrite_extras/)).

Write this in the file `/home/proxy/middle_squid_config.rb` we have created earlier:

```ruby
run lambda {|uri, extras|
  redirect_to 'http://duckduckgo.com' if uri.host.end_with? 'google.com'
}
```

Run `sudo squid -k reconfigure` again to restart all MiddleSquid processes.
You should now be redirected to http://duckduckgo.com each time you visit
Google under your Squid proxy.

### Black Lists

While it may be fun to redirect yourself to an alternate search engine,
MiddleSquid is more useful at blocking annoying advertisements and tracking
services that are constantly watching your whereabouts.

MiddleSquid can scan any black list collection distributed in plain-text format
and compatible with SquidGuard or Dansguardian, such as:

- [Shalla's Blacklists](http://www.shallalist.de/) (free for personal use)
- [URLBlackList.com](http://www.urlblacklist.com/) (commercial)

Replace the previous configuration in `/home/proxy/middle_squid_config.rb`
by this one:

```ruby
database '/home/proxy/blacklist.db'

adv     = blacklist 'adv'
tracker = blacklist 'tracker'

run lambda {|uri, extras|
  if adv.include? uri
    redirect_to 'http://your.webserver/block_pages/advertising.html'
  end

  if tracker.include? uri
    redirect_to 'http://your.webserver/block_pages/tracker.html'
  end
}
```

Next we have to download a blacklist and ask MiddleSquid to index its content
in the database for fast access:

```sh
sudo su - proxy

# Download Shalla's Blacklists
wget "http://www.shallalist.de/Downloads/shallalist.tar.gz" -O shallalist.tar.gz
tar xzf shallalist.tar.gz
mv BL ShallaBlackList

# Construct the blacklist database
/usr/local/bin/middle_squid_wrapper.sh index ShallaBlackList -C /home/proxy/middle_squid_config.rb

exit
```

The `index` command above may take a while to complete. Once it's done, re-run `squid -k reconfigure` and
enjoy an internet without ads or tracking beacons.

### Content Interception

MiddleSquid can also intercept the client's requests and modify the data sent to the
browser. Let's translate a few click-bait headlines on BuzzFeed
(check out [Downworthy](http://downworthy.snipe.net/) while you are at it):

```ruby
CLICK_BAITS = {
  'Literally' => 'Figuratively',
  'Mind-Blowing' => 'Painfully Ordinary',
  'Will Blow Your Mind' => 'Might Perhaps Mildly Entertain You For a Moment',
  # ...
}.freeze

define_action :translate do |uri|
  intercept {|req, res|
    status, headers, body = download_like req, uri

    content_type = headers['Content-Type'].to_s

    if content_type.include? 'text/html'
      CLICK_BAITS.each {|before, after|
        body.gsub! before, after
      }
    end

    [status, headers, body]
  }
end

run lambda {|uri, extras|
  if uri.host == 'www.buzzfeed.com'
    translate uri
  end
}
```

Don't use this feature unless you have the permission from all your users to do so.
This indeed constitutes a man-in-the-middle attack and should be used with
moderation.

## Documentation

MiddleSquid's documentation is hosted at
[http://rubydoc.info/gems/middle_squid/MiddleSquid](http://rubydoc.info/gems/middle_squid/MiddleSquid).

- [Configuration syntax (DSL)](http://rubydoc.info/gems/middle_squid/MiddleSquid/Builder)
- [List of predefined actions](http://rubydoc.info/gems/middle_squid/MiddleSquid/Actions)
- [List of predefined helpers](http://rubydoc.info/gems/middle_squid/MiddleSquid/Helpers)
- [Available adapters](http://rubydoc.info/gems/middle_squid/MiddleSquid/Adapters)

## Changelog

### v1.0.1 (2014-11-06)

- send download errors as text/plain
- fix a crash when reading invalid UTF-8 byte sequences
- cleanup `index`'s output (everything is now sent to stderr)
- show the indexing progress

### v1.0 (2014-10-05)

First public release.

## Future Plans

- Find out why HTTPS is not always working under Squid without the ACL hack.
- Write new adapters for other proxies or softwares.

## Contributing

1. [Fork it](https://github.com/cfillion/middle_squid/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Test your changes (`rake`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request
