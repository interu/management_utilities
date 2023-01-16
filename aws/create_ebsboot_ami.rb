#!/usr/bin/env ruby

require 'rubygems'
require 'aws-sdk'
require 'yaml'

class CreateAmi
  attr_accessor :instance_id, :region, :regist_key

  def self.run
    self.new.run
  end

  def initialize(opt = {})
    config = YAML.load(File.read('~/.config.yml'))
    @region      = opt[:region]        || config['aws']['region']
    @instance_id = opt[:instance_id]   || config['ami']['instance_id']
    @regist_key  = opt[:regist_key]    || config['ami']['regist_key']
  end

  def ec2
    @ec2 ||= Aws::EC2::Client.new(region: region, credentials: Aws::InstanceProfileCredentials.new)
  end

  def run
    create_ami
  end

  def create_ami
    puts "[OK] Start registing #{registing_name} ..."
    ec2.create_image(instance_id: get_instance_id, name: registing_name, description: registing_name, no_reboot: true)
  end

  def registing_name
    "#{Time.now.strftime("%Y%m%d_%H%M")}_#{regist_key}"
  end

  def get_instance_id
    `curl -s http://169.254.169.254/latest/meta-data/instance-id`
  end
end

if __FILE__ == $0
  begin
    CreateAmi.run
  rescue Exception => e
    puts "[ERROR] Detail:\n #{e.inspect}"
    require "mail"
    config = YAML.load(File.read('~/.config.yml'))

    Mail.defaults do
      delivery_method :smtp, {
        :address => config['mail']['address'],
        :port => config['mail']['port'],
        :domain => config['mail']['address'],
        :user_name => config['mail']['user_name'],
        :password => config['mail']['password'],
        :authentication => 'plain',
        :encryption => :starttls
      }
      # For test mail
      # delivery_method :test
    end

    Mail.deliver do |mail|
      to config['mail']['to']
      from config['mail']['from']
      subject "[#{config['app_name']}] Manage Snapshot Error"
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
