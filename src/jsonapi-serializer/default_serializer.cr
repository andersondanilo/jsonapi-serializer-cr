require "./serializer"
require "json"

module JSONApiSerializer
  class DefaultSerializer(T)
    include Serializer(T)

    def serialize(entity : T?) : String?
      if entity.nil?
        nil
      else
        entity.to_json
      end
    end

    def deserialize(value : JSON::Any, base : T? = nil) : T?
      {% begin %}
      value_as_type("value", {{@type}})
      {% end %}
      return value
    end

    macro value_as_type(var, path)
      {% type = path.resolve %}
      {% for gtype in type.type_vars %}
        {% if gtype.name =~ /Array/ %}
          {{var.id}} = {{var.id}}.as_a?

          unless {{var.id}}.nil?
            {{var.id}} = {{var.id}}.map do |v|
              value_as_type("v", {{gtype}})
              v.not_nil!
            end
          end
        {% else %}
          {{var.id}} = {{gtype.id}}.from_json({{var.id}}.to_json)
        {% end %}
      {% end %}
    end
  end
end
