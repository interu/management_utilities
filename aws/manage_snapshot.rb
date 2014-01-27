#!/usr/bin/env ruby
#-*- encoding : utf-8 -*-

require 'rubygems'
require 'aws-sdk'
require 'active_support/time' ## activesupport v3
require 'constellation'

class MyConfiguration
  Constellation.enhance self
  self.config_file = "~/.config.yml"
end

class ManageSnapshot
  attr_accessor :access_key, :secret_key, :volume_id, :owner_id, :region, :description, :long_period, :short_period

  def self.run
    self.new.run
  end

  def initialize(opt = {})
    config = MyConfiguration.new
    @access_key  = opt[:access_key]    || config.aws['access_key']
    @secret_key  = opt[:secret_key]    || config.aws['secret_key']
    @owner_id    = opt[:owner_id].try(:to_s) || config.aws['owner_id'].to_s
    @region      = opt[:region]        || config.aws['region']
    @volume_id   = opt[:volume_id]     || config.ebs['volume_id']
    @description = opt[:description]   || config.ebs['description']
    @long_period = opt[:long_period]   || 12.hour
    @short_period = opt[:short_period] || 2.hour
  end

  def ec2
    @ec2 ||= AWS::EC2.new(access_key_id: access_key, secret_access_key: secret_key, region: region)
  end

  def run
    create_snapshot
    check_status_snapshot
    delete_snapshot
  end

  def create_snapshot
    puts '[INFO] Create snapshot.'
    ec2.volumes[volume_id].create_snapshot(description)
  end

  def check_status_snapshot(snapshots = select_owners_and_same_description_snapshots)
    puts '[INFO] Check status snapshot.'
    result = snapshots.select{ |ss| ss.status == "pending" }
    raise "pending status count : #{result.count}" if result.count >= 2
  end

  def delete_snapshot(snapshots = select_snapshot_to_delete)
    puts '[INFO] Delete snapshots ...'
    snapshots.each do |snapshot|
      snapshot.delete
    end
  end

  def select_snapshot_to_delete(snapshots = select_owners_and_same_description_snapshots)
    puts '[INFO] Select snapshots to delete.'
    target = []
    puts '[INFO] First narrowing-down.'
    target << snapshots.select { |ss| Time.parse(ss.start_time) <= long_period.ago }
    puts '[INFO] Second narrowing-down.'
    target << snapshots.select { |ss| short_period.ago > Time.parse(ss.start_time) && Time.parse(ss.start_time) >= long_period.ago && 10 < Time.parse(ss.start_time).min }
    target.flatten
  end

  def select_owners_and_same_description_snapshots
    puts '[INFO] Select owners and same description snapshots.'
    ec2.snapshots.with_owner(owner_id).select{ |snapshot| snapshot.description == description }
  end
end

if __FILE__ == $0
  config = MyConfiguration.new
  begin
    ManageSnapshot.run
  rescue Exception => e
    puts "[ERROR] Detail:\n #{e.inspect}"
    require "mail"
    require 'i18n'

    Mail.defaults do
      delivery_method :smtp, {
        :address              => "smtp.gmail.com",
        :port                 => 587,
        :domain               => 'smtp.gmail.com',
        :user_name            => config.gmail['from'],
        :password             => config.gmail['password'],
        :authentication       => 'plain',
        :enable_starttls_auto => true
      }
      # For test mail
      # delivery_method :test
    end

    Mail.deliver do |mail|
      to config.gmail['to']
      from config.gmail['from']
      subject "[#{config.app_name}] Create Snapshot Error"
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
