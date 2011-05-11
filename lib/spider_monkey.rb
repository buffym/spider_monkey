require 'net/http'
require 'uri'
require 'hpricot'

module SpiderMonkey #:nodoc:

  # = SpiderMonkey::Finder
  # A link and image validation class.
  #
  # This class runs recursively and is suitable for small/medium sites. Run
  # on large sites with many links at your own peril.
  # *Note*: Does not follow redirection at this time.
  class Finder

    # Contains an array of all *broken* links and images found
    attr_reader :broken

    # Contains an array of _all_ links and images checked
    attr_reader :visited


    # The +new+ class method initializes the class.
    # === Parameters
    # * _url_ = url string in the form of 'http://www.google.com'
    # === Example
    #  monkey = SpiderMonkey.new('http://www.google.com')
    #  monkey.broken will contain an array of broken links
    #  monkey.visited will contain an array of all visited links
    def initialize(url)
      @visited = []
      @broken = []
      links(url)
    end

    private

    attr_writer :visited, :broken #:nodoc:

    # checks to see if _uri_ is reachable, and returns the content body
    # if it is, nil otherwise
    def live_body(uri)
      begin
        resp = Net::HTTP.get_response(uri)
        resp.kind_of?(Net::HTTPSuccess) ? resp.body : nil
      rescue SocketError
        nil
      rescue URI::InvalidURIError
        nil
      end
    end

    # checks to see if _uri_ is reachable using a head request. Does not
    # download the entire content body for efficiency.
    def live_link(uri)
      begin
        Net::HTTP.start(uri.host) { |http| http.request_head(uri.path).kind_of?(Net::HTTPSuccess) ? true : false }
      rescue SocketError
        nil
      rescue URI::InvalidURIError
        nil
      end
    end

    # utility method for creating the uri for a page link
    def create_uri(uri, link)
      l = URI.parse(link)
      l.scheme ||= uri.scheme
      l.host ||= uri.host
      uri.path = '/' if uri.path.empty?
      l.path = uri.path + l.path unless l.path =~ /\//
      l
    end

    # +links+ - a recursive function that spiders a site for broken links.
    # It will spider through all links that are part of the original url
    # == Parameters:
    # * _url_ - the url whose links require validation
    def links(url)
      uri = URI.parse(url)

      html = live_body(uri)

      visited << uri.to_s

      if (html)
        doc = Hpricot(html)

        # get all the links, use xpath to search the document for all anchor tags
        links = doc.search('//a').map{ |a| a[:href] }

        # delete links that we don't care about, javascript links mailto and place holder hashes
        links.delete_if { |href| href =~ /javascript|mailto/ }
        links.delete_if { |href| href == '#'}

        links.each do |link|
          if link
            l = create_uri(uri, link)
            
            unless (visited.include?(l.to_s))
              if (l.host == uri.host)
                links(l.to_s)
              else
                broken << l.to_s unless(live_link(l))
                visited << l.to_s
              end
            end
          end
         end

        images = doc.search('//img').map{ |img| img[:src] }

        images.each do |img|
          if (img)
            l = create_uri(uri, img)
            unless (visited.include?(l.to_s))
              broken << l.to_s unless(live_link(l))
              visited << l.to_s
            end
          end
        end
      else
        broken << uri.to_s
      end
    end
  end
end

