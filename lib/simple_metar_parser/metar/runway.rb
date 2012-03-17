$:.unshift(File.dirname(__FILE__))

module SimpleMetarParser
  class Runway < Base

    def reset
      @runways = Array.new
    end

    attr_reader :runways

    def decode_split(s)
      # TODO add variable vis. http://stoivane.iki.fi/metar/

      if s =~ /R(.{2})\/P(\d{4})(.)/
        h = {
          :runway => $1,
          :visual_range => $2.to_i
        }

        if $3 == "N"
        elsif $3 == "U"
          h[:change] = :up
        elsif $3 == "D"
          h[:change] = :down
        end

        @runways << h

      end

    end
  end

end

