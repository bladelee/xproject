# lib/remove_csp_middleware.rb
class RemoveCspMiddleware
    def initialize(app)
      @app = app
    end
  
    def call(env)
      status, headers, response = @app.call(env)
      headers.delete('Content-Security-Policy')
      headers.delete('Content-Security-Policy-Report-Only')
      [status, headers, response]
    end
  end