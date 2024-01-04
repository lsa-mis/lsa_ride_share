require 'rails_helper'

RSpec.describe 'Shibboleth login', type: :system do
  it 'login success' do
    visit all_root_path
    click_on "Sign In"
    expect(page).to have_content('About LSA RideShare application.')
  end
end
