class ShortStack < Pancake::Stack
  inheritable_inner_classes :Controller

  class Controller
    extend  Pancake::Mixins::Publish
    include Pancake::Mixins::Render
    include Pancake::Mixins::RequestHelper
    include Pancake::Mixins::ResponseHelper
    include Pancake::Mixins::StackHelper

    inheritable_inner_classes :ViewContext

    class self::ViewContext
      include Pancake::Mixins::RequestHelper
      include AnyView

      # No way to get the env into the view context... this is not good :(
      def env
        _view_context_for.env
      end

      def self.template(name_or_template, opts = {})
        opts[:format] ||= content_type
        super
      end

      def template(name_or_template, opts={})
        opts[:format] ||= content_type
        super
      end

      def _template_name_for(name, opts = {})
        opts[:format] ||= :html
        "#{name}.#{opts[:format]}"
      end
    end

    extlib_inheritable_accessor :_handle_exception

    push_paths(:views, ["app/views", "views"], "**/*")

    DEFAULT_EXCEPTION_HANDLER = lambda do |error|
      if layout = env['layout']
        layout.content = render :error, :error => error
        layout
      else
        render :error, :error => error
      end
    end unless defined?(DEFAULT_EXCEPTION_HANDLER)

    # @api private
    def self.call(env)
      app = new(env)
      app.dispatch!
    end

    def layout
      env['layout']
    end

    # @api public
    attr_accessor :status

    def initialize(env)
      @env, @request = env, Rack::Request.new(env)
      @status = 200
    end

    # Provides access to the request params
    # @api public
    def params
      request.params
    end

    attr_writer :action
    def action
      @action ||=  begin
        rr = request.env['router.response']
        action = rr && rr.dest && rr.dest[:action]
      end
    end

    # Dispatches to an action based on the params["action"] parameter
    def dispatch!
      if logger
        logger.info "Request: #{request.path}"
        logger.info "Params: #{params.inspect}"
      end


      # Check that the action is available
      raise Pancake::Errors::NotFound, "No Action Found" unless allowed_action?(action)

      @action_opts  = actions[action]

      negotiate_content_type!(@action_opts.formats, params)

      # Set the layout defaults before the action is rendered
      if layout && stack_class.default_layout
        layout.template_name = stack_class.default_layout
      end

      layout.format = params['format'] if layout

      logger.info "Dispatching to #{action.inspect}" if logger

      result = catch(:halt){ self.send(action) }

      case result
      when Array
        result
      when Rack::Response
        result.finish
      when String
        out = if layout
          layout.content = result
          layout
        else
          result
        end
        Rack::Response.new(out, status, headers).finish
      else
        Rack::Response.new((result || ""), status, headers).finish
      end

    rescue Pancake::Errors::HttpError => e
      if logger && log_http_error?(e)
        logger.error "Exception: #{e.message}"
        logger.error e.backtrace.join("\n")
      end
      handle_request_exception(e)
    rescue Exception => e
      if Pancake.handle_errors?
        server_error = Pancake::Errors::Server.new(e.message)
        server_error.exceptions << e
        server_error.set_backtrace e.backtrace
      else
        server_error = e
      end
      handle_request_exception(server_error)
    end

    def log_http_error?(error)
      true
    end

    def self.handle_exception(&block)
      if block_given?
        self._handle_exception = block
      else
        self._handle_exception || DEFAULT_EXCEPTION_HANDLER
      end
    end

    def handle_request_exception(error)
      raise(error.class, error.message, error.backtrace) unless Pancake.handle_errors?
      self.status = error.code
      result = instance_exec error, &self.class.handle_exception
      Rack::Response.new(result, status, headers).finish
    end

    private
    def allowed_action?(action)
      self.class.actions.include?(action.to_s)
    end

    public
    def self.roots
      stack_class.roots
    end

    def self._template_name_for(name, opts)
      opts[:format] ||= :html
      [
        "#{name}.#{opts[:format]}",
        "#{name}"
      ]
    end

    def _tempate_name_for(name, opts = {})
      opts[:format] ||= content_type
      self.class._template_name_for(name, opts)
    end
  end # Controller
end # Short
