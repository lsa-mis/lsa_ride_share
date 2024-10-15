class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :saml
  before_action :set_user
  attr_reader :user, :service

  def saml
    handle_auth "Saml"
  end

  private

  def handle_auth(kind)
    if user_signed_in?
      flash[:notice] = "Your #{kind} account was connected."
      redirect_to edit_user_registration_path
    else
      sign_in_and_redirect user, event: :authentication
      $baseURL = ''
      set_flash_message :notice, :success, kind: kind
    end
  end

  def user_is_stale?
    return unless user_signed_in?
    current_user.last_sign_in_at < 15.minutes.ago
  end
end

def auth
  request.env["omniauth.auth"]
end

def set_user
  if user_signed_in?
    @user = current_user
  elsif User.where(email: auth.info.email).any?
    @user = User.find_by(email: auth.info.email)
  else
    @user = create_user
  end

  if @user
    session[:user_email] = @user.email
    uniqname = @user.uniqname
    session[:user_memberships] = []
    access_groups = Unit.pluck(:ldap_group)
    access_groups.each do |group|
      if  LdapLookup.is_member_of_group?(uniqname, group)
        session[:user_memberships].append(group)
      end
    end
    session[:unit_ids] = []
    if LdapLookup.is_member_of_group?(uniqname, 'lsa-was-rails-devs')
      session[:unit_ids] = Unit.all.pluck(:id)
      session[:role] = 'super_admin'
      # for now:
      session[:user_memberships].append('lsa-was-rails-devs')
    else
      if session[:user_memberships].present?
        session[:role] = 'admin'
      elsif Manager.find_by(uniqname: uniqname).present?
        session[:role] = 'manager'
      elsif Student.find_by(uniqname: user.uniqname, program: Program.current_term).present?
        session[:role] = 'student'
      else
        session[:role] = 'none'
      end
      session[:unit_ids] = Unit.where(ldap_group: session[:user_memberships]).pluck(:id)
    end
    
  end
end

def get_uniqname(email)
  email.split("@").first
end

def create_user

  @user = User.create(
    email: auth.info.email,
    uniqname: get_uniqname(auth.info.email),
    uid: auth.info.uid,
    principal_name: auth.info.principal_name,
    display_name: auth.info.name,
    person_affiliation: auth.info.person_affiliation,
    password: Devise.friendly_token[0, 20]
  )

end