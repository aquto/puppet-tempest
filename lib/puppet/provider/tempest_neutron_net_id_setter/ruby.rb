Puppet::Type.type(:tempest_neutron_net_id_setter).provide(:ruby) do

  # almost entirely lifted from stdlib's file_line

  def exists?
    lines.find do |line|
      should_line.chomp == line.chomp
    end
  end

  def create
    handle_create_with_match
  end

  def self.get_network_id(network_name)
    network = Puppet::Type.type('neutron_network').instances.find do |i|
      i.provider.name == network_name
    end
    if network
      return network.provider.id
    end
  end

  def get_network_id
    @network_id ||= self.class.get_network_id(@resource[:network_name])
  end

  def should_line
    "#{resource[:name]} = #{get_network_id}"
  end

  def match
    /^\s*#{resource[:name]}\s*=\s*/
  end

  def handle_create_with_match()
    regex = match
    match_count = lines.select { |l| regex.match(l) }.count
    if match_count > 1
      raise Puppet::Error, "More than one line in file \
'#{resource[:tempest_conf_path]}' matches pattern '#{regex.to_s}'"
    end
    File.open(resource[:tempest_conf_path], 'w') do |fh|
      lines.each do |l|
        fh.puts(regex.match(l) ? should_line : l)
      end

      if (match_count == 0)
        fh.puts(should_line)
      end
    end
  end

  private
  def lines
    # If this type is ever used with very large files, we should
    #  write this in a different way, using a temp
    #  file; for now assuming that this type is only used on
    #  small-ish config files that can fit into memory without
    #  too much trouble.
    @lines ||= File.readlines(resource[:tempest_conf_path])
  end

end
