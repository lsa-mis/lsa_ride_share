require 'rails_helper'

RSpec.describe Program, type: :request do

	# with manager role
  # go to index action
  # expect 200
  context 'index action' do
    context 'with manager role who has a program' do
      let!(:user_manager) { FactoryBot.create(:user) }
      let!(:manager) { FactoryBot.create(:manager, uniqname: user_manager.uniqname) }
      let!(:program) { FactoryBot.create(:program, instructor: manager) }

      it 'returns 200' do
        allow(LdapLookup).to receive(:is_member_of_group?).with(anything, "lsa-was-rails-devs").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(user_manager.uniqname, anything).and_return(false)
        mock_login(user_manager)
        get programs_path
        # binding.pry
        puts response.body
        expect(response).to have_http_status(200)
      end
    end

    context 'with manager role who has no programs' do
      let!(:user_manager) { FactoryBot.create(:user) }
      let!(:manager) { FactoryBot.create(:manager, uniqname: user_manager.uniqname) }

      it 'returns 302' do
        allow(LdapLookup).to receive(:is_member_of_group?).with(anything, "lsa-was-rails-devs").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(user_manager.uniqname, anything).and_return(false)
        mock_login(user_manager)
        get programs_path
        # binding.pry
        expect(response).to have_http_status(302)
        expect(response.location).to include("/welcome_pages/manager")
        expect(flash[:alert]).to match("You are not authorized to perform this action.")
      end
    end

  end
end
