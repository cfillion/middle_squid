class Addressable::URI
  def cleanhost
    host \
      .sub(/\Awww\./, '')
      .sub(/\.+\z/, '')
  end

  def cleanpath
    p = Pathname.new(path).cleanpath

    file = p.basename('.*').to_s.downcase
    p = p.dirname if %w[index default].include? file

    p.to_s[1..-1]
  end
end
