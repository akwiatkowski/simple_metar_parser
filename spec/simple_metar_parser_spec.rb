require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "SimpleMetarParser" do
  it "simple test" do
    SimpleMetarParser.should be_kind_of(Module)
    SimpleMetarParser::Parser.should be_kind_of(Class)
    SimpleMetarParser::Metar.should be_kind_of(Class)
  end
end
