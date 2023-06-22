class ApplicationMailer < ActionMailer::Base
  include ApplicationHelper
  prepend_view_path "app/views/mailers"
  default from: "lsa-rideshare-admins@umich.edu"
  default to: "lsa-rideshare-admins@umich.edu"
  default subject: "Mail from the LSA Rideshare App"
  layout "mailer"
end
