class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |var|
      define_method(var) do
        instance_variable_get("@#{var.to_s}")
      end
      define_method("#{var}=") do |value|
        instance_variable_set("@#{var.to_s}", value)
      end
    end
  end
end
