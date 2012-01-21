module SimpleMetarParser
  class Base

    def initialize(_parent)
      @parent = _parent
      reset
    end

    def reset
      # implement
    end

    def decode_split(s)
      # implement
    end

    def post_process
      # implement
    end

  end
end