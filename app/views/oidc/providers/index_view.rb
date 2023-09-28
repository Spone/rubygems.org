# frozen_string_literal: true

class OIDC::Providers::IndexView < ApplicationView
  include Phlex::Rails::Helpers::LinkTo

  attr_reader :providers

  def initialize(providers:)
    @providers = providers
    super()
  end

  def template
    self.title = t(".title")

    div(class: "t-body") do
      p do
        plain "These are the OIDC providers that have been configured for RubyGems.org."
        br
        plain "Please reach out to support if you need another OIDC Provider added."
      end
      hr
      ul do
        providers.each do |provider|
          li { link_to provider.issuer, profile_oidc_provider_path(provider) }
        end
      end
    end
  end
end
