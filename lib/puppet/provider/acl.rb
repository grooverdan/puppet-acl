# Abstract
class Puppet::Provider::Acl < Puppet::Provider

  private

  def tempdir
    @tempdir ||= File.join(Dir.tmpdir, 'acl-' + Digest::MD5.hexdigest(@resource.value(:path)))
  end

end