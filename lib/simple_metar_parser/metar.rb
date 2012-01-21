$:.unshift(File.dirname(__FILE__))

require 'metar/base'
require 'metar/wind'

module SimpleMetarParser
  class Metar

    DEFAULT_TIME_INTERVAL = 30 * 60

    def initialize(_raw, _options = { })
      @raw = _raw.to_s.gsub(/\s/, ' ').strip
      @raw_splits = @raw.split(' ')

      @options = _options
      @time_interval = _options[:time_interval] || DEFAULT_TIME_INTERVAL
      @year = _options[:year] || Time.now.utc.year
      @month = _options[:month] || Time.now.utc.month
      # metar city code
      @city = _options[:city]

      @modules = {
        :wind => Wind.new(self)
      }

      # Create dynamically accessors
      @modules.each_key do |k|
        self.instance_variable_set("@#{k}".to_sym, @modules[k])
        self.class.send :define_method, k do
          instance_variable_get( "@" + k.to_s )
        end
      end

      reset
      decode
      post_process

    end

    attr_reader :year, :month

    def reset
      @modules.each_value do |m|
        m.reset
      end
    end

    def post_process
      @wind.post_process
    end

    # Raw metar string
    attr_reader :raw

    # Splits of raw string
    attr_reader :raw_splits

    # Initial options
    attr_reader :options

    # Time "from"
    attr_reader :time
    alias :time_from :time

    # Interval of one metar
    attr_reader :time_interval

    # End of time period
    def time_to
      self.time_from + self.time_interval
    end

    # Metar code of city
    attr_reader :city

    # You can set AR model for fetching additional information about city
    def self.rails_model=(klass)
      @@rails_model_class = klass
    end

    # Get city information using AR
    def self.find_by_metar(metar)
      return nil if not defined? @@rails_model_class or @@rails_model_class.nil?
      @@rails_model_class.find_by_metar(metar)
    end

    # Decode all string fragments
    def decode
      self.raw_splits.each do |split|
        decode_split(split)
      end

      # one time last processes


      #calculate_humidity
      #calculate_cloud
      #calculate_rain_and_snow

      # if metar is invalid store it in log to check if decoder has error
      #if true == ConfigLoader.instance.config(self.class.to_s)[:store_decoder_errors]
      #  unless valid?
      #    AdvLog.instance.logger(self).error("Cant decode metar: '#{self.raw}', city '#{self.city}'")
      #  end
      #end
    end

    # Check if current split has proper information and store them inside
    def decode_split(split)
      decode_city(split)
      decode_time(split)

      @wind.decode_split(split)

      #decode_wind_variable(split)
      #decode_temperature(split)
      #decode_pressure(split)
      #dndode_visibility(split)
      #decode_clouds(split)
      #decode_specials(split)
      #check_cavok(split)
    end

    # Decode time
    def decode_time(s)
      if s =~ /(\d{2})(\d{2})(\d{2})Z/
        @time = Time.utc(self.year, self.month, $1.to_i, $2.to_i, $3.to_i, 0, 0)
      end
    end

    # City. Information about city is at the begin
    def decode_city(s)
      if s =~ /^([A-Z]{4})$/ and not s == 'AUTO' and not s == 'GRID' and not s == 'WNDS'
        @city = $1
        @city_model = self.class.find_by_metar(@city)
      end
    end

    # Addition city information fetched using AR
    attr_reader :city_model


  end
end