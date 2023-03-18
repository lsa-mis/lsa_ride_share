class ApplicationController < ActionController::Base
  before_action :set_membership
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_in_group

  def user_not_in_group
    flash[:alert] = "You are not authorized to perform this action."
    sign_out(current_user)
    redirect_to root_path
  end

  def user_not_authorized
    flash[:alert] = "Please sign in to perform this action."
    redirect_to(request.referrer || root_path)
  end

  def set_membership
    if user_signed_in?
      current_user.membership = session[:user_memberships]
      access_groups = ['lsa-rideshare-admins']
      unless current_user.membership && (current_user.membership & access_groups).any?
        flash[:alert] = "You are not authorized to perform this action."
        sign_out(current_user)
        redirect_to root_path
      end
    else
      new_user_session_path
    end
  end

end
