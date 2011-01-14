
Gem::Specification.new do |s|
  s.name        = 'deadpool'
  s.version     = '0.1.3'
  s.summary     = 'Non VIP based failover service for MySQL and others in the cloud.'
  s.description = <<-EOF
    Non VIP based failover service for MySQL and others in the cloud.
    Nagios monitoring built in.
    Designed to let you add custom monitoring and failover plugins.
  EOF

  s.required_ruby_version = '>= 1.8.6'

  s.author      = 'Kirt Fitzpatrick'
  s.email       = 'kirt.fitzpatrick@akqa.com'

  s.bindir      = 'bin'
  s.executables = ['deadpool_admin', 'deadpool_generator', 'deadpool_hosts']

  s.files        = Dir['README', 'bin/*', 'lib/**/*', 'config/**/*', 'doc/**/*']
  s.require_path = 'lib'


  s.add_dependency('eventmachine', '0.12.10')
  s.add_dependency('json', '1.4.6')

  
end
