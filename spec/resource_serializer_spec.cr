require "./spec_helper"

class MyResource
  property id : Int32?
  property name : String
  property description : String?
  property other_resource : OtherResource?
  property dependencies : Array(Dependency) = [] of Dependency

  def initialize(@name)
  end
end

class MyResourceSerializer < JSONApiSerializer::ResourceSerializer(MyResource)
  identifier id
  type "my-resource"
  attribute name
  attribute description
  relationship(other_resource) { @other_resource_serializer }
  relationship(dependencies) { DependencyResourceSerializer.new }

  def initialize(@other_resource_serializer : OtherResourceSerializer)
    super(nil)
  end
end

class OtherResource
  property id : Int32
  property name : String

  def initialize(@id, @name)
  end
end

class OtherResourceSerializer < JSONApiSerializer::ResourceSerializer(OtherResource)
  identifier id
  type "other-resource"
  attribute name
end

class Dependency
  property id : String
  property dep_type : String = "Test"
  property resource : OtherResource

  def initialize(@id, @resource)
  end
end

class DependencyResourceSerializer < JSONApiSerializer::ResourceSerializer(Dependency)
  identifier id
  type "dependency"

  attribute dep_type

  relationship(resource) { OtherResourceSerializer.new }
end

describe JSONApiSerializer::ResourceSerializer do
  it "works" do
    my_resource = MyResource.new "Teste"
    my_resource.id = 5
    my_resource.description = "teste"
    my_resource.other_resource = OtherResource.new(6, "Ok")
    my_resource.dependencies = [
      Dependency.new("5", OtherResource.new(6, "Ok")),
      Dependency.new("6", OtherResource.new(7, "Ok")),
    ]

    other_serializer = OtherResourceSerializer.new

    serializer = MyResourceSerializer.new(other_serializer)

    response = serializer.serialize(my_resource)
    response.should_not be_nil
    JSON.parse(response.not_nil!).to_pretty_json.should eq <<-END
    {
      "data": {
        "id": "5",
        "type": "my-resource",
        "attributes": {
          "name": "Teste",
          "description": "teste"
        },
        "relationships": {
          "other_resource": {
            "data": {
              "id": "6",
              "type": "other-resource"
            }
          },
          "dependencies": {
            "data": [
              {
                "id": "5",
                "type": "dependency"
              },
              {
                "id": "6",
                "type": "dependency"
              }
            ]
          }
        }
      },
      "included": [
        {
          "id": "6",
          "type": "other-resource",
          "attributes": {
            "name": "Ok"
          }
        },
        {
          "id": "5",
          "type": "dependency",
          "attributes": {
            "dep_type": "Test"
          },
          "relationships": {
            "resource": {
              "data": {
                "id": "6",
                "type": "other-resource"
              }
            }
          }
        },
        {
          "id": "6",
          "type": "dependency",
          "attributes": {
            "dep_type": "Test"
          },
          "relationships": {
            "resource": {
              "data": {
                "id": "7",
                "type": "other-resource"
              }
            }
          }
        },
        {
          "id": "7",
          "type": "other-resource",
          "attributes": {
            "name": "Ok"
          }
        }
      ]
    }
    END

    serializer.options = JSONApiSerializer::SerializeOptions.new(change_case: "camelcase")
    serializer.change_case("other_resource").should eq "otherResource"

    response = serializer.serialize(my_resource)
    response.should_not be_nil
    JSON.parse(response.not_nil!).to_pretty_json.should eq <<-END
    {
      "data": {
        "id": "5",
        "type": "my-resource",
        "attributes": {
          "name": "Teste",
          "description": "teste"
        },
        "relationships": {
          "otherResource": {
            "data": {
              "id": "6",
              "type": "other-resource"
            }
          },
          "dependencies": {
            "data": [
              {
                "id": "5",
                "type": "dependency"
              },
              {
                "id": "6",
                "type": "dependency"
              }
            ]
          }
        }
      },
      "included": [
        {
          "id": "6",
          "type": "other-resource",
          "attributes": {
            "name": "Ok"
          }
        },
        {
          "id": "5",
          "type": "dependency",
          "attributes": {
            "depType": "Test"
          },
          "relationships": {
            "resource": {
              "data": {
                "id": "6",
                "type": "other-resource"
              }
            }
          }
        },
        {
          "id": "6",
          "type": "dependency",
          "attributes": {
            "depType": "Test"
          },
          "relationships": {
            "resource": {
              "data": {
                "id": "7",
                "type": "other-resource"
              }
            }
          }
        },
        {
          "id": "7",
          "type": "other-resource",
          "attributes": {
            "name": "Ok"
          }
        }
      ]
    }
    END
  end
end
