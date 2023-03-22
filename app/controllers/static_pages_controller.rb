class StaticPagesController < ApplicationController
  def home
    authorize :page
    if current_user
      redirect_to programs_path if current_user.membership.include?('lsa-rideshare-admins')
    end
  end
end
