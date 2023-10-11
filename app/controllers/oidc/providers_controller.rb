# frozen_string_literal: true

class OIDC::ProvidersController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?
  before_action :find_provider, only: :show

  def index
    render OIDC::Providers::IndexView.new(providers: OIDC::Provider.all)
  end

  def show
    render OIDC::Providers::ShowView.new(provider: @provider)
  end

  private

  def find_provider
    @provider = OIDC::Provider.find(params.require(:id))
  end
end
