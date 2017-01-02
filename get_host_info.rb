require 'json'
require_relative 'host_info_getter'

class GetHostInfo
  def write_output
    instance_array = HostInfoGetter.new.get_ec2_hosts
    instance_array.concat(HostInfoGetter.new.get_rds_hosts)
    instance_json  = JSON.pretty_generate(instance_array)
    instance_file  = './instance_info.json'
    File.open(instance_file, 'w') { |file| file.write(instance_json) }
  end
end

GetHostInfo.new.write_output

