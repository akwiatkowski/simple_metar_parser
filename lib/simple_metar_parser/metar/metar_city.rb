$:.unshift(File.dirname(__FILE__))

module SimpleMetarParser
  class MetarCity < Base

    # You can set AR model for fetching additional information about city
    def self.rails_model=(klass)
      @@rails_model_class = klass
    end

    # Get city information using AR
    def self.find_by_metar(metar)
      return nil if not defined? @@rails_model_class or @@rails_model_class.nil?
      @@rails_model_class.find_by_metar(metar)
    end

    def reset
      @code = nil
      @model = nil
    end

    def decode_split(s)
      if s =~ /^([A-Z]{4})$/ and not s == 'AUTO' and not s == 'GRID' and not s == 'WNDS'
        @code = $1
        @model = self.class.find_by_metar(@code)
      end
    end

    # Addition city information fetched using AR
    attr_reader :model

    # Metar code of city
    attr_reader :code

  end
end