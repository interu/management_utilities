# gem install backup
# execute : # backup perform -t system --config_file '/root/scripts/backup/collect_system_logs.rb'
# Set backup schedule 06:00am
#     logrotate.d/syslog daily

require 'constellation'

class MyConfiguration
  Constellation.enhance self
  self.config_file = "~/.config.yml"
end

timestamp = Date.today.strftime('%Y%m%d')
config = MyConfiguration.new

Backup::Model.new(:system, 'system log buckup') do
  archive :logs do |archive|
    archive.add '/var/log/messages'
    archive.add "/var/log/messages-#{timestamp}.gz"
    archive.add '/var/log/secure'
    archive.add "/var/log/secure-#{timestamp}.gz"
    archive.add '/var/log/maillog'
    archive.add "/var/log/maillog-#{timestamp}.gz"
    archive.add '/var/log/boot.log'
    archive.add "/var/log/boot-#{timestamp}.gz"
    #monthly or weekly
    archive.add '/var/log/dmesg'
    archive.add '/var/log/wtmp'
    archive.add '/var/log/lastlog'
  end

  compress_with Gzip do |compression|
    compression.best = true
  end

  store_with S3 do |s3|
    s3.access_key_id      = config.aws['access_key']
    s3.secret_access_key  = config.aws['secret_key']
    s3.region             = config.aws['region']
    s3.bucket             = config.s3['bucket']
    s3.path               = '/backups'
    s3.keep               = 365
  end

  notify_by Mail do |mail|
    mail.on_success           = false
    mail.on_warning           = false
    mail.on_failure           = true

    mail.from                 = config.gmail['from']
    mail.to                   = config.gmail['to']
    mail.address              = 'smtp.gmail.com'
    mail.port                 = 587
    mail.domain               = 'smtp.gmail.com'
    mail.user_name            = config.gmail['from']
    mail.password             = config.gmail['password']
    mail.authentication       = 'plain'
    mail.enable_starttls_auto = true
  end
end
