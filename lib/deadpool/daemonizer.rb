# Blatanly stolen from Ben Marini
# https://gist.github.com/517442/9ed5c4bd66bd8afc6a379286d8be1d8fb8a33925

module Deadpool
  module Daemonizer
    def daemonize(opts = {})
      opts = { log: '/dev/null', pid: "/var/run/#{File.basename($0)}.pid" }.merge(opts)

      $stdout.sync = $stderr.sync = true
      $stdin.reopen('/dev/null')

      exit if fork

      Process.setsid

      exit if fork

      Dir.chdir('/') if opts[:chdir]
      File.umask(0o000) if opts[:umask]

      if File.exist?(opts[:pid])
        begin
          existing_pid = File.read(opts[:pid]).to_i
          Process.kill(0, existing_pid) # See if proc exists
          abort "error: existing process #{existing_pid} using this pidfile, exiting"
        rescue Errno::ESRCH
          puts "warning: removing stale pidfile with pid #{existing_pid}"
        end
      end

      File.open(opts[:pid], 'w') { |f| f.write($$) }

      at_exit do
        ((File.read(opts[:pid]).to_i == $$) && File.unlink(opts[:pid]))
      rescue StandardError
        nil
      end

      puts "forked process is #{$$}"
      puts "output redirected to #{opts[:log]}"

      $stdout.reopen(opts[:log], 'a')
      $stderr.reopen(opts[:log], 'a')
      $stdout.sync = $stderr.sync = true
    end

    def kill(opts = {})
      opts = { log: '/dev/null', pid: "/var/run/#{File.basename($0)}.pid" }.merge(opts)
      pid = File.read(opts[:pid]).to_i
      sec = 60 # Seconds to wait before force killing
      Process.kill('TERM', pid)

      begin
        SystemTimer.timeout(sec) do
          loop do
            puts "waiting #{sec} seconds for #{pid} before sending KILL"
            Process.kill(0, pid) # See if proc exists

            sec -= 1
            sleep 1
          end
        end
      rescue Errno::ESRCH
        puts "killed process #{pid}"
      rescue Timeout::Error
        Process.kill('KILL', pid)
        puts "force killed process #{pid}"
      end
    rescue Errno::ENOENT
      puts "warning: pidfile #{opts[:pid]} does not exist"
    rescue Errno::ESRCH
      puts "warning: process #{pid} does not exist"
    end
  end
end
