require 'aws-sdk'

class HostInfoGetter
  def initialize
    @ec2 = Aws::EC2::Client.new(
        region: 'us-east-1'
    )

    @rds = Aws::RDS::Client.new(
        region: 'us-east-1'
    )
  end

  def get_host_name(tags)
    name = 'no_name'
    tags.each { |t| name = t.value.downcase if t.key == 'Name' }
    name
  end

  def get_ec2_info(instance)
    # state=#<struct Aws::EC2::Types::InstanceState code=16 name="running">
    # launch_time=2015-09-13 15:16:34 UTC
    # placement=#<struct Aws::EC2::Types::Placement availability_zone="us-east-1d" group_name="" tenancy="default">
    # security_groups=[#<struct Aws::EC2::Types::GroupIdentifier group_name="salt_master_sg" group_id="sg-6167310c">]

    {
        id: instance.instance_id,
        name: get_host_name(instance.tags),
        pub_ip: instance.public_ip_address,
        priv_ip: instance.private_ip_address,
        aliases: [ instance.public_ip_address, instance.private_ip_address ],
        instance_type: instance.instance_type,
        ami_id: instance.image_id,
        key: instance.key_name,
        zone: instance.placement.availability_zone,
        spot_req: instance.spot_instance_request_id,
        is_spot: ! instance.spot_instance_request_id.nil?,
        volumes: get_volumes(instance.block_device_mappings),
        service: 'ec2'
    # TODO: security groups, state, launch time and zone
    }
  end

  def get_volumes(device_arr)
    volumes = []

    device_arr.each do |device|
      volumes << device.ebs.volume_id
    end

    volumes
  end

  def get_ec2_hosts
    response = @ec2.describe_instances

    instance_arr = []
    response.reservations.each do |res|
      res.instances.each do |i|
        # next unless i.state.code == 16
        info = get_ec2_info(i)
        instance_arr << info
      end
    end

    instance_arr
  end

  def get_ip_for_db(instance)
    addr = instance.endpoint.address
    ns_info = `nslookup #{addr}`.split("\n")
    ns_info[-1].split(': ')[1]
  end

  def get_rds_info(instance)
    priv_ip = get_ip_for_db(instance)

    {
        name: instance.db_instance_identifier,
        class: instance.db_instance_class,
        host_name: instance.endpoint.address,
        priv_ip: priv_ip,
        aliases: [ priv_ip ],
        service: 'rds'
    }

  end

  def get_rds_hosts
    response = @rds.describe_db_instances
    instance_arr = []

    response.db_instances.each do |db|
      info = get_rds_info(db)
      instance_arr << info
    end

    instance_arr
  end
end

