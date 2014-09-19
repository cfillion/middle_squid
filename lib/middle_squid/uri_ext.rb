module URI
  def cleanhost
    host \
      .gsub(/\Awww\./, '')
      .gsub(/\.+\z/, '')
  end

  def cleanpath
    Pathname.new(path).cleanpath.to_s
  end
end
