class StaticPagesController < ApplicationController
  def home
    authorize :page
    if user_signed_in?
      if is_student?
        redirect_to welcome_pages_student_path
      end
    end
  end
end
