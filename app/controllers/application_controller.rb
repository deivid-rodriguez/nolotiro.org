class ApplicationController < ActionController::Base
  # TODO: comment captcha for ad creation/edition
  
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :set_locale
  before_filter :configure_permitted_parameters, if: :devise_controller?

  rescue_from CanCan::AccessDenied do |exception|
    if user_signed_in? 
      redirect_to root_url, :alert => t('nlt.permission_denied')
    else
      redirect_to new_user_session_url, :alert => exception.message
    end
  end

  def access_denied exception
    redirect_to root_url, :alert => exception.message
  end

  def signed_in_root_path(resource)
    woeid = resource.woeid
    return ads_woeid_path(id: woeid, type: 'give') if woeid

    location_ask_path
  end

  def set_locale
    session[:locale] = params[:lang] if valid_locale?(params[:lang])

    I18n.locale =
      params_locale || session_locale || browser_locale || default_locale
  end

  def valid_locale?(code)
    return false unless code.present?

    I18n.available_locales.include?(code.to_sym)
  end

  def params_locale
    params[:locale].presence
  end

  def session_locale
    session[:locale].presence
  end

  def browser_locale
    http_accept_language.compatible_language_from(I18n.available_locales)
  end

  def default_locale
    I18n.default_locale
  end

  def default_url_options(options={})
    #logger.debug "default_url_options is passed options: #{options.inspect}\n"
    { locale: I18n.locale }
  end
  
  def authenticate_active_admin_user!
    authenticate_user!
    unless current_user.admin?
      flash[:alert] = t('nlt.permission_denied')
      redirect_to root_path
    end
  end

  def type_scope
    params[:type] == 'want' ? params[:type] : 'give'
  end

  helper_method :type_scope

  def status_scope
    return 'available' unless %w(booked delivered).include?(params[:status])

    params[:status]
  end

  helper_method :status_scope

  def location_suggest 
    @location_suggest ||= RequestGeolocator.new(request).suggest
  end

  helper_method :location_suggest

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :email, :password, :password_confirmation, :remember_me])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:username, :email, :password, :remember_me])
  end
end
