module MiddleSquid
  # Use to query the blacklist database.
  # URIs can be matched by hostname (see {#include_domain?}), path (see {#include_url?}) or both (see {#include?}).
  #
  # Instances of this class should be created using {Builder#blacklist Builder#blacklist}
  # (otherwise they would not be seen by the "<code>middle_squid index</code>" command unless the "+--full+" flag is enabled).
  class BlackList
    include Database

    # @return [String] the category passed to {#initialize}
    attr_reader :category

    # @return [Array<String>] the aliases passed to {#initialize}
    attr_reader :aliases

    # Returns a new instance of BlackList. Use {Builder#blacklist Builder#blacklist} instead.
    # @param category [String]
    # @param aliases  [Array<String>]
    def initialize(category, aliases: [])
      @category = category
      @aliases = aliases
    end

    # Whether the blacklist category contains the uri's hostname or an upper-level domain.
    #
    # Rules to the <code>www</code> subdomain match any subdomains.
    #
    # @example Rule: sub.domain.com
    #   Matches:
    #   - http://sub.domain.com/...
    #   - http://second.sub.domain.com/...
    #   - http://infinite.level.of.sub.domain.com/...
    # @param uri [URI] the uri to search
    def include_domain?(uri)
      !!db.get_first_value(
        "SELECT 1 FROM domains WHERE category = ? AND ? LIKE '%' || host LIMIT 1",
        [@category, uri.cleanhost]
      )
    end

    # Whether the blacklist category contains the uri. Matches by partial domain (like {#include_domain?}) and path. The query string is ignored.
    #
    # Rules to index files (index.html, Default.aspx and friends) match the whole directory.
    #
    # @example Rule: domain.com/path
    #   Matches:
    #   - http://domain.com/path
    #   - http://domain.com/dummy/../path
    #   - http://domain.com/path/extra_path
    #   - http://domain.com/path?query=string
    # @param uri [URI] the uri to search
    def include_url?(uri)
      !!db.get_first_value(
        "SELECT 1 FROM urls WHERE category = ? AND ? LIKE '%' || host AND ? LIKE path || '%' LIMIT 1",
        [@category, uri.cleanhost, uri.cleanpath]
      )
    end

    # Whether this blacklists contains the uri.
    # Matches by domain and/or path.
    #
    # @param uri [URI] the uri to search
    def include?(uri)
      include_domain?(uri) || include_url?(uri)
    end
  end
end
