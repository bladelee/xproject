# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    # policy.default_src :self, :https
    # policy.font_src    :self, :https, :data
    # policy.img_src     :self, :https, :data
    # policy.object_src  :none
    # policy.script_src  :self, :https
    # policy.script_src  :self, :https, :unsafe_inline, :unsafe_eval, :nonce => true
    # policy.script_src  :self, 
    #                     :https, 
    #                     "http://localhost:3000",
    #                     "ws://localhost:3000",
    #                     "http://localhost:4200/employees",
    #                     "ws://localhost:4200",
    #                     "https://www.ssa.gov",
    #                     :unsafe_inline    # 允许内联脚本
    # policy.script_src  :self, :https, :unsafe_inline, :unsafe_eval, :strict_dynamic, "'nonce-#{SecureRandom.base64(16)}'"
    # policy.style_src   :self, :https
    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"
  end

#   # Generate session nonces for permitted importmap, inline scripts, and inline styles.
#   config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
#   config.content_security_policy_nonce_directives = %w(script-src style-src)
    # config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }
    # config.content_security_policy_nonce_directives = %w(script-src)

    config.content_security_policy do |policy|
        policy.default_src "*"
        policy.script_src "*", :unsafe_inline, :unsafe_eval
        policy.style_src "*", :unsafe_inline
    end

    # 禁用 nonce 生成
    config.content_security_policy_nonce_generator = nil
    config.content_security_policy_nonce_directives = []
  # Report violations without enforcing the policy.
  # config.content_security_policy_report_only = true
end
