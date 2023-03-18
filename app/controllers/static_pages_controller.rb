class StaticPagesController < ApplicationController
  def home
    authorize :page
  end
end
