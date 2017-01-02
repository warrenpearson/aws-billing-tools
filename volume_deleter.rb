#!/usr/bin/env ruby

require 'aws-sdk'

# Delete an instance and its attached volumes
# Convenience script for when mass deletes are
# required.
class VolumeDeleter
  def initialize
    @ec2 = Aws::EC2::Client.new(
      region: 'us-east-1'
    )
  end

  def delete(volume)
    @ec2.delete_volume(volume_id: volume)
    puts "Deleting #{volume}"
  rescue => err
    puts err
  end
end

volume = ARGV[0]
unless volume
  puts "Usage: #{__FILE__} <volume_id>"
  exit
end

VolumeDeleter.new.delete(volume)
