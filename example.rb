config do |c|
  c.database = 'blacklist.db'
  c.minimal_indexing = true
end

adv = BlackList.new 'adv'
test = BlackList.new 'test'
tracker = BlackList.new 'tracker'

blocked = [adv, test, tracker]

define_action :block do
  replace_by 'http://webfilter.net/block_page'

  # intercept do |req, res|
  #   res.write "This webpage is blocked!"
  # end
end

run proc {|uri, extras|
  redirect_to 'http://google.com' if uri.host == 'perdu.com'

  block if blocked.any? {|bl| bl.include? uri }
}
