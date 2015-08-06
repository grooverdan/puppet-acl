require File.join(File.dirname(__FILE__), '..', 'acl')

Puppet::Type.type(:acl).provide(:posixacl, :parent => Puppet::Provider::Acl) do
  desc "Provide posix 1e acl functions using posix getfacl/setfacl commands"

  commands :setfacl => '/usr/bin/setfacl'
  commands :getfacl => '/usr/bin/getfacl'

  confine :feature => :posix
  defaultfor :operatingsystem => [:debian, :ubuntu, :redhat, :centos, :fedora]

  def exists?
    permission
  end
  
  def unset_perm(perm, path)
    # Don't try to unset mode bits, it don't make sense!
    if !(perm =~ /^(((u(ser)?)|(g(roup)?)|(m(ask)?)|(o(ther)?)):):/)
      perm = perm.split(':')[0..-2].join(':')
      if check_recursive
        setfacl('-R', '-n', '-x', perm, path)
      else
        setfacl('-n', '-x', perm, path)
      end
    end
  end

  def set_perm(perm, path)
    if check_recursive
      setfacl('-R', '-n', '-m', perm, path)
    else
      setfacl('-n', '-m', perm, path)
    end
  end

  def unset
    @resource.value(:permission).each do |perm|
      unset_perm(perm, @resource.value(:path))
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
      else value.sort
    end
  end
  
  def check_recursive
    # Changed functionality to return boolean true or false
    value = (@resource.value(:recursive) == :true)
  end

  def check_exact
    value = (@resource.value(:action) == :exact)
  end
  
  def check_unset
    value = (@resource.value(:action) == :unset)
  end

  def check_purge
    value = (@resource.value(:action) == :purge)
  end

  def check_set
    value = (@resource.value(:action) == :set)
  end

  def permission=(value)
    Puppet.debug @resource.value(:action)
    case @resource.value(:action)
    when :unset
      unset
    when :purge
      purge
    when :exact, :set
      cur_perm = permission
      perm_to_set = @resource.value(:permission) - cur_perm
      perm_to_unset = cur_perm - @resource.value(:permission)
      if (perm_to_set.length == 0 && perm_to_unset.length == 0)
        return false
      end
      # Take supplied perms literally, unset any existing perms which
      # are absent from ACLs given
      if check_exact
        perm_to_unset.each do |perm|
          # Skip base perms in unset step
          if perm =~ /^(((u(ser)?)|(g(roup)?)|(m(ask)?)|(o(ther)?)):):/
            Puppet.debug "skipping unset of base perm: #{perm}"
          else
            unset_perm(perm, @resource.value(:path))
          end
        end
      end
      perm_to_set.each do |perm|
        set_perm(perm, @resource.value(:path))
      end
    end
  end
end
