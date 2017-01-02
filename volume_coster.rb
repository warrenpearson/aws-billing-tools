#!/usr/bin/env ruby

require 'aws-sdk'
require 'csv'

# Get costs for each volume.
class VolumeCoster
  def list(input_file)
    ec2 = Aws::EC2::Client.new(
      region: 'us-east-1'
    )

    response = ec2.describe_volumes
    vols = response.volumes
    total = 0
    vols.each do |v|
      total += vol_info(v, input_file)
    end

    puts "Total: #{total.round(2)}"
  end

  def vol_info(v, input_file)
    txt = "#{v.volume_id},#{v.size},#{v.availability_zone},#{v.state},"
    vol_total = get_total_for_resource(v.volume_id, input_file)
    txt += vol_total.to_s
    puts txt
    vol_total
  end

  def get_total_for_resource(resource, input_file)
    rows = `grep #{resource} #{input_file}`.split("\n")
    total = 0.00

    rows.each do |r|
      CSV.parse(r) do |row|
        total += row[-3].to_f
      end
    end

    # puts "Total monthly cost for #{resource}, $#{total.round(2)}"
    total.round(2)
  end
end

VolumeCoster.new.list(ARGV[0])
