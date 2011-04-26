require 'rubygems'
require 'right_aws'
require "active_support/time"
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
    delete_snapshot
  rescue => e
    puts "--------- Error ---------"
    puts e
  end

  def create_snapshot
    ec2.create_snapshot(volume_id, description)
  end

  def delete_snapshot(snapshots = select_snapshot_to_delete)
    snapshots.each do |snapshot|
      ec2.delete_snapshot(snapshot[:aws_id])
    end
  end

  def select_snapshot_to_delete(snapshots = select_owners_and_same_description_snapshots)
    snapshots.
      select { |ss| ss[:aws_started_at] >= long_period.ago }.
      select { |ss| short_period.ago < ss[:aws_started_at] and ss[:aws_started_at] <= long_period.ago and 10 < ss[:aws_started_at].min }
  end

  def select_owners_and_same_description_snapshots
    ec2.describe_snapshots.select{ |snapshot| snapshot[:aws_owner] == owner_id and snapshot[:aws_description] == description }
  end
end
