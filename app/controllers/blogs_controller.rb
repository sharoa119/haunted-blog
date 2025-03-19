# frozen_string_literal: true

class BlogsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show]
  before_action :set_blog, only: %i[show edit update destroy]
  before_action :authorize_user!, only: %i[edit update destroy]
  before_action :require_login_for_secret_blog!, only: %i[show]

  def index
    @blogs = Blog.search(params[:term]).published.default_order
  end

  def show
    redirect_to blogs_path, alert: 'You cannot access this blog.' if @blog.secret? && @blog.user != current_user
  end

  def new
    @blog = Blog.new
  end

  def edit; end

  def create
    @blog = current_user.blogs.new(blog_params)
    @blog.random_eyecatch = params[:blog][:random_eyecatch] if can_use_premium_feature?

    if @blog.save
      redirect_to blog_url(@blog), notice: 'Blog was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    update_params = blog_params
    update_params[:random_eyecatch] = params[:blog][:random_eyecatch] if can_use_premium_feature?

    if @blog.update(update_params)
      redirect_to blog_url(@blog), notice: 'Blog was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @blog.destroy!

    redirect_to blogs_url, notice: 'Blog was successfully destroyed.', status: :see_other
  end

  private

  def set_blog
    @blog = Blog.find(params[:id])
  end

  def authorize_user!
    raise ActiveRecord::RecordNotFound unless @blog.owned_by?(current_user)
  end

  def require_login_for_secret_blog!
    return unless @blog.secret?

    raise ActiveRecord::RecordNotFound if !user_signed_in? || @blog.user != current_user
  end

  def blog_params
    params.require(:blog).permit(:title, :content, :secret)
  end

  def can_use_premium_feature?
    current_user&.premium?
  end
end
