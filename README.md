# jsonapi-serializer-cr

JSON:API Serializer for Crystal Lang, see JSON:API Specification at https://jsonapi.org/

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     jsonapi-serializer-cr:
       github: andersondanilo/jsonapi-serializer-cr
   ```

2. Run `shards install`

## Usage

### Define your resource
```crystal
class MyResource
  property id : Int32?
  property name : String
  property description : String?
  property other_resource : OtherResource?
  property dependencies : Array(Dependency) = [] of Dependency
  property brother_id : Int32?

  def initialize(@name)
  end
end
```

### Define your serializer
```crystal
class MyResourceSerializer < JSONApiSerializer::ResourceSerializer(MyResource)
  identifier id
  type "my-resource"
  attribute name
  attribute description
  relationship(other_resource) { @other_resource_serializer }
  relationship(dependencies) { DependencyResourceSerializer.new }
  relationship_id brother_id, "brother", "brothers"

  def initialize(@other_resource_serializer : OtherResourceSerializer)
    super(nil)
  end
end
```

### Start serializing and deserializing
```crystal
require "jsonapi-serializer-cr"

# instantialize serializer (MyResourceSerializer) and entity (MyResource)
# ...

# serialize
json = serializer.serialize(entity)

# or deserialize
entity = serializer.deserialize(json)

# You can set options to the serializer
serializer.options = JSONApiSerializer::SerializeOptions.new(change_case: "camelcase")

# You can deserialize a object replacing the attributes based on an already constructed object (updating an existing object)
entity = serializer.deserialize! json, my_resource

# The difference between "deserialize!" and "deserialize" is that "deserialize!" throws JSONApiSerializer::DeserializeException, "deserialize" only return nil
```

```crystal

```

## Contributing

1. Fork it (<https://github.com/your-github-user/jsonapi-serializer-cr/fork>)
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Anderson Danilo](https://github.com/andersondanilo) - creator and maintainer
