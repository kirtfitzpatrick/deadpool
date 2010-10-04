# Assumes at a minimum the following config:
# --
# primary_host:   '127.0.0.1'
# secondary_host: '127.0.0.1'
# monitor_config:
#   redis_args: '[-h host] [-p port] [-a authpw] [-r repeat_times] [-n db_num]'

module Deadpool
  module Monitor
    class Redis < Base

      def primary_ok?
        false
      end

      def secondary_ok?
        false
      end
    end
  end
end
