#-*- encoding : utf-8 -*-
targets = %w(instance-type instance-id ami-id public-ipv4)

targets.each do |target|
  system("/usr/bin/curl -s http://169.254.169.254/latest/meta-data/#{target}")
  puts "\n"
end
