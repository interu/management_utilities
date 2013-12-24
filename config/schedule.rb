# -*- encoding : utf-8 -*-
# Use thchedule.rbs file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Learn more: http://github.com/javan/whenever
set :job_template, nil
set :path, "/root/management_utilities"
set :output, "/tmp/batch.log"
job_type :rake, "cd :path && bundle exec rake :task :output"
job_type :command, "cd :path && bundle exec :task :output"
job_type :runner,  "cd :path && script/runner -e :environment ':task' :output"

## システムログをS3に退避
every 1.day, at: '6:00 am' do
  command "backup perform -t system --config_file '/root/management_utilities/backup/collect_system_logs.rb'"
end

## EBSボリュームのsnapshot定期取得
every :hour do
  command "ruby aws/manage_snapshot.rb"
end

## EBSブートインスタンスAMI定期取得
every '11 1 2 1,4,7,10 *' do
  command "ruby /root/management_utilities/aws/create_ebsboot_ami.rb"
end
