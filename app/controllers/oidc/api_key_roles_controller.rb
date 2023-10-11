class OIDC::ApiKeyRolesController < ApplicationController
  include ApiKeyable

  helper RubygemsHelper

  before_action :redirect_to_signin, unless: :signed_in?
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?
  before_action :redirect_to_settings_strong_mfa_required, if: :mfa_required_weak_level_enabled?
  before_action :redirect_to_verify, unless: :password_session_active?
  before_action :find_api_key_role, except: %i[index new create]

  def index
    @api_key_roles = current_user.oidc_api_key_roles.strict_loading.includes(:provider)
  end

  def show
  end

  def github_actions_workflow
    render OIDC::ApiKeyRoles::GitHubActionsWorkflowView.new(api_key_role: @api_key_role)
  end

  def new
    rubygem = Rubygem.find_by(name: params[:rubygem])
    scopes = params.permit(scopes: []).fetch(:scopes, [])
    @api_key_role = current_user.oidc_api_key_roles.build
    @api_key_role.name = "Push #{rubygem.name}" if rubygem
    @api_key_role.api_key_permissions = OIDC::ApiKeyPermissions.new(
      gems: rubygem ? [rubygem.name] : [],
      scopes: scopes
    )

    condition = OIDC::AccessPolicy::Statement::Condition.new
    statement = OIDC::AccessPolicy::Statement.new(conditions: [condition])
    add_default_params(rubygem, statement, condition)

    @api_key_role.access_policy = OIDC::AccessPolicy.new(statements: [statement])
  end

  def edit
  end

  def create
    @api_key_role = current_user.oidc_api_key_roles.build(api_key_role_params)
    if @api_key_role.save
      redirect_to profile_oidc_api_key_role_path(@api_key_role.token), flash: { notice: t(".success") }
    else
      flash.now[:error] = @api_key_role.errors.full_messages.to_sentence
      render :new
    end
  end

  def update
    if @api_key_role.update(api_key_role_params)
      redirect_to profile_oidc_api_key_role_path(@api_key_role.token), flash: { notice: t(".success") }
    else
      flash.now[:error] = @api_key_role.errors.full_messages.to_sentence
      render :edit
    end
  end

  private

  def find_api_key_role
    @api_key_role = current_user.oidc_api_key_roles
      .includes(id_tokens: { api_key: nil }, provider: nil).strict_loading
      .find_by!(token: params.require(:token))
  end

  def redirect_to_verify
    session[:redirect_uri] = request.path_info
    redirect_to verify_session_path
  end

  def api_key_role_params
    params.require(:oidc_api_key_role).permit(
      :name, :oidc_provider_id,
      api_key_permissions: [{ scopes: [] }, :valid_for, { gems: [] }],
      access_policy: {
        statements_attributes: [:effect, { principal: :oidc },
                                { conditions_attributes: %i[operator claim value] }]
      }
    )
  end

  def add_default_params(rubygem, statement, condition)
    condition.claim = "aud"
    condition.operator = "string_equals"
    condition.value = Gemcutter::HOST

    return unless rubygem
    return unless (gh = helpers.link_to_github(rubygem)).presence
    return unless (@api_key_role.provider = OIDC::Provider.github_actions)

    statement.principal = { oidc: @api_key_role.provider.issuer }

    repo_condition = OIDC::AccessPolicy::Statement::Condition.new(
      claim: "repository",
      operator: "string_equals",
      value: gh.path.split("/")[1, 2].join("/")
    )
    statement.conditions << repo_condition
  end
end
