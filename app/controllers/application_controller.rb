class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include ApplicationHelper

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  after_action :verify_authorized, unless: :devise_controller?
  skip_after_action :verify_authorized, only: [:delete_file_attachment]

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(root_path)
  end

  def pundit_user
    { user: current_user, params: params, role: session[:role], unit_ids: session[:unit_ids] }
  end

  def auth_user
    unless user_signed_in?
      $baseURL = request.fullpath
      redirect_post(user_saml_omniauth_authorize_path, options: {authenticity_token: :auto})
    end
  end


  def after_sign_in_path_for(resource)
    if $baseURL.present?
      $baseURL
    elsif is_admin?
      programs_path
    elsif is_manager?
      welcome_pages_manager_path
    elsif is_student?
      welcome_pages_student_path
    else
      root_path
    end
  end

  def delete_file_attachment
    delete_file = ActiveStorage::Attachment.find(params[:id])
    delete_file.purge
    redirect_back(fallback_location: request.referer)
  end
  
  def redirect_back_or_default(notice = '', alert = false, default = all_root_url)
    if alert
      flash[:alert] = notice
    else
      flash[:notice] = notice
    end
    url = session[:return_to]
    session[:return_to] = nil
    redirect_to(url, anchor: "top" || default)
  end

  def get_manager_name(uniqname, program)
    result = {'valid' => false, 'note' => '', 'last_name' => '', 'first_name' => ''}
    valid = LdapLookup.uid_exist?(uniqname)
    if valid
      if program.instructor.uniqname == uniqname
        result['note'] = "#{uniqname} is instructor's uniqname"
      else
        # check if uniqname is an admin uniqname
        ldap_group = is_member_of_admin_groups?(uniqname)
        if ldap_group
          result['valid'] = false
          result['note'] = "#{uniqname} is an admin - a member of #{ldap_group} group. Admins can't be managers."
          return result
        end
        name = LdapLookup.get_simple_name(uniqname)
        result['valid'] =  true
        if name.include?("No displayname")
          result['note'] = " Mcommunity returns no name for '#{uniqname}' uniqname. Please go to Programs->Managers and add first and last names manually."
        else
          result['first_name'] = name.split(" ").first
          result['last_name'] = name.split(" ").last
        end
      end
    else
      result['note'] = "The '#{uniqname}' uniqname is not valid."
    end
    return result
  end

  def is_member_of_admin_groups?(uniqname)
    access_groups = Unit.pluck(:ldap_group) + ['lsa-was-rails-devs']
    ldap_group = false
    access_groups.each do |group|
      if LdapLookup.is_member_of_group?(uniqname, group)
        ldap_group = group
      end
    end
    return ldap_group
  end

  def get_faculty_name_for_survey(uniqname)
    result = {'valid' => false, 'note' => '', 'last_name' => '', 'first_name' => ''}
    valid = LdapLookup.uid_exist?(uniqname)
    if valid
      # check if uniqname is an admin uniqname
      ldap_group = is_member_of_admin_groups?(uniqname)
      if ldap_group
        result['valid'] = false
        result['note'] = "#{uniqname} is an admin - a member of #{ldap_group} group. Admins can't be instructors."
        return result
      end
      name = LdapLookup.get_simple_name(uniqname)
      result['valid'] =  true
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
