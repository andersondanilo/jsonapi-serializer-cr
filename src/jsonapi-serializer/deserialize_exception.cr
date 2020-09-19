module JSONApiSerializer
  class DeserializeException < Exception
    property path : String?
    property error_type : ErrorType?

    enum ErrorType
      MALFORMED_JSON
      REQUIRED_ATTRIBUTE
    end
  end
end
