class Addressable::URI
  def cleanhost
    normalized_host \
      .sub(/\Awww\./, '')
      .sub(/\.+\z/, '')
      .force_encoding(Encoding::UTF_8)
  end

  def cleanpath
    p = Pathname.new(normalized_path).cleanpath

    file = p.basename('.*').to_s.downcase
    p = p.dirname if %w[index default].include? file

    p.to_s[1..-1].force_encoding Encoding::UTF_8
  end
end
