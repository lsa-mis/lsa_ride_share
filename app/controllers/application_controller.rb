class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include ApplicationHelper

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  before_action :set_unit_and_membership
  after_action :verify_authorized, unless: :devise_controller?
  skip_after_action :verify_authorized, only: [:delete_file_attachment]

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(root_path)
  end

  def auth_user
    unless user_signed_in?
      redirect_to root_path, notice: 'You must sign in first!'
    end
  end

  def set_unit_and_membership
    if user_signed_in?
      current_user.membership = session[:user_memberships]
      if is_super_admin?(current_user)
        current_user.unit_ids = Unit.all.pluck(:id)
      else
        current_user.unit_ids = Unit.where(ldap_group: session[:user_memberships]).pluck(:id)
      end
    else
      new_user_session_path
    end
  end

  def after_sign_in_path_for(resource)
    if session[:user_memberships].present?
      programs_path 
    else
      root_path
    end
  end

  def delete_file_attachment
    delete_file = ActiveStorage::Attachment.find(params[:id])
    delete_file.purge
    redirect_back(fallback_location: request.referer)
  end
  
  def redirect_back_or_default(notice = '', default = root_url)
    flash[:notice] = notice
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def get_manager_name(uniqname, program)
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
