module StudentApi
  require 'uri'
  require 'net/http'
  OK_CODE = "200"

  def mvr_status(uniqname)
    mvr_status = ''
    url = URI("https://ltp.fo.umich.edu/mvr/api/api.php?action=check_status&uniqname=#{uniqname}")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    request = Net::HTTP::Get.new(url)
    request["x-api-key"] = ENV["SYGIC_API_KEY"]
    request["cache-control"] = 'no-cache'

    response = http.request(request)
    data = JSON.parse(response.read_body)
    unless data['mvr_status'].nil?
      mvr_status = data['mvr_status']
    end
    if data['expires'].present?
      mvr_status += " until " + data['expires']
    end
    return mvr_status
  end

  def class_roster_operational(term_code, subject_code, catalog_number, class_section, access_token)
    begin
      result = {'success' => false, 'errorcode' => '', 'error' => '', 'data' => {}}
      url = URI("https://gw.api.it.umich.edu/um/aa/ClassRoster/Terms/#{term_code}/SubjectCode/#{subject_code}?CatalogNumber=#{catalog_number}&ClassSection=#{class_section}")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER

      request = Net::HTTP::Get.new(url)
      request["x-ibm-client-id"] = "#{Rails.application.credentials.um_api[:client_id]}"
      request["authorization"] = "Bearer #{access_token}"
      request["accept"] = 'application/json'

      response = http.request(request)
      if response.is_a?(Net::HTTPGatewayTimeout)
        result['errorcode'] = "GatewayTimeout Error accessing Students Roster"
        result['error'] = "Please try again later"
      else
        response_json = JSON.parse(response.read_body)
        if response_json['errorCode'].present?
          result['errorcode'] = response_json['errorCode']
          result['error'] = response_json['errorMessage']
        elsif response_json['getClassMembersOperResponse']['Classes'].present?
          result['success'] = true
          result['data'] = response_json['getClassMembersOperResponse']['Classes']
        else
          result['errorcode'] = "API error"
          result['error'] = "check the course name; "
        end
      end
    rescue StandardError => e
      result['errorcode'] = "Exception"
      result['error'] = e.message
    end
    return result
  end

  def update_students(program)
    begin
      # add new students and delete those who dropped the course
      scope = "classroster"
      token = get_auth_token(scope)
      notice = ""
      alert = ""
      if token['success']
        courses = program.courses
        courses.each do |course|
          result = class_roster_operational(program.term.code, course.subject, course.catalog_number, course.class_section, token['access_token'])
          if result['success']
            if result['data']['Class']['ClassSections']['ClassSection']['ClassStudents'].present?
              data = result['data']['Class']['ClassSections']['ClassSection']['ClassStudents']['ClassStudent']
              if data.class == Hash
                data1 = []
                data1 << data
                data = data1
              end
              students_in_db_registered = program.students.registered.where(course_id: course.id).pluck(:uniqname)
              students_in_db_added_manually = program.students.added_manually.pluck(:uniqname)
              data.each do |student_info|
                if student_info['EnrollmentStatus'] == "Enrolled"
                  uniqname = student_info['Uniqname']
                  if students_in_db_registered.include?(uniqname)
                    students_in_db_registered.delete(uniqname)
                  elsif students_in_db_added_manually.include?(uniqname)
                    unless Student.find_by(uniqname: student_info['Uniqname'], program: program, course: nil).update(registered: true, course: course)
                    alert += "#{course.display_name}: Error updating student #{student_info['Uniqname']} record from manually added to registered."
                    end
                  else
                    student = Student.new(uniqname: student_info['Uniqname'], first_name: student_info['Name'].split(",").last, last_name: student_info['Name'].split(",").first, program: program, course: course)
                    unless student.save
                      alert += "#{course.display_name}: Student (uniqname - #{student_info['Uniqname']}) was not added: " + student.errors.full_messages.join(',')
                    end
                  end
                end
              end
              if students_in_db_registered.present?
                # delete students who dropped the course
                students_in_db_registered.each do |uniqname|
                  student = Student.find_by(uniqname: students_in_db_registered, program_id: program, course_id: course.id)
                  if student.reservations.present?
                    student.update(registered: false, course_id: nil)
                  else
                    student.delete
                  end
                end
              end
              notice += "#{course.display_name}: Student list is updated. "
            else
              notice += "The #{course.display_name} course has no students registered."
            end
          else
            alert += "#{course.display_name}: " + result['errorcode'] + ": " + result['error']
          end
        end
        unless program.update(number_of_students: program.students.count)
          alert += "Error updating number of students."
        end
      else
        flash.now[:alert] = token['error']
        return
      end
    rescue StandardError => e
      alert += "There is an error updating student list: " + e.message + "; "
    end
    flash.now[:notice] = notice
    flash.now[:alert] = alert
  end

  def canvas_readonly(course_id, access_token)
    begin
      page = "first"
      per_page = 100
      students_with_pass_score = {}
      next_page = true
      result = {'success' => false, 'error' => '', 'data' => []}
      while next_page do
        url = URI("https://gw.api.it.umich.edu/um/aa/CanvasReadOnly/courses/#{course_id}/enrollments?page=#{page}&per_page=#{per_page}")
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER

        request = Net::HTTP::Get.new(url)
        request["x-ibm-client-id"] = "#{Rails.application.credentials.um_api[:client_id]}"
        request["authorization"] = "Bearer #{access_token}"
        request["accept"] = 'application/json'

        response = http.request(request)
        response_json = JSON.parse(response.read_body)
        link = response.to_hash["link"].to_s
        if link.include? 'rel=\"next\"'
          next_link = link.split(",").second
          page = "bookmark" + next_link.split("page=bookmark").last.split("&per_page").first
        else
          next_page = false
        end
        if response.code == OK_CODE
          if response_json.present?
            response_json.each do |student|
              if student['grades'].present? && student['grades']['current_score'] == 100
                students_with_pass_score.merge! Hash[student['user']['login_id'], student['updated_at']]
              end
            end
            result['success'] = true
          else
            result['error'] = " course id #{course_id} - empty result"
          end
        else
          if response_json.is_a?(Hash) && response_json['errors'].present?
            result['error'] = "course id #{course_id} - " + response_json['errors'][0]['message']
          else
            result['error'] = "course id #{course_id} - " + "unknown error"
          end
        end
      end
      result['data'] = students_with_pass_score
    rescue => error
      result['error'] = error.message
      return result
    end
    return result
  end

  def update_my_canvas_status(student, program)
    scope = "canvasreadonly"
    token = get_auth_token(scope)
    if token['success']
      result = canvas_readonly(program.canvas_course_id, token['access_token'])
    end
    if result['success']
      students_with_good_score = result['data']
      uniqnames = students_with_good_score.keys
      if uniqnames.include?(student.uniqname)
        return students_with_good_score[student.uniqname]
      end
    end
    return false
  end

  def get_auth_token(scope)
    returned_data = {'success' => false, "error" => "", 'access_token' => nil}
    url = URI("https://gw.api.it.umich.edu/um/oauth2/token")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    request = Net::HTTP::Post.new(url)
    request["content-type"] = 'application/x-www-form-urlencoded'
    request["accept"] = 'application/json'
    request.body = "grant_type=client_credentials&client_id=#{Rails.application.credentials.um_api[:client_id]}&client_secret=#{Rails.application.credentials.um_api[:client_secret]}&scope=#{scope}"

    response = http.request(request)
    response_json = JSON.parse(response.read_body)
    if response_json['access_token'].present?
      returned_data['success'] = true
      returned_data['access_token'] = response_json['access_token']
    else
      returned_data['error'] = response_json
    end
    return returned_data
  end

  def get_name(uniqname)
    result = {'valid' => false, 'note' => '', 'last_name' => '', 'first_name' => ''}
    valid = LdapLookup.uid_exist?(uniqname)
    if valid
      result['valid'] = true
      name = LdapLookup.get_simple_name(uniqname)
      if name.include?("No displayname")
        result['note'] = " Mcommunity returns no name for '#{uniqname}' uniqname."
      else
        result['first_name'] = name.split(" ").first
        result['last_name'] = name.split(" ").last
      end
    else
      result['note'] = "The '#{uniqname}' uniqname is not valid."
    end
    return result
  end

end
