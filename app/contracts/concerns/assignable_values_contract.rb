module AssignableValuesContract
  def assignable_values(column, _user)
    method_name = "assignable_#{column.to_s.pluralize}"

    puts "AssignableValuesContract: #{method_name}"

    if respond_to?(method_name, true)
      send(method_name)
    end
  end
end
