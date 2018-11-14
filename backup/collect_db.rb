##
# Backup v5.x Configuration
#
# execute : # backup perform -t db --config_file '/root/scripts/backup/collect_db.rb'
# Set backup schedule 02:00am
#     logrotate.d/syslog daily

require 'constellation'

class MyConfiguration
  Constellation.enhance self
  self.config_file = "~/.config.yml"
end

timestamp = Date.today.strftime('%Y%m%d')
config = MyConfiguration.new

Storage::S3.defaults do |s3|
  s3.access_key_id      = config.aws['access_key']
  s3.secret_access_key  = config.aws['secret_key']
end

Notifier::Mail.defaults do |mail|
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

Compressor::Gzip.defaults do |compression|
  compression.level = 6
end

Backup::Model.new(:db, 'database buckup') do

  database MySQL do |database|
    database.name               = config.mysql['database']
    database.username           = config.mysql['username']
    database.password           = config.mysql['password']
    database.host               = config.mysql['host']
    database.additional_options = ['--single-transaction', '--quick']
  end

  compress_with Gzip

  store_with S3 do |s3|
    s3.region             = config.aws['region']
    s3.bucket             = config.s3['bucket']
    s3.path               = '/backups'
    s3.keep               = 20
  end

  notify_by Mail do |mail|
    mail.on_success           = false
    mail.on_warning           = false
    mail.on_failure           = true
  end
end
