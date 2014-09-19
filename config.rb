# config do |c|
#   c.blacklist_db = 'blacklist2.db'
# end

ads = BlackList.new 'ads'
trackers = BlackList.new 'trackers'

# define_action :block, proc {
#   intercept do |req, res|
#     res.write "This webpage is blocked!"
#   end
# }

run proc {|uri, extras|
  if 'perdu.com' == uri.host
    replace_by 'http://google.com'
  end

  if ads.include? uri
    replace_by 'http://webfilter.net/block_page'
  end
}
