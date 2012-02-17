
Puppet::Type.type(:posixacl).provide :acl, :parent => Puppet::Provider::Package do
    desc "provide posix 1e acl functions using posix getfacl/setfacl commands"

    commands :setfacl => '/usr/bin/setfacl'
    commands :getfacl => '/usr/bin/getfacl'

    confine :feature => :posix

    def set do
      @resource[:permissions].each do |perm|        
        setfacl '-m'  perm @resource[:name]
      end
    end

    def unset do
      @resource[:permissions].each do |perm|        
        setfacl '-x' perm @resource[:name]
      end
    end

    def purge do
      setfacl '-b' @resource[:name]
    end

    def permissions do
      value = []
      #String#lines would be nice, but we need to support Ruby 1.8.5
      getfacl '-es' @resource[:name].split("\n").each do |line|
        value << line
      end
      case value.length
        when 0 then nil
        when 1 then value[0]
        else value
      end
    end

    def permissions=(value) do
      value.each do |perm|        
        setfacl option perm @resource[:name]
      end
    end

end
