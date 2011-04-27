require "rubygems"
require "spec"
require "active_support"
require "./manage_snapshot"

describe ManageSnapshot, "#create_snapshot" do
  it "should create snapshot" do
    runner = ManageSnapshot.new(:volume_id => "volume1", :description => "volume1 desc")
    ec2 = mock(:ec2)
    ec2.should_receive(:create_snapshot).with("volume1", "volume1 desc")
    runner.stub(:ec2).and_return(ec2)
    runner.create_snapshot
  end
end

describe ManageSnapshot, "#check_status_snapshot" do
  before do
    @runner = ManageSnapshot.new
  end

  it "should not select 2 snapshots that status is pending" do
    @snapshots = [{ :aws_status => "pending" }, { :aws_status => "completed" }]
    proc{ @runner.check_status_snapshot(@snapshots) }.should_not raise_error
  end

  it "should select 2 snapshots that status is pending" do
    @snapshots = [{ :aws_status => "pending" }, { :aws_status => "pending" }]
    proc{ @runner.check_status_snapshot(@snapshots) }.should raise_error
  end
end

describe ManageSnapshot, "#delete_snapshot" do
  it "should delete selected volume" do
    runner = ManageSnapshot.new
    ec2 = mock(:ec2)
    ec2.should_receive(:delete_snapshot).with("target_snapshot_aws_id")
    runner.stub(:ec2).and_return(ec2)

    runner.delete_snapshot([{ :aws_id => "target_snapshot_aws_id" }])
  end
end

describe ManageSnapshot, "#select_snapshot_to_delete" do
  before do
    @runner = ManageSnapshot.new
    @snapshots = []
  end

  subject { @runner.select_snapshot_to_delete(@snapshots) }

  it "should not select recent 2hour volume" do
    @new_snapshot = { :aws_started_at => 1.hour.ago }
    @snapshots << @new_snapshot
    should_not include(@new_snapshot)
  end
  it "should not select every hour volume that is since 12hour" do
    @hourly_snapshot = { :aws_started_at => 6.hour.ago.change(:min => 4) }
    @snapshots << @hourly_snapshot
    should_not include(@hourly_snapshot)
  end
  it "should select volume that is older than 12hour" do
    @old_snapshot = { :aws_started_at => 15.hour.ago }
    @snapshots << @old_snapshot
    should include(@old_snapshot)
  end

  it "should select volume that is not every hour and since 12hour" do
    @not_hourly_snapshot = { :aws_started_at => 6.hour.ago.change(:min => 15) }
    @snapshots << @not_hourly_snapshot
    should include(@not_hourly_snapshot)
  end
end

describe ManageSnapshot, "#select_owners_and_same_description_snapshots" do
  before do
    @runner = ManageSnapshot.new(:owner_id => "target_owner_id", :description => "target_description")

    ec2 = mock(:ec2)
    @not_select_snapshot = { :aws_owner => "not_owner_id", :aws_description => "target_description" }
    @select_snapshot = { :aws_owner => "target_owner_id", :aws_description => "target_description" }
    snapshots = [@not_select_snapshot, @select_snapshot]
    ec2.stub(:describe_snapshots).and_return(snapshots)

    @runner.stub(:ec2).and_return(ec2)
  end
  subject { @runner.select_owners_and_same_description_snapshots }
  it "should not select different owner's snapshot" do
    should_not include(@not_select_snapshot)
  end
  it "should not select different description snapshot" do
    should_not include(@not_select_snapshot)
  end
  it "should select same owner and description snapshot" do
    should include(@select_snapshot)
  end
end
