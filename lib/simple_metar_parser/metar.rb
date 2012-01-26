$:.unshift(File.dirname(__FILE__))

require 'metar/base'
require 'metar/wind'
require 'metar/metar_time'
require 'metar/metar_city'
require 'metar/temperature'
require 'metar/pressure'
require 'metar/visibility'
require 'metar/clouds'
require 'metar/metar_specials'
require 'metar/metar_other'

module SimpleMetarParser
  class Metar

    DEFAULT_TIME_INTERVAL = 30 * 60

    def initialize(_raw, _options = { })
      @raw = _raw.to_s.gsub(/\s/, ' ').strip
      @raw_splits = @raw.split(' ')

      @options = _options
      @options[:time_interval] = _options[:time_interval] || DEFAULT_TIME_INTERVAL
      @year = _options[:year] || Time.now.utc.year
      @month = _options[:month] || Time.now.utc.month
      # metar city code
      @options_city = _options[:city]

      @modules = {
        :wind => Wind.new(self),
        :time => MetarTime.new(self),
        :city => MetarCity.new(self),
        :temperature => Temperature.new(self),
        :pressure => Pressure.new(self),
        :visibility => Visibility.new(self),
        :clouds => Clouds.new(self),
        :specials => MetarSpecials.new(self),
        :other => MetarOther.new(self)
      }

      # Create dynamically accessors
      @modules.each_key do |k|
        self.instance_variable_set("@#{k}".to_sym, @modules[k])
        self.class.send :define_method, k do
          instance_variable_get("@" + k.to_s)
        end
      end

      reset
      decode
      post_process
    end

    # Array of all parsing modules
    def modules
      @modules.values
    end

    attr_reader :year, :month

    # Raw metar string
    attr_reader :raw

    # Splits of raw string
    attr_reader :raw_splits

    # Initial options
    attr_reader :options

    # Reset everything
    def reset
      @modules.each_value do |m|
        m.reset
      end
    end

    # Decode all string fragments
    def decode
      self.raw_splits.each do |split|
        self.modules.each do |m|
          m.decode_split(split)
        end
      end
    end

    def post_process
      self.modules.each do |m|
        m.post_process
      end
    end

    # Additional accessors

    # You can set AR model for fetching additional information about city
    def self.rails_model=(klass)
      MetarCity.rails_model = klass
    end

    def time_from
      self.time.time_from
    end

    def time_to
      self.time.time_to
    end

    def valid?
      if not self.temperature.nil? and not self.temperature.degrees.nil? and
        not self.wind.nil? and
        not self.time_from.nil?
        return true
      else
        return false
      end

    end

  end
end