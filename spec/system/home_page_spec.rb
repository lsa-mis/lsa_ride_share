require 'rails_helper'

RSpec.describe 'Home page', type: :system do
  describe 'home page' do
    it 'shows the right content' do
      visit all_root_path
      expect(page).to have_content('About LSA RideShare application.')
    end
  end
end
