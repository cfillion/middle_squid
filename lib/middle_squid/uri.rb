# @see http://rubydoc.info/gems/addressable/Addressable/URI
class MiddleSquid::URI < Addressable::URI
  DOT   = '.'.freeze
  SLASH = '/'.freeze

  def cleanhost
    clean = normalized_host.force_encoding Encoding::UTF_8
    clean.sub! /\Awww\./, ''
    clean.sub! /\.+\z/, ''
    clean.insert 0, DOT
    clean
  end

  def cleanpath
    dirty = normalized_path.force_encoding Encoding::UTF_8
    p = Pathname.new(dirty).cleanpath

    file = p.basename('.*').to_s.downcase
    p = p.dirname if %w[index default].include? file

    clean = p.to_s[1..-1]
    clean << SLASH unless clean.empty?
    clean
  end
end
