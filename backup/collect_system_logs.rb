# encoding: utf-8

##
# Backup v4.x Configuration
#
# Documentation: http://meskyanichi.github.io/backup
# Issue Tracker: https://github.com/meskyanichi/backup/issues

require 'constellation'

class MyConfiguration
  Constellation.enhance self
  self.config_file = "~/.config.yml"
end

timestamp = Date.today.strftime('%Y%m%d')
config = MyConfiguration.new

Backup::Model.new(:system, 'system log buckup') do

  split_into_chunks_of 4000

  archive :logs do |archive|
    archive.add '/var/log/syslog'
    archive.add "/var/log/syslog-#{timestamp}"
    archive.add '/var/log/auth.log'
    archive.add "/var/log/auth.log-#{timestamp}"
    archive.add '/var/log/mail.log'
    archive.add "/var/log/mail.log-#{timestamp}"
    archive.add '/var/log/ufw.log'
    archive.add "/var/log/ufw.log-#{timestamp}"
    #monthly or weekly
    archive.add '/var/log/wtmp'
    archive.add '/var/log/lastlog'
  end

  compress_with Gzip do |compression|
    compression.level = 6
  end

  store_with S3 do |s3|
    s3.access_key_id      = config.aws['access_key']
    s3.secret_access_key  = config.aws['secret_key']
    s3.region             = config.aws['region']
    s3.bucket             = config.s3['bucket']
    s3.path               = '/backups'
    s3.keep               = 365 * 5
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
    mail.encryption           = :starttls
  end
end
