require 'rails_helper'

RSpec.describe "Controllers", type: :request do

  describe 'login success' do
    it 'displays welcome message on programs page' do
      user = FactoryBot.create(:user)
      mock_login(user)
      follow_redirect!
      expect(response.body).to include("Welcome")
    end
  end

  describe 'login failure' do
    it 'displays welcome message on programs page' do
      user = FactoryBot.build(:user, email: "kielbasa")
      mock_login(user)
      expect(response.body).not_to include("Welcome")
    end
  end

end
