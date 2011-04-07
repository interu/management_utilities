# gem install backup
# execute : # backup perform -t system --config_file '/root/scripts/backup/collect_system_logs.rb'
# Set backup schedule 06:00am
#     logrotate.d/syslog daily

require 'pit'

timestamp = Date.today.strftime('%Y%m%d')
pit_s3 = Pit.get('s3', :require => { 'access_key' => '', 'secret_key' => '', 'region' => '', 'bucket' => ''})
pit_gmail = Pit.get('gmail', :require => { 'to' => '', 'from' => '', 'password' => ''})

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
    s3.access_key_id      = pit_s3['access_key']
    s3.secret_access_key  = pit_s3['secret_key']
    s3.region             = pit_s3['region']
    s3.bucket             = pit_s3['bucket']
    s3.path               = '/backups'
    s3.keep               = 365
  end

  notify_by Mail do |mail|
    mail.on_success           = false
    mail.on_failure           = true

    mail.from                 = pit_gmail['from']
    mail.to                   = pit_gmail['to']
    mail.address              = 'smtp.gmail.com'
    mail.port                 = 587
    mail.domain               = 'smtp.gmail.com'
    mail.user_name            = pit_gmail['from']
    mail.password             = pit_gmail['password']
    mail.authentication       = 'plain'
    mail.enable_starttls_auto = true
  end
end
