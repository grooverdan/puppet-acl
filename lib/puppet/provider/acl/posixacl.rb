require File.join(File.dirname(__FILE__), '..', 'acl')

Puppet::Type.type(:acl).provide(:posixacl, :parent => Puppet::Provider::Acl) do
  desc "Provide posix 1e acl functions using posix getfacl/setfacl commands"

  commands :setfacl => '/usr/bin/setfacl'
  commands :getfacl => '/usr/bin/getfacl'

  confine :feature => :posix
  defaultfor :operatingsystem => [:debian, :ubuntu]

  def exists?
    # Use long options for getfacl to support RHEL5
    getfacl('--absolute-names', '--no-effective', @resource.value(:path))
  end
  
  def set
    cur_perm = permission
    Puppet.debug "cur_perm-1: #{cur_perm}"
    @resource.value(:permission).each do |perm|
      Puppet.debug "permission-1: #{perm}"
      if !(cur_perm.include?(perm))
        Puppet.debug "!(cur_perm.include?(perm))-1"
        if check_recursive
          setfacl('-R', '-n', '-m', perm, @resource.value(:path))
        else
          setfacl('-n', '-m', perm, @resource.value(:path))
        end
      end
    end
  end

  def unset
    @resource.value(:permission).each do |perm|
      if check_recursive
        setfacl('-R', '-n', '-x', perm, @resource.value(:path))
      else
        setfacl('-n', '-x', perm, @resource.value(:path))
      end
    end
  end

  def purge
    if check_recursive
      setfacl('-R', '-b', @resource.value(:path))
    else
      setfacl('-b', @resource.value(:path))
    end
  end

  def permission
    value = []
    #String#lines would be nice, but we need to support Ruby 1.8.5
    getfacl('--absolute-names', '--no-effective', @resource.value(:path)).split("\n").each do |line|
      # Strip comments and blank lines
      if !(line =~ /^#/) and !(line == "")
        value << line
      end
    end
    case value.length
      when 0 then nil
      when 1 then value[0]
      else value
    end
  end
  
  def check_recursive
    # Changed functionality to return boolean true or false
    value = (@resource.value(:recursive) == :true)
  end

  def permission=(value)
    cur_perm = permission
    Puppet.debug "cur_perm-2: #{cur_perm}"
    purge
    value.each do |perm|
      Puppet.debug "permission-2: #{perm}"
      if !(cur_perm.include?(perm))
        Puppet.debug "!(cur_perm.include?(perm))-2"
        if check_recursive
          setfacl('-R', '-n', '-m', perm, @resource.value(:path))
        else
          setfacl('-n', '-m', perm, @resource.value(:path))
        end
      end
    end
  end

end
