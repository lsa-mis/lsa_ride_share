require 'rails_helper'

RSpec.describe 'Shibboleth login', type: :system do
  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:saml] = {:provider => 'saml', :uid => '123545'}
    # request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:saml] 
  end


  it 'login success' do
    visit programs_path
    # click_on "Sign In"
    binding.pry
    expect(page).to have_content('Welcome')
  end
end
