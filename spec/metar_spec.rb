require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

sample_metar = "LBBG 041600Z 12003MPS 310V290 1400 R04/P1500N R22/P1500U +SN BKN022 OVC050 M04/M07 Q1020 NOSIG 9949//91="

describe "SimpleMetarParser::Metar" do
  it "simple test" do
    m = SimpleMetarParser::Parser.parse(sample_metar)
    m.raw.should == sample_metar
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

end
