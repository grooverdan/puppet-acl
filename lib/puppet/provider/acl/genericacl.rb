require File.join(File.dirname(__FILE__), '..', 'acl')

Puppet::Type.type(:acl).provide(:genericacl, :parent => Puppet::Provider::Acl) do

end