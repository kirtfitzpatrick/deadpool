require_relative 'lib/deadpool/version'

Gem::Specification.new do |spec|
  spec.name = 'deadpool'
  spec.version = Deadpool::VERSION
  spec.author = 'Kirt Fitzpatrick'
  spec.summary = '/etc/hosts based failover system w/monitoring'
  spec.description = <<~DESCRIPTION
    /etc/hosts based failover system w/monitoring. Nagios compatible monitoring 
    built in. Also generic enough to handle failover and monitoring for just about 
    anything that can be exec'd through ssh.
  DESCRIPTION
  spec.post_install_message = <<~MESSAGE
    Desparate times call for desparate measures. To get started run:
    $ deadpool-gen --help
  MESSAGE

  spec.homepage = 'https://github.com/kirtfitzpatrick/deadpool'
  spec.license = 'MIT'
  spec.required_ruby_version = '~> 2.7.0'
  spec.metadata["source_code_uri"] = "https://github.com/kirtfitzpatrick/deadpool"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.bindir = 'bin'
  spec.executables = %w[deadpool deadpool-gen deadpool-hosts]
  spec.files = Dir['README', 'bin/deadpool*', 'lib/**/*', 'config/**/*']
  spec.require_path = 'lib'

  spec.add_runtime_dependency 'eventmachine', '~> 1.2.7'
  spec.add_runtime_dependency 'json', '~> 2.3.0'
  spec.add_runtime_dependency 'net-ssh', '~> 6.0.2'

  spec.add_development_dependency 'bundler', '~> 2.1.4'
  spec.add_development_dependency 'rake', '~> 13.0.1'
  spec.add_development_dependency 'mocha', '~> 1.11.2'
  spec.add_development_dependency 'simplecov', '~> 0.18.5'
end
