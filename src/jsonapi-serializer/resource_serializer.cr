require "./serializer"
require "./serialize_options"
require "json"

module JSONApiSerializer
  abstract class ResourceSerializer(T)
    alias JSONType = Nil | Bool | Int64 | Float64 | String | Array(JSONType) | Hash(String, JSONType)

    include Serializer(T)

    property options : SerializeOptions

    def initialize(options : SerializeOptions? = nil)
      if options.nil?
        @options = SerializeOptions.new
      else
        @options = options
      end
    end

    def options=(v : SerializeOptions)
      @options = v
    end

    annotation Metadata
    end

    abstract def get_type : String

    ATTR_MACROS = ["identifier", "attribute", "relationship"]

    {% for attr_macro in ATTR_MACROS %}
      private macro {{attr_macro.id}}(name_call, &block)
        \{% name = name_call.name %}

        @[Metadata(type: "{{attr_macro.id}}", name: "\{{name}}")]
        {% if attr_macro =~ /relationship/ %}
        protected def _metadata_{{attr_macro.id}}_\{{name}} : JSONApiSerializer::ResourceSerializer
        {% else %}
        protected def _metadata_{{attr_macro.id}}_\{{name}}
        {% end %}
          \{% if block %}
            \{{yield}}
          \{% else %}
            {% if attr_macro =~ /relationship/ %}
              raise "Expected resource serializer for relationship \{{name}}"
            {% else %}
              nil
            {% end %}
          \{% end %}
        end
      end
    {% end %}

    private macro relationship_id(attr_call, rel_name, res_type)
      {% attr_name = attr_call.name %}
      @[Metadata(type: "relationship_id", name: "{{attr_name}}", rel_name: {{rel_name}}, res_type: {{res_type}})]
      protected def _metadata_relationship_id_{{attr_name}}
      end
    end

    private macro type(name)
      def get_type : String
        {{name}}
      end
    end

    def change_case(name : String) : String
      case @options.change_case
      when "camelcase"
        return name.camelcase(lower: true)
      when "no"
        return name
      else
        raise "invalid change_case #{@options.change_case}"
      end
    end

    macro inherited
      macro finished
        {% verbatim do %}
          {% identifier_name = nil %}
          {% attr_names = [] of StringLiteral %}
          {% rel_names = [] of StringLiteral %}
          {% rel_id_names = [] of StringLiteral %}
          {% rel_id_metadata = {} of StringLiteral => Annotation %}

          {% for m in @type.methods %}
            {% meta_ann = m.annotation(Metadata) %}
            {% if meta_ann %}
              {% if meta_ann[:type] == "identifier" %}
                {% identifier_name = meta_ann[:name] %}
              {% elsif meta_ann[:type] == "attribute" %}
                {% attr_names << meta_ann[:name] %}
              {% elsif meta_ann[:type] == "relationship" %}
                {% rel_names << meta_ann[:name] %}
              {% elsif meta_ann[:type] == "relationship_id" %}
                {% rel_id_names << meta_ann[:name] %}
                {% rel_id_metadata[meta_ann[:name]] = meta_ann %}
              {% end %}
            {% end %}
          {% end %}

          def serialize(entity : T?) : String?
            if entity.nil?
              return "null"
            end

            response = {"data" => {} of String => JSON::Any, "included" => [] of JSON::Any}

            serialized_id = serialize_id(entity)

            unless serialized_id.raw.nil?
              response["data"].as(Hash)["id"] = serialized_id
            end

            response["data"].as(Hash)["type"] = JSON::Any.new(get_type)
            response["data"].as(Hash)["attributes"] = serialize_attributes(entity)

            is_included = ["#{get_type}/#{serialized_id}"]

            {% if rel_names.size > 0 %}
              response["data"].as(Hash)["relationships"] = serialize_relationships(entity)
              response["included"] = serialize_included(entity, is_included)

              if response["included"].as(Array).empty?
                response.delete("included")
              end
            {% end %}

            return response.to_json
          end

          def serialize_id(entity : T) : JSON::Any
            {% if identifier_name %}
              JSON::Any.new(entity.{{identifier_name.id}}.try(&.to_s))
            {% else %}
              raise "resource without identifier"
            {% end %}
          end

          def serialize_attributes(entity : T) : JSON::Any
            return serialize_attributes_macro
          end

          macro serialize_attributes_macro
            \{% resource_class = @type.superclass.type_vars.first %}
            attributes = {} of String => JSON::Any

            {% for attr_name in attr_names %}
              value = JSON::Any.new(nil)
              serialize_attribute_name_macro({{attr_name}})
              attributes[change_case({{attr_name}})] = value
            {% end %}


            attributes = JSON::Any.new(attributes)
            return attributes
          end

          macro serialize_attribute_name_macro(name)
            {% verbatim do %}
              {% resource_class = @type.superclass.type_vars.first %}
              {% attr_type = nil %}
              {% for ivar in resource_class.instance_vars %}
                {% if ivar.name == name.id %}
                  {% attr_type = ivar.type %}
                {% end %}
              {% end %}

              {% if attr_type.nil? %}
                raise "attr {{name.id}} doest not exists on entity"
              {% else %}
                serializer = _metadata_attribute_{{name.id}}

                if serializer.nil?
                  serializer = JSONApiSerializer::DefaultSerializer({{attr_type}}).new
                end

                raw_value = entity.{{name.id}}

                if raw_value.is_a?(JSONType)
                  value = JSON::Any.new(raw_value)
                else
                  str_value = serializer.serialize(raw_value)

                  if str_value.nil?
                    value = JSON::Any.new(nil)
                  else
                    value = JSON.parse(str_value)
                  end
                end
              {% end %}
            {% end %}
          end

          def serialize_relationships(entity : T) : JSON::Any
            return serialize_relationships_macro
          end

          macro serialize_relationships_macro
            relationships = {} of String => JSON::Any

            {% for rel_name in rel_names %}
              serializer = _metadata_relationship_{{rel_name.id}}
              serializer.options = @options

              relationships[change_case({{rel_name}})] = JSON::Any.new({
                "data" => serialize_relationship_macro({{rel_name}})
              })
            {% end %}

            {% for rel_id_name in rel_id_names %}
              {% ann = rel_id_metadata[rel_id_name] %}
              if entity.{{rel_id_name.id}}.nil?
                rel_id_data = JSON::Any.new(nil)
              elsif entity.{{rel_id_name.id}}.is_a?(Array)
                rel_id_data = JSON::Any.new(entity.{{rel_id_name.id}}.as(Array).map do |id|
                  JSON::Any.new({
                    "id" => JSON::Any.new(id.to_s),
                    "type" => JSON::Any.new({{ann[:res_type]}})
                  })
                end)
              else
                rel_id_data = JSON::Any.new({
                  "id" => JSON::Any.new(entity.{{rel_id_name.id}}.to_s),
                  "type" => JSON::Any.new({{ann[:res_type]}})
                })
              end
              relationships[change_case({{ann[:rel_name]}})] = JSON::Any.new({
                "data" => rel_id_data
              })
            {% end %}


            relationships = JSON::Any.new(relationships)
            return relationships
          end

          macro serialize_relationship_macro(rel_name)
            if entity.\{{rel_name.id}}.nil?
              JSON::Any.new(nil)
            else
              json_value = nil

              if entity.\{{rel_name.id}}.is_a?(Array)
                json_value = JSON::Any.new(entity.\{{rel_name.id}}.as(Array).map do |rel_entity|
                  JSON::Any.new({
                    "id" => serializer.serialize_id(rel_entity.not_nil!),
                    "type" => JSON::Any.new(serializer.get_type)
                  })
                end)
              else
                value = entity.\{{rel_name.id}}
                unless value.is_a?(Array)
                  json_value = JSON::Any.new({
                    "id" => serializer.serialize_id(value.not_nil!),
                    "type" => JSON::Any.new(serializer.get_type)
                  })
                end
              end

              if json_value.nil?
                JSON::Any.new(nil)
              else
                json_value
              end
            end
          end

          def serialize_included(entity : T, is_included : Array(String)) : Array(JSON::Any)
            return serialize_included_macro
          end

          macro serialize_included_macro
            included = [] of JSON::Any

            {% for rel_name in rel_names %}
              serializer = _metadata_relationship_{{rel_name.id}}
              serializer.options = @options

              inc_entity_base = entity.{{rel_name.id}}

              unless inc_entity_base.nil?
                if inc_entity_base.is_a?(Array)
                  inc_entity_array = inc_entity_base
                else
                  inc_entity_array = [inc_entity_base]
                end

                inc_entity_array.each do |inc_entity|
                  unless inc_entity.nil?
                    key = "#{serializer.get_type}/#{serializer.serialize_id(inc_entity)}"

                    unless is_included.includes?(key)
                      inc_data = JSON::Any.new({
                        "id" => serializer.serialize_id(inc_entity),
                        "type" => JSON::Any.new(serializer.get_type),
                        "attributes" => serializer.serialize_attributes(inc_entity),
                      })

                      inc_relationships = serializer.serialize_relationships(inc_entity)

                      unless inc_relationships.as_h.empty?
                        inc_data.as_h["relationships"] = inc_relationships
                      end

                      included << inc_data
                      is_included << key

                      serializer.serialize_included(inc_entity, is_included).each do |inc_included|
                        included << inc_included
                      end
                    end
                  end
                end
              end
            {% end %}

            return included
          end

          def deserialize(value : JSON::Any, base : T? = nil) : T?
          end
        {% end %}
      end
    end
  end
end
