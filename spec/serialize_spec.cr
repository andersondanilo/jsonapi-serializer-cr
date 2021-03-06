require "./spec_helper"

module SerializeSpec
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
end

describe JSONApiSerializer::ResourceSerializer do
  it "serialize" do
    my_resource = SerializeSpec::MyResource.new "Teste"
    my_resource.id = 5
    my_resource.description = "teste"
    my_resource.other_resource = SerializeSpec::OtherResource.new(6, "Ok")
    my_resource.brother_id = 7
    my_resource.dependencies = [
      SerializeSpec::Dependency.new("5", SerializeSpec::OtherResource.new(6, "Ok")),
      SerializeSpec::Dependency.new("6", SerializeSpec::OtherResource.new(7, "Ok")),
    ]

    other_serializer = SerializeSpec::OtherResourceSerializer.new

    serializer = SerializeSpec::MyResourceSerializer.new(other_serializer)

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
          },
          "brother": {
            "data": {
              "id": "7",
              "type": "brothers"
            }
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
          },
          "brother": {
            "data": {
              "id": "7",
              "type": "brothers"
            }
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

  it "serialize multiple entities" do
    my_resource_1 = SerializeSpec::MyResource.new "Teste"
    my_resource_1.id = 5
    my_resource_1.description = "teste"
    my_resource_1.other_resource = SerializeSpec::OtherResource.new(6, "Ok")
    my_resource_1.brother_id = 7
    my_resource_1.dependencies = [
      SerializeSpec::Dependency.new("5", SerializeSpec::OtherResource.new(6, "Ok")),
      SerializeSpec::Dependency.new("6", SerializeSpec::OtherResource.new(7, "Ok")),
    ]

    my_resource_2 = SerializeSpec::MyResource.new "Teste"
    my_resource_2.id = 6
    my_resource_2.description = "teste"
    my_resource_2.other_resource = SerializeSpec::OtherResource.new(6, "Ok")
    my_resource_2.brother_id = 7
    my_resource_2.dependencies = [
      SerializeSpec::Dependency.new("5", SerializeSpec::OtherResource.new(6, "Ok")),
      SerializeSpec::Dependency.new("9", SerializeSpec::OtherResource.new(7, "Ok")),
    ]

    other_serializer = SerializeSpec::OtherResourceSerializer.new

    serializer = SerializeSpec::MyResourceSerializer.new(other_serializer)

    response = serializer.serialize([my_resource_1, my_resource_2])
    response.should_not be_nil
    JSON.parse(response.not_nil!).to_pretty_json.should eq <<-END
    {
      "data": [
        {
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
            },
            "brother": {
              "data": {
                "id": "7",
                "type": "brothers"
              }
            }
          }
        },
        {
          "id": "6",
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
                  "id": "9",
                  "type": "dependency"
                }
              ]
            },
            "brother": {
              "data": {
                "id": "7",
                "type": "brothers"
              }
            }
          }
        }
      ],
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
        },
        {
          "id": "9",
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
        }
      ]
    }
    END
  end
end
