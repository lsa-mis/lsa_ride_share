module StudentApi
  require 'uri'
  require 'net/http'

  def mvr_status(uniqname)
    #  https://ltp.fo.umich.edu/mvr/api/api.php?action=check_status&uniqname=hodel

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
    response_json = JSON.parse(response.read_body)
    if response_json['errorCode'].present?
      result['errorcode'] = response_json['errorCode']
      result['error'] = response_json['errorMessage']
    else
      result['success'] = true
      result['data'] = response_json['getClassMembersOperResponse']
    end
    return result
  end

  def canvas_readonly(course_id, access_token)
    result = {'success' => false, 'error' => '', 'data' => []}
    url = URI("https://gw.api.it.umich.edu/um/aa/CanvasReadOnly/courses/#{course_id}/enrollments")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(url)
    request["x-ibm-client-id"] = "#{Rails.application.credentials.um_api[:client_id]}"
    request["authorization"] = "Bearer #{access_token}"
    request["accept"] = 'application/json'

    response = http.request(request)
    response_json = JSON.parse(response.read_body)
    if response_json.is_a?(Hash) && response_json['errors'].present?
      result['error'] = "course id #{course_id} - " + response_json['errors'][0]['message']
    else
      if response_json.present?
        students_with_pass_score = {}
        response_json.each do |student|
          # test with < 100.00, uniqnames brwern 
          if student['grades'].present? and student['grades']['final_score'] == 100.00
            students_with_pass_score.merge! Hash[student['user']['login_id'], student['last_activity_at']]
          end
        end
        result['success'] = true
        result['data'] = students_with_pass_score
      else
        result['error'] = " course id #{course_id} - empty result"
      end
    end
    return result
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