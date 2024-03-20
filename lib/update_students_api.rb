class UpdateStudentsApi
  require 'uri'
  require 'net/http'

  def mvr_status(uniqname)
    mvr_status = ''
    url = URI("https://ltp.fo.umich.edu/mvr/api/api.php?action=check_status&uniqname=#{uniqname}")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

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
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

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

  def update_students(program, log)
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
                      log.api_logger.debug "#{course.display_name}: Error updating student - uniqname: #{student_info['Uniqname']} - record from manually added to registered."
                    end
                  else
                    student = Student.new(uniqname: student_info['Uniqname'], first_name: student_info['Name'].split(",").last, last_name: student_info['Name'].split(",").first, program: program, course: course)
                    unless student.save
                      log.api_logger.debug "#{course.display_name}: Student (uniqname - #{student_info['Uniqname']}) was not added: #{student.errors.full_messages.join(',')}"
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
              log.api_logger.info "The #{course.display_name} course has no students registered."
            end
          else
            alert += "#{course.display_name}: " + result['errorcode'] + ": " + result['error']
          end
        end
        unless program.update(number_of_students: program.students.count)
          log.api_logger.debug "Error updating number of students."
        end
        unless notice == ""
          log.api_logger.info "#{notice}"
        end
        unless alert == ""
          log.api_logger.debug "#{alert}"
        end
      else
        log.api_logger.debug "#{token['error']}"
        return
      end
    rescue StandardError => e
      log.api_logger.debug "There is an error updating student list: " + e.message
      return
    end
  end

  def get_auth_token(scope)
    returned_data = {'success' => false, "error" => "", 'access_token' => nil}
    url = URI("https://gw.api.it.umich.edu/um/oauth2/token")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

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
end

class ApiLog
  def api_logger
    @@api_logger ||= Logger.new("#{Rails.root}/log/api_nightly_update_db.log")
  end
end
