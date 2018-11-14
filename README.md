# Installation
apt install ruby ruby-dev

bundle install --path ./

# Registration
bundle exec whenever -i system


# Test
cd aws/
bundle exec rspec manage_snapshot_spec.rb
