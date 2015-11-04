class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  check_authorization

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, :alert => exception.message
  end

  def current_user
    @current_user ||= session[:user_id] && User.find(session[:user_id])
  end
  helper_method :current_user


  def ensure_logged_in
    current_user || redirect_to(root_path)
  end
  helper_method :ensure_logged_in

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end
  before_action :set_locale

  def login user
    session[:user_id] = user.id
  end

  def logout
    session.clear
  end

  helper_method def filter_present?
    params.has_key? :working_group
  end
end
