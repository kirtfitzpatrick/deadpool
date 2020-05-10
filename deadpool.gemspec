Gem::Specification.new do |spec|
  spec.name        = 'deadpool'
  spec.version     = '0.1.3'
  spec.summary     = '/etc/hosts based failover system w/monitoring'
  spec.description = <<-EOF
/etc/hosts based failover system w/monitoring. Nagios compatible monitoring 
built in. Also generic enough to handle failover and monitoring for just about 
anything that can be exec'd through ssh.
  EOF
  spec.post_install_message = <<-EOF
Desparate times call for desparate measures. To get started run:
$ deadpool-generator --help
  EOF

  spec.author                = 'Kirt Fitzpatrick'
  spec.homepage              = 'https://github.com/kirtfitzpatrick/deadpool'
  spec.license               = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.bindir       = 'bin'
  spec.executables  = ['deadpool-admin', 'deadpool-generator', 'deadpool-hosts']
  spec.files        = Dir['README', 'bin/*', 'lib/**/*', 'config/**/*', 'doc/**/*']
  spec.require_path = 'lib'
  # spec.add_dependency('eventmachine', '1.2.7')
  # spec.add_dependency('json', '2.3.0')
  spec.add_runtime_dependency('eventmachine', '1.2.7')
  spec.add_runtime_dependency('json', '2.3.0')
end
