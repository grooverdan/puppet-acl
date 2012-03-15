
Puppet::Type.newtype(:acl) do
  desc <<-EOT
     Ensures that a set of ACL permissions are applied to a given file or directory.

      Example:

          acl { '/var/www/html':
            ensure      => present,
            permission  => [
              'user::rwx',
              'group::r-x',
              'mask::rwx',
              'other::r--',
              'default:user::rwx',
              'default:user:www-data:r-x',
              'default:group::r-x',
              'default:mask::rwx',
              'default:other::r--',
            ],
            provider    => posixacl,
            recursive   => true,
          }

      In this example, Puppet will ensure that the user and group permissions
      are set recursively on /var/www/html as well as add default permissions 
      that will apply to new directories and files created under /var/www/html
  
    EOT

  ensurable do
    newvalue(:present) do
      provider.set
    end
  
    newvalue(:absent) do
      provider.unset
    end
  
    newvalue(:purged) do
      provider.purge
    end
  end

  newparam(:path) do
    desc "The file or directory to which the ACL applies."
    isnamevar
    validate do |value|
      path = Pathname.new(value)
      unless path.absolute?
        raise ArgumentError, "Path must be absolute: #{path}"
      end
    end
  end

  newproperty(:permission, :array_matching => :all) do 
    desc "ACL permission(s)."

    def is_to_s(value)
      if value == :absent or value.include?(:absent)
        super
      else
        value.join(",")
      end
    end

    def should_to_s(value)
      if value == :absent or value.include?(:absent)
        super
      else
        value.join(",")
      end
    end

    # TODO munge into normalised form
    validate do |acl|
      unless acl =~ /^(d(efault)?:)?(((u(ser)?|g(roup)?):)?(([^:]+|((m(ask)?|o(ther)?):?))?|:?))(:[-rwxX]+|([0-7]{3,4}))$/
        raise ArgumentError, "%s is not valid acl permission" % acl
      end
    end
  end

  newparam(:recursive) do
    desc "Apply ACLs recursively."
    newvalues(:true, :false)
    defaultto :false
  end

  autorequire(:file) do
    self[:path]
  end
  
  validate do
    unless self[:permission]
      raise(Puppet::Error, "permission is a required property.")
    end
  end

end
