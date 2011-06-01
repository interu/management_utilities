#!/usr/bin/env ruby

require 'rubygems'
require 'right_aws'
require 'active_support/time' ## activesupport v3
require 'pit'

class ManageSnapshot
  @@pit = Pit.get('s3', :require => { 'access_key' => '', 'secret_key' => '', 'volume_id' => '', 'owner_id' => '', 'region' => '', 'app_title' => ''})

  attr_accessor :access_key, :secret_key, :volume_id, :owner_id, :region, :description, :long_period, :short_period

  def self.run
    self.new.run
  end

  def initialize(opt = {})
    @access_key  = opt[:access_key] || @@pit['access_key']
    @secret_key  = opt[:secret_key] || @@pit['secret_key']
    @volume_id   = opt[:volume_id] || @@pit['volume_id']
    @owner_id    = opt[:owner_id] || @@pit['owner_id']
    @region      = opt[:region] || @@pit['region']
    @description = opt[:description] || @@pit['app_title']
    @long_period = opt[:long_period] || 12.hour
    @short_period = opt[:short_period] || 2.hour
  end

  def ec2
    @ec2 ||= RightAws::Ec2.new(access_key, secret_key, {:region => region})
  end

  def run
    create_snapshot
    check_status_snapshot
    delete_snapshot
  end

  def create_snapshot
    ec2.create_snapshot(volume_id, description)
  end

  def check_status_snapshot(snapshots = select_owners_and_same_description_snapshots)
    result = snapshots.select{ |ss| ss[:aws_status] == "pending" }
    raise "pending status count : #{result.count}" if result.count >= 2
  end

  def delete_snapshot(snapshots = select_snapshot_to_delete)
    snapshots.each do |snapshot|
      ec2.delete_snapshot(snapshot[:aws_id])
    end
  end

  def select_snapshot_to_delete(snapshots = select_owners_and_same_description_snapshots)
    target = []
    target << snapshots.select { |ss| Time.parse(ss[:aws_started_at]) <= long_period.ago }
    target << snapshots.select { |ss| short_period.ago > Time.parse(ss[:aws_started_at]) and Time.parse(ss[:aws_started_at]) >= long_period.ago and 10 < Time.parse(ss[:aws_started_at]).min }
    target.flatten
  end

  def select_owners_and_same_description_snapshots
    ec2.describe_snapshots.select{ |snapshot| snapshot[:aws_owner] == owner_id and snapshot[:aws_description] == description }
  end
end

if __FILE__ == $0
  begin
    ManageSnapshot.run
  rescue Exception => e
    require "mail"
    require 'i18n'

    pit_gmail = Pit.get('gmail', :require => { 'to' => '', 'from' => '', 'password' => ''})

    Mail.defaults do
      delivery_method :smtp, {
        :address              => "smtp.gmail.com",
        :port                 => 587,
        :domain               => 'smtp.gmail.com',
        :user_name            => pit_gmail['from'],
        :password             => pit_gmail['password'],
        :authentication       => 'plain',
        :enable_starttls_auto => true
      }
      # For test mail
      # delivery_method :test
    end

    Mail.deliver do |mail|
      to pit_gmail['to']
      from pit_gmail['from']
      subject "[#{description}] Manage Snapshot Error"
      body <<-EOF
Manage Snapshot Error

Error:
#{e}

Backtrace:
#{e.backtrace.join('
')}
EOF
    end
  end
end
