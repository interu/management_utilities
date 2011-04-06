require 'rubygems'
require 'right_aws'
require 'pit'

pit = Pit.get('s3_info', :require => { 'access_key' => '', 'secret_key' => '', 'volume_id' => '', 'owner_id' => '', 'region' => '', 'app_title' => ''})

access_key  = pit['access_key']
secret_key  = pit['secret_key']
volume_id   = pit['volume_id']
owner_id    = pit['owner_id']
region      = pit['region']
description = pit['app_title']
generation  = 3


begin
  @ec2 = RightAws::Ec2.new(access_key, secret_key, {:region => region})

  ## Create Snapshot
  puts "--------- Create Snapshot ---------"
  @ec2.create_snapshot(volume_id, description)

  #puts "--------- Describe Snapshot ---------"
  all_snapshots = @ec2.describe_snapshots

  snapshots = all_snapshots.select{|snapshot| snapshot[:aws_owner] == owner_id and snapshot[:aws_description] == description}.sort{|x,y| x[:aws_started_at] <=> y[:aws_started_at]}

  target_snapshot = snapshots.size > generation ? snapshots.first : nil
  puts "--------- Delete Snapshot ---------"
  puts target_snapshot.inspect

  # Delete Old Snapshot
  unless target_snapshot.empty?
    @ec2.delete_snapshot(target_snapshot[:aws_id])
  end

rescue
end

