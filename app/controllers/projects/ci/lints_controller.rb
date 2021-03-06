# frozen_string_literal: true

class Projects::Ci::LintsController < Projects::ApplicationController
  before_action :authorize_create_pipeline!

  def show
  end

  def create
    @content = params[:content]
    @dry_run = params[:dry_run]

    @result = Gitlab::Ci::Lint
      .new(project: @project, current_user: current_user)
      .validate(@content, dry_run: @dry_run)

    respond_to do |format|
      format.html { render :show }
      format.json do
        render json: ::Ci::Lint::ResultSerializer.new.represent(@result)
      end
    end
  end
end
