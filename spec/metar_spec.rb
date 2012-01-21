require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

sample_metar = "LBBG 041600Z 12003MPS 310V290 1400 R04/P1500N R22/P1500U +SN BKN022 OVC050 M04/M07 Q1020 NOSIG 9949//91="

describe "SimpleMetarParser::Metar" do
  it "simple test" do
    m = SimpleMetarParser::Parser.parse(sample_metar)
    m.raw.should == sample_metar
  end

  it "should get city information using fake AR class" do
    # fake class
    class FakeCity
      def self.find_by_metar(m)
        return {:city => m}
      end
    end

    SimpleMetarParser::Metar.rails_model = FakeCity
    m = SimpleMetarParser::Parser.parse(sample_metar)
    m.city_model.should == FakeCity.find_by_metar('LBBG')

    SimpleMetarParser::Metar.rails_model = nil
    m = SimpleMetarParser::Parser.parse(sample_metar)
    m.city_model.should == nil
  end

  it "change time range" do
    time_range = SimpleMetarParser::Metar::DEFAULT_TIME_INTERVAL
    m = SimpleMetarParser::Parser.parse(sample_metar)
    m.time_interval.should == time_range
    m.time_from.should == m.time_to - time_range

    time_range = 3600
    m = SimpleMetarParser::Parser.parse(sample_metar, {:time_interval => time_range})
    m.time_interval.should == time_range
    m.time_from.should == m.time_to - time_range
  end

  it "decode metar string" do
    # http://www.metarreader.com/
    
    metar_string = "LBBG 041600Z 12003MPS 310V290 1400 R04/P1500N R22/P1500U +SN BKN022 OVC050 M04/M07 Q1020 NOSIG 9949//91="

    m = SimpleMetarParser::Parser.parse(sample_metar)
    m.time_from.utc.day.should == 4
    m.time_from.utc.hour.should == 16
    m.time_from.utc.min.should == 0

    (m.time_to - m.time_from).should == 30*60

    m.city.should == "LBBG"

    m.wind.should be_kind_of(SimpleMetarParser::Wind)
    m.wind.wind_direction.should == 120
    m.wind.wind_speed.should == 3

    

  end

end
