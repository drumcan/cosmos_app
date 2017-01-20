class ChargesController < ApplicationController
  def new
    @charge = Charge.new
  end

  def create
    p params
    order_id = rand(36**8).to_s(36)
    amount = "10"
    token = params[:payment_method_token]

    @result = braintree_transaction_create(token, amount, order_id)
    p @result

    @charge = Charge.new
    render :new
  end
end
