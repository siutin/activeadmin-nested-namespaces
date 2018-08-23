require "active_admin/nested_namespace/version"

module ActiveAdmin
  module NestedNamespace
    def self.setup
      ActiveAdmin::Application.class_eval do

        def namespace(name)
          name ||= :root

          namespace = namespaces[build_name_path(name)] ||= begin
            namespace = Namespace.new(self, name)
            ActiveSupport::Notifications.publish ActiveAdmin::Namespace::RegisterEvent, namespace
            namespace
          end

          yield(namespace) if block_given?

          namespace
        end

        def build_name_path(name)
          Array(name).map(&:to_s).map(&:underscore).map(&:to_sym)
        end

      end

      ActiveAdmin::BaseController.class_eval do
        def authenticate_active_admin_user
          if active_admin_namespace.authentication_method
            auth_method = active_admin_namespace.authentication_method
            if auth_method.is_a?(Proc)
              namespace = active_admin_namespace.name_path
              send(auth_method.call(namespace))
            else
              send(auth_method)
            end
          end
        end

        def current_active_admin_user
          if active_admin_namespace.current_user_method
            user_method = active_admin_namespace.current_user_method
            if user_method.is_a?(Proc)
              namespace = active_admin_namespace.name_path
              send(user_method.call(namespace))
            else
              send(user_method)
            end
          end
        end
      end

      ActiveAdmin::Namespace.class_eval do

        attr_reader :name_path

        def initialize(application, name)
          @application = application
          @name_path = ActiveAdmin.application.build_name_path(name)
          @resources = ResourceCollection.new
          register_module unless root?
          build_menu_collection
        end

        def name
          Deprecation.warn "name replaced by name_path now that namespaces can be nested."
          name_path.first
        end

        def root?
          name_path.first == :root
        end

        def module_name
          root? ? nil : name_path.map(&:to_s).map(&:camelize).join('::')
        end

        def route_prefix
          root? ? nil : name_path.map(&:to_s).join('_').underscore
        end

        def add_logout_button_to_menu(menu, priority = 20, html_options = {})
          computed_logout_link_path = logout_link_path.is_a?(Proc) ? logout_link_path.call(name_path) : logout_link_path

          if computed_logout_link_path
            html_options = html_options.reverse_merge(method: logout_link_method || :get)
            menu.add id: 'logout', priority: priority, html_options: html_options,
                     label: -> {I18n.t 'active_admin.logout'},
                     url: computed_logout_link_path,
                     if: :current_active_admin_user?
          end
        end

        # dynamically create nested modules
        def register_module
          module_names = module_name.split("::").inject([]) {|n, c| n << (n.empty? ? [c] : [n.last] + [c]).flatten}
          module_names.each do |module_name_array|
            eval "module ::#{module_name_array.join("::")}; end"
          end
        end

      end

      ActiveAdmin::Namespace::Store.class_eval do

        def [](key)
          @namespaces[Array(key)]
        end

        def names
          Deprecation.warn "names replaced by name_paths now that namespaces can be nested."
          @namespaces.keys.first
        end

        def name_paths
          @namespaces.keys
        end

      end

      # TODO: patch active_admin/orm/active_record/comments.rb

      ActiveAdmin::Comment.class_eval do
        def self.find_for_resource_in_namespace(resource, name)
          where(
              resource_type: resource_type(resource),
              resource_id: resource,
              namespace: name.to_s
          ).order(ActiveAdmin.application.namespaces[ActiveAdmin.application.build_name_path(name)].comments_order)
        end
      end

      ActiveAdmin::Comments::Views::Comments.class_eval do

        def build(resource)
          @resource = resource
          @comments = ActiveAdmin::Comment.find_for_resource_in_namespace(resource, active_admin_namespace.name_path).includes(:author).page(params[:page])
          super(title, for: resource)
          build_comments
        end

        def comments_url(*args)
          parts = []
          parts << active_admin_namespace.name_path unless active_admin_namespace.root?
          parts << active_admin_namespace.comments_registration_name.underscore
          parts << 'path'
          send parts.join('_'), *args
        end

        def comment_form_url
          parts = []
          parts << active_admin_namespace.name_path unless active_admin_namespace.root?
          parts << active_admin_namespace.comments_registration_name.underscore.pluralize
          parts << 'path'
          send parts.join '_'
        end

      end

      ActiveAdmin::Page.class_eval do
        def namespace_name
          Deprecation.warn "namespace_name replaced by namespace_name now that namespaces can be nested."
          namespace.name.to_s
        end

        def namespace_name_path
          namespace.name_path
        end
      end

      ActiveAdmin::Resource::BelongsTo::TargetNotFound.class_eval do
        def initialize(key, namespace)
          super "Could not find #{key} in #{namespace.name_path} " +
                    "with #{namespace.resources.map(&:resource_name)}"
        end
      end

      ActiveAdmin::Router.class_eval do

        def define_root_routes(router)
          router.instance_exec @application.namespaces do |namespaces|
            namespaces.each do |namespace|
              if namespace.root?
                root namespace.root_to_options.merge(to: namespace.root_to)
              else
                proc = Proc.new do
                  root namespace.root_to_options.merge(to: namespace.root_to, as: :root)
                end
                (namespace.name_path.reverse.inject(proc) {|n, c| Proc.new {namespace c, namespace.route_options.dup, &n}}).call
              end
            end
          end
        end

        # Defines the routes for each resource
        def define_resource_routes(router)
          router.instance_exec @application.namespaces, self do |namespaces, aa_router|
            resources = namespaces.flat_map {|n| n.resources.values}
            resources.each do |config|
              routes = aa_router.resource_routes(config)

              # Add in the parent if it exists
              if config.belongs_to?
                belongs_to = routes
                routes = Proc.new do
                  # If it's optional, make the normal resource routes
                  instance_exec &belongs_to if config.belongs_to_config.optional?

                  # Make the nested belongs_to routes
                  # :only is set to nothing so that we don't clobber any existing routes on the resource
                  resources config.belongs_to_config.target.resource_name.plural, only: [] do
                    instance_exec &belongs_to
                  end
                end
              end

              # Add on the namespace if required
              unless config.namespace.root?
                nested = routes
                routes = Proc.new do

                  proc = Proc.new do
                    instance_exec &nested
                  end
                  (config.namespace.name_path.reverse.inject(proc) {|n, c| Proc.new {namespace c, config.namespace.route_options.dup, &n}}).call
                end
              end

              instance_exec &routes
            end
          end
        end

      end

      ActiveAdmin::Scope.class_eval do
        def initialize(name, method = nil, options = {}, &block)
          @name, @scope_method = name, method.try(:to_sym)

          if name.is_a? Proc
            raise "A string/symbol is required as the second argument if your label is a proc." unless method
            @id = ActiveAdmin::Dependency.rails.parameterize method.to_s
          else
            @scope_method ||= (name.is_a?(Array) ? name.join('_').underscore : name).to_sym
            @id = ActiveAdmin::Dependency.rails.parameterize name.to_s
          end

          @scope_method = nil if @scope_method == :all
          @scope_method, @scope_block = nil, block if block_given?

          @localizer = options[:localizer]
          @show_count = options.fetch(:show_count, true)
          @display_if_block = options[:if] || proc {true}
          @default_block = options[:default] || proc {false}
        end
      end

      ActiveAdmin::Views::Pages::Base.class_eval do
        def add_classes_to_body
          @body.add_class(params[:action])
          @body.add_class(params[:controller].tr('/', '_'))
          @body.add_class("active_admin")
          @body.add_class("logged_in")
          @body.add_class(active_admin_namespace.name_path.map(&:to_s).join('_') + '_namespace')
        end
      end
    end
  end
end
