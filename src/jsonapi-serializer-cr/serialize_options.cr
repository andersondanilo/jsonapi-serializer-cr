module JSONApiSerializer
  class SerializeOptions
    property change_case : String

    def initialize(@change_case = "no")
    end
  end
end
