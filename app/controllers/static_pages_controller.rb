class StaticPagesController < ApplicationController
  def home
    authorize :page
    if user_signed_in?
      if is_student?(current_user)
        redirect_to welcome_pages_student_path
      end
    end
  end

  def docs
    authorize :page
    if user_signed_in?
      if is_student?(current_user)
        redirect_to welcome_pages_student_path
      end
    end
    
  end
end
