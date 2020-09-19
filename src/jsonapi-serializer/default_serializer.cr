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
        {% gtype = gtype.union_types.select { |t| t.name != "Nil" }.first %}

        {% if gtype.name =~ /Array/ %}
          {{var.id}} = {{var.id}}.as_a?

          unless {{var.id}}.nil?
            {{var.id}} = {{var.id}}.map do |v|
              value_as_type("v", {{gtype}})
              v.not_nil!
            end
          end
        {% elsif gtype.name =~ /^Int[0-9]*$/ %}
          {{var.id}} = {{var.id}}.raw

          {% valid_types = ["String", "Int64", "Int32", "Int16", "Int8"] %}

          if {{var.id}}.is_a?({{ valid_types.join("|").id }})
            {% if gtype.name =~ /Int64/ %}
              {{var.id}} = {{var.id}}.as({{valid_types.join("|").id}}).to_i64
            {% elsif gtype.name =~ /Int16/ %}
              {{var.id}} = {{var.id}}.as({{valid_types.join("|").id}}).to_i16
            {% elsif gtype.name =~ /Int8/ %}
              {{var.id}} = {{var.id}}.as({{valid_types.join("|").id}}).to_i8
            {% else %}
              {{var.id}} = {{var.id}}.as({{valid_types.join("|").id}}).to_i32
            {% end %}

            {{var.id}} = {{var.id}}.as({{gtype.id}})
          else
            {{var.id}} = nil
          end
        {% elsif gtype.name =~ /^Float[0-9]*$/ %}
          {{var.id}} = {{var.id}}.raw

          {% valid_types = ["String", "Float64", "Float32"] %}

          if {{var.id}}.is_a?({{ valid_types.join("|").id }})
            {% if gtype.name =~ /^Float64/ %}
              {{var.id}} = {{var.id}}.as({{valid_types.join("|").id}}).to_f64
            {% else %}
              {{var.id}} = {{var.id}}.as({{valid_types.join("|").id}}).to_f32
            {% end %}

            {{var.id}} = {{var.id}}.as({{gtype.id}})
          else
            {{var.id}} = nil
          end
        {% elsif gtype.name == "String" %}
          {{var.id}} = {{var.id}}.raw

          {% valid_types = ["String", "Float64", "Float32", "Int64", "Int32", "Int16", "Int8", "Bool"] %}

          if {{var.id}}.is_a?({{ valid_types.join("|").id }})
            {{var.id}} = {{var.id}}.as({{valid_types.join("|").id}}).to_s
          else
            {{var.id}} = nil
          end
        {% elsif gtype.name == "Bool" %}
          {{var.id}} = {{var.id}}.raw

          if {{var.id}}.is_a?(Bool)
            {{var.id}} = {{var.id}}.as(Bool)
          elsif {{var.id}}.is_a?(Int) || {{var.id}}.is_a?(Float)
            {{var.id}} = {{var.id}} == 1
          else
            {{var.id}} = nil
          end
        {% elsif gtype.name == "Time" %}
          {{var.id}} = {{var.id}}.raw

          if {{var.id}}.is_a?(String)
            time_value = nil

            begin
              time_value = Time::Format::ISO_8601_DATE_TIME.parse({{var.id}}.as(String), Time::Location::UTC)
            rescue Time::Format::Error
            end

            if time_value.nil?
              begin
                time_value = Time.parse({{var.id}}.as(String), "%Y-%m-%d %H:%M:%S", Time::Location::UTC)
              rescue Time::Format::Error
              end
            end

            if time_value.nil?
              begin
                time_value = Time::Format::ISO_8601_DATE.parse({{var.id}}.as(String), Time::Location::UTC)
              rescue Time::Format::Error
              end
            end

            {{var.id}} = time_value
          else
            {{var.id}} = nil
          end
        {% else %}
          {{var.id}} = {{gtype.id}}.from_json({{var.id}}.to_json)
        {% end %}
      {% end %}
    end
  end
end
