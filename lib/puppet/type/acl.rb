
Puppet::Type.newtype(:acl) do
    @doc = "Manage posix acl on files"

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

    newparam(:name) do
      desc "The file on with the acl applies"
      isnamevar

    end

    newproperty(:permission, :array_matching => :all) do 
      desc "Multiple acl permissions"

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
        unless acl =~ /^(d(efault)?:)?((u(ser)?|g(roup)?):[^:]+|((m(ask)?|o(ther)?):?))(:[-rwxX]+|([0-7]{3,4}))$/
          raise ArgumentError, "%s is not valid acl permission" % acl
        end
      end
    end

    autorequire(:file) do
      self[:name]
    end
  
    { :user => 'u(ser)?:', :group => 'g(roup)?:'}.each do |type, regex|
      if obj = @parameters[:permission]
        autorequire(type) do
          val = []
          obj.each do |value|
            if value =~ /^(d(efault)?:)?#{regex}([^:]+)/
              val << $4
            end
          end
          val
        end
      end
    end

end

