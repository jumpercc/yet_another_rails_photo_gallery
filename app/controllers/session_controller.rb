class SessionController < ApplicationController
  skip_before_filter :authorize_admin, :only => [
    :login, :set_locale, :set_image_size, :set_lists_order
  ]
  before_filter :html_gui, :only => []

  def login
    if params[:login].nil? || params[:login].empty? \
    || params[:password].nil? || params[:password].empty?
      render :json => { code: 409, error: I18n.t('error.no_parameters') }
    else
      user = User.find_by_name( params[:login] )
      if user.nil? || user.password_hash != User.hash_password( params[:password], user.salt )
        render :json => { code: 403, error: I18n.t('error.wrong_password') }
      else
        cookies.signed[:user] = {
          value: user.name,
          secure: !Rails.env.development?,
        }
        render :json => { code: 200 }
      end
    end
  end

  def logout
    if cookies.signed[:user].nil?
      redirect_to root_url
      render :json => { code: 403, error: I18n.t('error.not_signed_in') }
    else
      cookies.delete :user
      render :json => { code: 200 }
    end
  end

  def set_locale
    alert = nil
    if params[:locale].nil? || params[:locale].empty?
      alert = I18n.t('error.no_parameters')
    elsif !I18n.available_locales.include? params[:locale].to_sym
      alert = I18n.t('error.unknown_locale')
    else
      request.session[:locale] = params[:locale].to_sym
      I18n.locale = request.session[:locale]
    end
    redirect_back_with_hash(alert)
  end

  def set_image_size
    alert = nil
    if params[:image_size].nil? || params[:image_size].empty?
      alert = I18n.t('error.no_parameters')
    elsif !@all_image_sizes.include? params[:image_size]
      alert = I18n.t('error.wrong_image_size')
    else
      request.session[:image_size] = params[:image_size]
      @image_size = request.session[:image_size]
    end
    redirect_back_with_hash(alert)
  end

  def set_lists_order
    alert = nil
    if params[:lists_order].nil? || params[:lists_order].empty?
      alert = I18n.t('error.no_parameters')
    elsif !@all_lists_orders.include? params[:lists_order]
      alert = I18n.t('error.wrong_lists_order')
    else
      request.session[:lists_order] = params[:lists_order]
      @lists_order = request.session[:lists_order]
    end
    redirect_back_with_hash(alert)
  end

  private

  def redirect_back_with_hash(alert)
    if params[:hash].nil? || params[:hash].empty?
      url = request.env["HTTP_REFERER"] || root_url
    else
      url = root_url + "#" + URI::escape( params[:hash] )
    end
    redirect_to( url, :alert => alert )
  end
end
