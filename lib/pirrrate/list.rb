module Pirrrate
  # An abstract list of torrents.
  #
  # @abstract Sublcass and override {#url}.
  class List
    # Get a list of torrents.
    #
    # @return [Array<Torrent>]
    def torrents
      rows.map { |row| build_torrent(row) }
    end

    # Get a list of torrent rows.
    #
    # @return [Nokogiri::XML::NodeSet]
    def rows
      doc = Nokogiri::HTML(open(url.to_uri))
      doc.xpath('.//table/tr')[1..31]
    end

    # Build a torrent object from result row.
    #
    # @param row [Nokogiri::XML::Element]
    # @return [Torrent]
    def build_torrent(row)
      cols = row.xpath('.//td')

      category, subcategory = cols[0].xpath('.//a').map(&:text)

      links = cols[1].xpath('.//a')
      title = links[0].text
      url = links[0]['href']
      magnet_link = links[1]['href']
      torrent_link = (l = links[2]['href']) && l.end_with?('.torrent') && l || nil

      meta_col = cols[1].xpath('.//font').text.gsub("\u00a0", ' ')
      _, created_at, size, user = %r{Uploaded (.*), Size (.*), ULed by (.*)}.match(meta_col).to_a

      seeders = cols[2].text.to_i
      leechers = cols[3].text.to_i

      Torrent.new title, url, category, subcategory, magnet_link, torrent_link,
        Chronic.parse(created_at), size, user, seeders, leechers
    end

    # @return [URL]
    def url
      raise NotImplementedError
    end

    def inspect
      "#<#{self.class.name} #{url}>"
    end
  end
end
