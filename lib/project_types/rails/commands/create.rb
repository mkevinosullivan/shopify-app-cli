# frozen_string_literal: true
module Rails
  module Commands
    class Create < ShopifyCli::SubCommand
      USER_AGENT_CODE = <<~USERAGENT
        module ShopifyAPI
          class Base < ActiveResource::Base
            self.headers['User-Agent'] << " | ShopifyApp/\#{ShopifyApp::VERSION} | Shopify App CLI"
          end
        end
      USERAGENT

      INVALID_RUBY_VERSION = <<~MSG
        This project requires a ruby version ~> 2.4.
        See {{underline:https://github.com/Shopify/shopify-app-cli/blob/master/docs/installing-ruby.md}}
        for our recommended method of installing ruby.
      MSG

      DEFAULT_RAILS_FLAGS = %w(--skip-spring)

      options do |parser, flags|
        # backwards compatibility allow 'title' for now
        parser.on('--title=TITLE') { |t| flags[:title] = t }
        parser.on('--name=NAME') { |t| flags[:title] = t }
        parser.on('--organization_id=ID') { |url| flags[:organization_id] = url }
        parser.on('--shop_domain=MYSHOPIFYDOMAIN') { |url| flags[:shop_domain] = url }
        parser.on('--type=APPTYPE') { |url| flags[:type] = url }
        parser.on('--db=DB') { |db| flags[:db] = db }
        parser.on('--api') { flags[:api] = true }
        parser.on('--rails-opts=RAILSOPTS') { |opts| flags[:rails_opts] = opts }
      end

      def call(args, _name)
        form = Forms::Create.ask(@ctx, args, options.flags)
        return @ctx.puts(self.class.help) if form.nil?

        @ctx.abort(INVALID_RUBY_VERSION) unless Ruby.version(@ctx).satisfies?('~>2.4')

        build(form.name)
        set_custom_ua
        ShopifyCli::Project.write(@ctx, 'rails')

        ShopifyCli::Core::Finalize.request_cd(form.name)

        api_client = ShopifyCli::Tasks::CreateApiClient.call(
          @ctx,
          org_id: form.organization_id,
          title: form.title,
          type: form.type,
          app_url: 'https://shopify.github.io/shopify-app-cli/getting-started',
        )

        ShopifyCli::Resources::EnvFile.new(
          api_key: api_client["apiKey"],
          secret: api_client["apiSecretKeys"].first["secret"],
          shop: form.shop_domain,
          scopes: 'write_products,write_customers,write_draft_orders',
        ).write(@ctx)

        partners_url = "https://partners.shopify.com/#{form.organization_id}/apps/#{api_client['id']}"

        @ctx.puts("{{v}} {{green:#{form.title}}} was created in your Partner" \
                  " Dashboard " \
                  "{{underline:#{partners_url}}}")
        @ctx.puts("{{*}} Run {{command:#{ShopifyCli::TOOL_NAME} serve}} to start a local server")
        @ctx.puts("{{*}} Then, visit {{underline:#{partners_url}/test}} to install" \
                  " {{green:#{form.title}}} on your Dev Store")
      end

      def self.help
        <<~HELP
        {{command:#{ShopifyCli::TOOL_NAME} create rails}}: Creates a ruby on rails app.
          Usage: {{command:#{ShopifyCli::TOOL_NAME} create rails}}
          Options:
            {{command:--name=NAME}} App name. Any string.
            {{command:--app_url=APPURL}} App URL. Must be valid URL.
            {{command:--organization_id=ID}} App Org ID. Must be existing org ID.
            {{command:--shop_domain=MYSHOPIFYDOMAIN}} Test store URL. Must be existing test store.
        HELP
      end

      private

      def build(name)
        install_gem('rails')
        CLI::UI::Frame.open("Installing bundler…") do
          install_gem('bundler', '~>1.0')
          install_gem('bundler', '~>2.0')
        end

        CLI::UI::Frame.open("Generating new rails app project in #{name}...") do
          new_command = %w(rails new)
          new_command += DEFAULT_RAILS_FLAGS
          new_command << "--database=#{options.flags[:db]}" unless options.flags[:db].nil?
          new_command << "--api" unless options.flags[:api].nil?
          new_command += options.flags[:rails_opts].split unless options.flags[:rails_opts].nil?
          new_command << name

          syscall(new_command)
        end

        @ctx.root = File.join(@ctx.root, name)

        @ctx.puts("{{v}} Adding shopify_app gem…")
        File.open(File.join(@ctx.root, 'Gemfile'), 'a') do |f|
          f.puts "\ngem 'shopify_app', '>=11.3.0'"
        end
        CLI::UI::Frame.open("Running bundle install...") do
          syscall(%w(bundle install))
        end

        CLI::UI::Frame.open("Running shopify_app generator...") do
          begin
            syscall(%w(spring stop))
          rescue
          end
          syscall(%w(rails generate shopify_app))
        end

        CLI::UI::Frame.open('Running migrations…') do
          syscall(%w(rails db:migrate RAILS_ENV=development))
        end
      end

      def set_custom_ua
        ua_path = File.join('config', 'initializers', 'user_agent.rb')
        @ctx.write(ua_path, USER_AGENT_CODE)
      end

      def syscall(args)
        args[0] = Gem.binary_path_for(@ctx, args[0])
        @ctx.system(*args, chdir: @ctx.root)
      end

      def install_gem(name, version = nil)
        Gem.install(@ctx, name, version)
      end
    end
  end
end

