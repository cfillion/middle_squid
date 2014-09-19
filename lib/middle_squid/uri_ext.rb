module URI
  def cleanhost
    host \
      .gsub(/\Awww\./, '')
      .gsub(/\.+\z/, '')
  end

  def cleanpath
    p = Pathname.new(path).cleanpath
    file = p.basename('.*').to_s.downcase

    if %w[index default].include? file
      p.parent.to_s
    else
      p.to_s
    end
  end
end
