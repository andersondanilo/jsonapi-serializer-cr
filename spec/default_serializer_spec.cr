require "./spec_helper"

describe JSONApiSerializer::DefaultSerializer do
  it "works" do
    int_serializer = JSONApiSerializer::DefaultSerializer(Int32).new
    int_serializer.deserialize("3").should eq 3
    int_serializer.deserialize("\"3\"").should eq 3
    int_serializer.serialize(3).should eq "3"

    int_serializer = JSONApiSerializer::DefaultSerializer(Int8).new
    int_serializer.deserialize("3").should eq 3
    int_serializer.deserialize("\"3\"").should eq 3
    int_serializer.serialize(3).should eq "3"

    float_serializer = JSONApiSerializer::DefaultSerializer(Float32).new
    float_serializer.deserialize("3.5").should eq 3.5
    float_serializer.deserialize("\"3.5\"").should eq 3.5
    float_serializer.serialize(3.5).should eq "3.5"

    float_serializer = JSONApiSerializer::DefaultSerializer(Float64).new
    float_serializer.deserialize("3.5").should eq 3.5
    float_serializer.deserialize("\"3.5\"").should eq 3.5
    float_serializer.serialize(3.5).should eq "3.5"

    str_serializer = JSONApiSerializer::DefaultSerializer(String).new
    str_serializer.deserialize("\"3.5\"").should eq "3.5"
    str_serializer.deserialize("3.5").should eq "3.5"
    str_serializer.serialize("3.5").should eq "\"3.5\""

    bool_serializer = JSONApiSerializer::DefaultSerializer(Bool).new
    bool_serializer.deserialize("true").should eq true
    bool_serializer.deserialize("1").should eq true
    bool_serializer.deserialize("0").should eq false
    bool_serializer.serialize(true).should eq "true"

    bool_serializer = JSONApiSerializer::DefaultSerializer(Bool?).new
    bool_serializer.deserialize("true").should eq true
    bool_serializer.deserialize("1").should eq true
    bool_serializer.deserialize("0").should eq false
    bool_serializer.serialize(true).should eq "true"

    arr_serializer = JSONApiSerializer::DefaultSerializer(Array(Int32)).new
    arr_serializer.deserialize("[1, 2]").should eq [1, 2]
    arr_serializer.serialize([1, 2]).should eq "[1,2]"

    time_serializer = JSONApiSerializer::DefaultSerializer(Time).new
    time = Time.local(2020, 1, 2, 10, 55, 30)
    time_serializer.serialize(time).should eq time.to_json
    time_serializer.deserialize(time.to_json).should eq time
    time_serializer.deserialize("\"2020-01-10\"").should eq Time.utc(2020, 1, 10)
    time_serializer.deserialize("\"2020-01-10 11:12:13\"").should eq Time.utc(2020, 1, 10, 11, 12, 13)
  end
end
