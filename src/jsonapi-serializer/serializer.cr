module JSONApiSerializer
  module Serializer(T)
    abstract def serialize(entity : T?) : String?

    def deserialize(json : String, base : T? = nil) : T?
      value = JSON.parse(json)
      deserialize(value, base)
    end

    abstract def deserialize(value : JSON::Any, base : T? = nil) : T?
  end
end
