class PagePolicy < ApplicationPolicy

  def home?
    true
  end

  def docs?
    true
  end

end
