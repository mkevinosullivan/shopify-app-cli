require 'json'
require 'fileutils'
require 'shopify_cli'
require 'forwardable'

module ShopifyCli
  ##
  # Wraps around ngrok functionality to allow you to spawn a ngrok proccess in the
  # background and stop the process when you need to. It also allows control over
  # the ngrok process between application runs.
  class Tunnel
    extend SingleForwardable

    def_delegators :new, :start, :stop, :auth

    class FetchUrlError < RuntimeError; end
    class NgrokError < RuntimeError; end

    PORT = 8081 # port that ngrok will bind to
    # mapping for supported operating systems for where to download ngrok from.
    DOWNLOAD_URLS = {
      mac: 'https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-darwin-amd64.zip',
      linux: 'https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip',
    }

    ##
    # will find and stop a running tunnel process. It will also output if the
    # operation was successful or not
    #
    # #### Paramters
    #
    # * `ctx` - running context from your command
    #
    def stop(ctx)
      if ShopifyCli::ProcessSupervision.running?(:ngrok)
        if ShopifyCli::ProcessSupervision.stop(:ngrok)
          ctx.puts('{{green:x}} ngrok tunnel stopped')
        else
          ctx.abort('ngrok tunnel could not be stopped. Try running {{command:killall -9 ngrok}}')
        end
      else
        ctx.puts("{{green:x}} ngrok tunnel not running")
      end
    end

    ##
    # start will start a running ngrok process running in the background. It will
    # also output the success of this operation
    #
    # #### Paramters
    #
    # * `ctx` - running context from your command
    #
    # #### Returns
    #
    # * `url` - the url that the tunnel is now bound to and available to the public
    #
    def start(ctx)
      install(ctx)
      process = ShopifyCli::ProcessSupervision.start(:ngrok, ngrok_command)
      log = fetch_url(ctx, process.log_path)
      if log.account
        ctx.puts("{{v}} ngrok tunnel running at {{underline:#{log.url}}}, with account #{log.account}")
      else
        ctx.puts("{{v}} ngrok tunnel running at {{underline:#{log.url}}}")
      end
      log.url
    end

    ##
    # will add the users authentication token to our version of ngrok to unlock the
    # extended ngrok features
    #
    # #### Paramters
    #
    # * `ctx` - running context from your command
    # * `token` - authentication token provided by ngrok for extended features
    #
    def auth(ctx, token)
      install(ctx)
      ctx.system(File.join(ShopifyCli::ROOT, 'ngrok'), 'authtoken', token)
    end

    private

    def install(ctx)
      return if File.exist?(File.join(ShopifyCli::ROOT, 'ngrok'))
      spinner = CLI::UI::SpinGroup.new
      spinner.add('Installing ngrok...') do
        zip_dest = File.join(ShopifyCli::ROOT, 'ngrok.zip')
        unless File.exist?(zip_dest)
          ctx.system('curl', '-o', zip_dest, DOWNLOAD_URLS[ctx.os], chdir: ShopifyCli::ROOT)
        end
        ctx.system('unzip', '-u', zip_dest, chdir: ShopifyCli::ROOT)
        ctx.rm(zip_dest)
      end
      spinner.wait
    end

    def fetch_url(ctx, log_path)
      LogParser.new(log_path)
    rescue RuntimeError => e
      stop(ctx)
      raise e.class, e.message
    end

    def ngrok_command
      "exec #{File.join(ShopifyCli::ROOT, 'ngrok')} http -log=stdout -log-level=debug #{PORT}"
    end

    class LogParser # :nodoc:
      TIMEOUT = 10

      attr_reader :url, :account

      def initialize(log_path)
        @log_path = log_path
        counter = 0
        while counter < TIMEOUT
          parse
          return if url
          counter += 1
          sleep(1)
        end

        raise FetchUrlError, "Unable to fetch external url" unless url
      end

      def parse
        @log = File.read(@log_path)
        unless error.empty?
          raise NgrokError, error.first
        end
        parse_account
        parse_url
      end

      def parse_url
        @url, _ = @log.match(/msg="started tunnel".*url=(https:\/\/.+)/)&.captures
      end

      def parse_account
        @account, _ = @log.match(/AccountName:([\w\s]+) SessionDuration/)&.captures
      end

      def error
        @log.scan(/msg="command failed" err="([^"]+)"/).flatten
      end
    end

    private_constant :LogParser
  end
end
