config do |c|
  c.database = 'blacklist.db'
  c.minimal_indexing = true
end

adv = BlackList.new 'adv'
test = BlackList.new 'test'
trackers = BlackList.new 'tracker'

blocked = [adv, test, trackers]

# define_action :block, proc {
#   intercept do |req, res|
#     res.write "This webpage is blocked!"
#   end
# }

run proc {|uri, extras|
  if 'perdu.com' == uri.host
    replace_by 'http://google.com'
  end

  if blocked.any? {|bl| bl.include? uri }
    replace_by 'http://webfilter.net/block_page'
  end
}
