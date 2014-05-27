# Installation
bundle install --path ./

# Registration
bundle exec whenever -i system

# Test
cd aws/
bundle exec rspec manage_snapshot_spec.rb

# backup config test
bundle exec backup check -c backup/collect_system_logs.rb
