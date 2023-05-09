module ManagerApi

  def get_name(uniqname, program)
    result = {'valid' => false, 'note' => '', 'last_name' => '', 'first_name' => ''}
    name = LdapLookup.get_simple_name(uniqname)
    if name == "No such user"
      result['note'] = "The '#{uniqname}' uniqname is not valid."
    else
      if program.instructor.uniqname == uniqname
        result['note'] = "#{uniqname} is instructor's uniqname"
      else
        result['valid'] =  true
        if name.nil?
          result['note'] = "Mcommunity returns no name for '#{uniqname}' uniqname."
        else
          result['first_name'] = name.split(" ").first
          result['last_name'] = name.split(" ").last
        end
      end
    end
    return result
  end

end
