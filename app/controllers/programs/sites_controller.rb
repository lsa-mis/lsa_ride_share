class Programs::SitesController < SitesController
  before_action :set_site_program

  private

  def set_site_program
      @site_program = Program.find(params[:program_id])
  end

end