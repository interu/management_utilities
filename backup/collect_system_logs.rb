# gem install backup
# execute : # backup perform -t system --config_file '/root/scripts/backup/collect_system_logs.rb'
# Set backup schedule 06:00am
#     logrotate.d/syslog daily

require 'pit'

pit = Pit.get('s3_info', :require => { 'access_key' => '', 'secret_key' => '', 'region' => '', 'bucket' => ''})
timestamp = Date.today.strftime('%Y%m%d')

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
    s3.access_key_id      = pit['access_key']
    s3.secret_access_key  = pit['secret_key']
    s3.region             = pit['region']
    s3.bucket             = pit['bucket']
    s3.path               = '/backups'
    s3.keep               = 365
  end
end
