class ApplicationMailer < ActionMailer::Base
  include MailerDolistConcern
  include MailerHeadersConfigurableConcern
  include MailerMonitoringConcern
  include BalancedDeliveryConcern
  include PriorityDeliveryConcern

  helper :application # gives access to all helpers defined within `application_helper`.
  default from: "#{APPLICATION_NAME} <#{CONTACT_EMAIL}>"
  layout 'mailer'

  before_action -> { Sentry.set_tags(mailer: mailer_name, action: action_name) }
end
