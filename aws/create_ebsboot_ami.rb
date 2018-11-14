#!/usr/bin/env ruby

require 'rubygems'
require 'aws'
require 'active_support/time'
require 'constellation'

class MyConfiguration
  Constellation.enhance self
  self.config_file = "~/.config.yml"
end

class CreateAmi
  attr_accessor :access_key, :secret_key, :instance_id, :region, :regist_key

  def self.run
    self.new.run
  end

  def initialize(opt = {})
    config = MyConfiguration.new
    @access_key  = opt[:access_key]    || config.aws['access_key']
    @secret_key  = opt[:secret_key]    || config.aws['secret_key']
    @region      = opt[:region]        || config.aws['region']
    @instance_id = opt[:instance_id]   || config.ami['instance_id']
    @regist_key  = opt[:regist_key]    || config.ami['regist_key']
  end

  def ec2
    @ec2 ||= AWS::EC2::Client.new(access_key_id: access_key, secret_access_key: secret_key, region: region)
  end

  def run
    create_ami
  end

  def create_ami
    if valid_instance?
      puts "[OK] Start registing #{registing_name} ..."
      ec2.instances[instance_id].create_image(registing_name, { description: registing_name, no_reboot: true })
    else
      puts "[Error] Instance ID was different."
    end
  end

  def registing_name
    "#{Time.now.strftime("%Y%m%d_%H%M")}_#{regist_key}"
  end

  def valid_instance?
    metadata = `curl -s http://169.254.169.254/latest/meta-data/instance-id`
    metadata == instance_id
  end
end

if __FILE__ == $0
  config = MyConfiguration.new
  begin
    CreateAmi.run
  rescue Exception => e
    puts "[ERROR] Detail:\n #{e.inspect}"
    require "mail"

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
      subject "[#{config.app_name}] Manage Snapshot Error"
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
