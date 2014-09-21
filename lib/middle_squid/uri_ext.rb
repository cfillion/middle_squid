class Addressable::URI
  def cleanhost
    host \
      .sub(/\Awww\./, '')
      .sub(/\.+\z/, '')
  end

  def cleanpath
    p = Pathname.new(path).cleanpath
    file = p.basename('.*').to_s.downcase

    if %w[index default].include? file
      p.dirname.to_s
    else
      p.to_s
    end
  end
end
