require 'net/http'
require 'uri'
require 'webrick'
require 'webrick/https'
require 'openssl'
require 'json'

class UsersController < ApplicationController
  before_action :signed_in_user, only: [:index, :edit, :update, :destroy, :transactions, :refund]
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
      @transaction.transaction_type = "charge"
      @transaction.save

      update_balance(@user, result)

      redirect_to @user
    else
      session[:errors] = result["error"]["user_message"]
      redirect_to @user
    end
  end

  def refund
    @user = current_user
    transaction_id = params[:transaction_id]


    result = braintree_credit_create(transaction_id)
    p result

    if result["data"]["status"] == "PENDING"
      @transaction = Transaction.new
      @transaction.transaction_id = result["data"]["id"]
      @transaction.amount = result["data"]["amount"]
      @transaction.status = result["data"]["status"]
      @transaction.refunded_transaction_id = params[:transaction_id]
      @transaction.transaction_type = "credit"
      @transaction.user_id = @user.id
      @transaction.save

      @orig_trans = Transaction.find_by transaction_id: params[:transaction_id]
      p @orig_trans
      @orig_trans.update_attribute(:refunded, true)



      @user.update_attribute(:balance, (@user.balance.to_f - 10).to_s)
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


  def update_balance(user, result)

    balance = (user.balance.to_f + result["data"]["amount"].to_f).to_s
    user.update_attribute(:balance, balance)
  end
end
