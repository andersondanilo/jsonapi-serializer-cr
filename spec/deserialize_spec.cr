require "./spec_helper"

module DeserializeSpec
  class MyResource
    property id : Int32?
    property name : String
    property description : String?
    property brother_id : String?

    def initialize(@name)
    end
  end

  class MyResourceSerializer < JSONApiSerializer::ResourceSerializer(MyResource)
    identifier id
    type "my-resource"
    attribute name
    attribute description
    relationship_id brother_id, "brother", "brothers"
  end
end

describe JSONApiSerializer::ResourceSerializer do
  it "deserialize" do
    json = <<-JSON
    {
      "data": {
        "id": "5",
        "type": "my-resource",
        "attributes": {
          "name": "Jen",
          "description": "My Description"
        },
        "relationships": {
          "brother": {
            "data": {
              "id": "ABC1",
              "type": "brothers"
            }
          }
        }
      }
    }
    JSON

    serializer = DeserializeSpec::MyResourceSerializer.new
    my_resource = serializer.deserialize! json
    my_resource.id.should eq 5
    my_resource.name.should eq "Jen"
    my_resource.description.should eq "My Description"
    my_resource.brother_id.should eq "ABC1"

    json = <<-JSON
    {
      "data": {
        "id": "5",
        "type": "my-resource",
        "attributes": {
          "name": "Jen",
          "description": "My Description"
        }
      }
    }
    JSON

    my_resource = serializer.deserialize! json, my_resource
    my_resource.id.should eq 5
    my_resource.name.should eq "Jen"
    my_resource.description.should eq "My Description"
    my_resource.brother_id.should eq "ABC1"

    json = <<-JSON
    {
      "data": {
        "id": "5",
        "type": "my-resource",
        "attributes": {
          "name": "Jen",
          "description": "My Description"
        }
      }
    }
    JSON

    my_resource = serializer.deserialize! json
    my_resource.id.should eq 5
    my_resource.name.should eq "Jen"
    my_resource.description.should eq "My Description"
    my_resource.brother_id.should be_nil

    json = <<-JSON
    {
      "data": {
        "id": "5",
        "type": "my-resource",
        "attributes": {
          "description": "My Description"
        }
      }
    }
    JSON

    expect_raises(JSONApiSerializer::DeserializeException, /null/) do
      my_resource = serializer.deserialize! json
    end
  end
end
