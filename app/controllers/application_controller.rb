class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.

    protect_from_forgery with: :exception
    include SessionsHelper

private

    def braintree_transaction_create(token, amount, order_id)
      payload = {
        :source => {
          :type  => "credit_card",
          :id => token
        },
        :amount => amount,
        :order_id => order_id,
        :currency => "USD"
      }

      action = "charges"
      response = braintree_post(payload, action)
      return response
    end

    def braintree_token_create(payment_method_token)
      payload = {
            :type => "credit_card",
            :token_id => payment_method_token,
            :verification => {
              :amount => "1.00",
              :currency => "USD",
              :vault_on_failure => false
            }
      }

      action = "payment-methods"
      response = braintree_post(payload, action)
      return response
    end

    def braintree_post(payload, action)
      payload = payload.to_json.to_s
       uri = URI.parse("https://payments.sandbox.braintree-api.com/#{action}")
       req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' => 'application/json', 'Authorization' => 'Bearer sandbox_jhktj9_mj8cfb_8wphf3_xm3r7m_jy4', 'Braintree-Version' => '2016-10-07'})
       req.body = payload

         resp = Net::HTTP.new(uri.host, uri.port)
         resp.use_ssl = true
         resp.ssl_version = 'TLSv1_2'
         resp.verify_mode = OpenSSL::SSL::VERIFY_PEER
         response = resp.start { |http| http.request(req) }

         return response = JSON.parse(response.body)
    end
end
