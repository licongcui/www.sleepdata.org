class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  after_filter :store_location

  def store_location
    if (params[:action] != 'logo' &&
        params[:action] != 'files' &&
        params[:action] != 'variable_chart' &&
        params[:action] != 'images' &&
        !request.fullpath.match("#{request.script_name}/users/login") &&
        !request.fullpath.match("#{request.script_name}/users/register") &&
        !request.fullpath.match("#{request.script_name}/users/password") &&
        !request.fullpath.match("#{request.script_name}/users/sign_out") &&
        !request.fullpath.match("#{request.script_name}/auth/") &&
        !request.xhr?) # don't store ajax calls
      store_location_in_session
    end
  end

  def after_sign_in_path_for(resource)
    add_list_to_user
    session[:previous_url] || root_path
  end

  def after_sign_out_path_for(resource_or_scope)
    cookies.delete(:list_id)
    session[:previous_url] || root_path
  end

  protected

  def store_location_in_session
    session[:previous_url] = request.fullpath
  end

  def add_list_to_user
    list = List.find_by_id( cookies.signed[:list_id] )
    if list
      list.update_attributes user_id: current_user.id
    elsif current_user.lists.count > 0
      cookies.signed[:list_id] = current_user.lists.last.id
    end
  end

  def check_system_admin
    redirect_to root_path, alert: "You do not have sufficient privileges to access that page." unless current_user.system_admin?
  end

  def empty_response_or_root_path(path = root_path)
    respond_to do |format|
      format.html { redirect_to path }
      format.js { render nothing: true }
      format.json { head :no_content }
      format.text { render nothing: true }
    end
  end

  def authenticate_user_from_token!
    (user_id, auth_token) = params[:auth_token].to_s.split('-')
    user                  = user_id && User.find_by_id(user_id)

    # Notice how we use Devise.secure_compare to compare the token
    # in the database with the token given in the params, mitigating
    # timing attacks.
    if user && Devise.secure_compare(user.authentication_token, auth_token)
      sign_in user, store: false
    end
  end

end
