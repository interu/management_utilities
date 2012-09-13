#!/usr/bin/env ruby

require 'rubygems'
require 'right_aws'
require 'active_support/time' ## activesupport v3
require 'pit'

class CreateAmi
  @@pit = Pit.get('s3', :require => { 'access_key' => '', 'secret_key' => '', 'instance_id' => '', 'region' => '', 'regist_key' => ''})

  attr_accessor :access_key, :secret_key, :instance_id, :region, :regist_key

  def self.run
    self.new.run
  end

  def initialize(opt = {})
    @access_key  = opt[:access_key] || @@pit['access_key']
    @secret_key  = opt[:secret_key] || @@pit['secret_key']
    @instance_id = opt[:instance_id] || @@pit['instance_id']
    @region      = opt[:region] || @@pit['region']
    @regist_key  = opt[:regist_key] || @@pit['regist_key']
  end

  def ec2
    @ec2 ||= RightAws::Ec2.new(access_key, secret_key, {:region => region})
  end

  def run
    create_ami
  end

  def create_ami
    if valid_instance?
      ec2.crate_image(instance_id, {:name => registing_name, :no_reboot => true})
    else
      puts "[Error] Instance ID was different."
    end
  end

  def registing_name
    "#{Time.now.strftime("%Y%m%d_%H%M")}_#{regist_key}"
  end

  def valid_instance?
    metadata = `curl -s http://169.254.169.254/latest/meta-data/instance-id`
    matadata == instance_id
  end
end

if __FILE__ == $0
  begin
    CreateAmi.run
  rescue Exception => e
    require "mail"
    require 'i18n'

    pit_gmail = Pit.get('gmail', :require => { 'to' => '', 'from' => '', 'password' => ''})
    pit_s3 = Pit.get('s3', :require => { 'app_title' => ''})

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
      subject "[#{pit_s3['app_title']}] Manage Snapshot Error"
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
