##
# Backup v5.x Configuration
#
## execute : # backup perform -t system --config_file '/root/scripts/backup/collect_system_logs.rb'
# Set backup schedule 06:00am
#     logrotate.d/syslog daily

require 'constellation'

class MyConfiguration
  Constellation.enhance self
  self.config_file = "~/.config.yml"
end

timestamp = Date.today.strftime('%Y%m%d')
config = MyConfiguration.new

Storage::S3.defaults do |s3|
  s3.use_iam_profile = true
end

Notifier::Mail.defaults do |mail|
  mail.from                 = config.mail['user_name']
  mail.to                   = config.mail['to']
  mail.address              = config.mail['address']
  mail.port                 = config.mail['port']
  mail.domain               = config.mail['address']
  mail.user_name            = config.gmail['user_nam3']
  mail.password             = config.gmail['password']
  mail.authentication       = 'plain'
  mail.encryption           = :starttls
end

Compressor::Gzip.defaults do |compression|
  compression.level = 6
end

Backup::Model.new(:system, 'system log buckup') do
  archive :logs do |archive|
    archive.add '/var/log/auth.log'
    archive.add "/var/log/auth.log.1"
    archive.add '/var/log/kern.log'
    archive.add "/var/log/kern.log.1"
    archive.add '/var/log/syslog.log'
    archive.add "/var/log/syslog.log.1"
    # archive.add '/var/log/apache2/access.log'
    # archive.add '/var/log/apache2/access.log.1'
    # archive.add '/var/log/apache2/error.log'
    # archive.add '/var/log/apache2/error.log.1'
    # archive.add '/var/log/apache2/other_vhosts_access.log'
    # archive.add '/var/log/apache2/other_vhosts_access.log.1'

    #monthly or weekly
    archive.add '/var/log/wtmp'
    archive.add '/var/log/lastlog'
  end

  compress_with Gzip

  store_with S3 do |s3|
    s3.region             = config.aws['region']
    s3.bucket             = config.s3['bucket']
    s3.path               = '/backups'
    # s3.keep               = 365 * 5
  end

  notify_by Mail do |mail|
    mail.on_success           = false
    mail.on_warning           = false
    mail.on_failure           = true
  end
end
