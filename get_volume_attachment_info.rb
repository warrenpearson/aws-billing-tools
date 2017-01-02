#!/usr/bin/env ruby

require 'aws-sdk'

# Get high-level information about a volume
class GetVolumeAttachmentInfo
  def get_info(volume_id)
    ec2 = Aws::EC2::Client.new(region: 'us-east-1')

    response = ec2.describe_volumes(volume_ids: [volume_id])
    vols = response.volumes
    print_info(vols[0])
  end

  def print_info(v)
    txt = "#{v.volume_id},#{v.size},#{v.availability_zone},#{v.state}"
    puts txt
    txt  = "instance_id: #{v.attachments[0].instance_id}, "
    txt += "device: #{v.attachments[0].device}"
    puts txt
  end
end

GetVolumeAttachmentInfo.new.get_info(ARGV[0])
