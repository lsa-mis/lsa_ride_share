class NotePolicy < ApplicationPolicy
  
  def index?
    user_in_access_group?
  end

  def show?
    user_in_access_group?
  end

  def create?
    user_in_access_group?
  end

  def new?
    create?
  end

  def update?
    user_in_access_group?
  end

  def edit?
    update?
  end

  def destroy?
    user_in_access_group?
  end

end
