
Gem::Specification.new do |s|
  s.name        = 'deadpool'
  s.version     = '0.0.1'
  s.summary     = 'Failover Service for MySQL, Redis, whatever.'
  s.description = <<-EOF
    Plugin architecture and chainable failover protocols.
    Nagios reporting baked in.
    Can use VIPs but doesn't need 'em.
    Can monitor and failover multiple services within the same instance.
  EOF

  s.required_ruby_version = '>= 1.8.6'
  # s.required_rubygems_version = ">= 1.3.6"

  s.author      = 'Kirt Fitzpatrick'
  s.email       = 'kirt.fitzpatrick@akqa.com'

  s.bindir      = 'bin'
  s.executables = ['deadpool_server', 'deadpool_admin', 'etc_hosts_switch']
  # s.default_executable = 'deadpool_server'

  s.files        = Dir['README', 'bin/*', 'lib/**/*', 'config/**/*', 'doc/**/*']
  s.require_path = 'lib'


  s.add_dependency('eventmachine', '0.12.10')
  s.add_dependency('json', '1.4.6')

  
end
