##
# Backup v5.x Configuration
#
## execute : # backup perform -t system --config_file '/root/scripts/backup/collect_system_logs.rb'
# Set backup schedule 06:00am
#     logrotate.d/syslog daily

timestamp = Date.today.strftime('%Y%m%d')
config = YAML.load(File.read('~/.config.yml'))

Storage::S3.defaults do |s3|
  s3.use_iam_profile = true
end

mail_setting = config['mail']
Notifier::Mail.defaults do |mail|
  mail.from                 = mail_setting['user_name']
  mail.to                   = mail_setting['to']
  mail.address              = mail_setting['address']
  mail.port                 = mail_setting['port']
  mail.domain               = mail_setting['address']
  mail.user_name            = mail_setting['user_name']
  mail.password             = mail_setting['password']
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
    s3.region             = config['aws']['region']
    s3.bucket             = config['s3']['bucket']
    s3.path               = '/backups'
    # s3.keep               = 365 * 5
  end

  notify_by Mail do |mail|
    mail.on_success           = false
    mail.on_warning           = false
    mail.on_failure           = true
  end
end
