require 'net/http'
require 'uri'
require 'webrick'
require 'webrick/https'
require 'openssl'
require 'json'

class UsersController < ApplicationController
  before_action :signed_in_user, only: [:index, :edit, :update, :destroy, :transactions]
  before_action :correct_user, only: [:edit, :update]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    result = braintree_token_create(params[:payment_method_token])

    if result["meta"]["verification"]["success"] == true
    @user.payment_token = result["data"]["id"]
    @user.first_six = result["data"]["bin"]
    @user.last_four = result["data"]["last_4"]
    @user.cart_type = result["data"]["brand"]
    @user.balance = "0"
  	if @user.save
  	  sign_in @user
      flash[:success] = "Welcome to the Sample App!"
      redirect_to @user
    else
      render 'new'
    end
  else
    session[:errors] = result["error"]["user_message"]
    redirect_to '/signup'
  end
end

  def show
    @user = User.find(params[:id])
    @transaction = Transaction.new
    @transactions = Transaction.where(user_id: @user.id).order(:created_at)
    p @transaction
  end

  def current_user=(user)
    @current_user = user
  end

  def transactions
    @user = current_user
    order_id = rand(36**8).to_s(36)
    amount = "10"
    token = @user.payment_token

    result = braintree_transaction_create(token, amount, order_id)

    if result["data"]["status"] == "PENDING"
      @transaction = Transaction.new
      @transaction.transaction_id = result["data"]["id"]
      @transaction.amount = result["data"]["amount"]
      @transaction.status = result["data"]["status"]
      @transaction.order_id = result["data"]["order_id"]
      @transaction.user_id = @user.id
      @transaction.save

      update_balance(@user, result)

      redirect_to @user
    else
      session[:errors] = result["error"]["user_message"]
      redirect_to @user
    end
  end

private

  def correct_user
      @user = User.find(params[:id])
      redirect_to(root_url) unless current_user?(@user)
  end

  def user_params
  	params.require(:user).permit(:name, :email, :password, :password_confirmation)
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

  def update_balance(user, result)

    balance = (user.balance.to_f + result["data"]["amount"].to_f).to_s
    user.update_attribute(:balance, balance)
  end
end
