# frozen_string_literal: true

class OIDC::ApiKeyRoles::GitHubActionsWorkflowView < ApplicationView
  include Phlex::Rails::Helpers::LinkTo

  attr_reader :api_key_role

  def initialize(api_key_role:)
    @api_key_role = api_key_role
    super()
  end

  def template
    self.title = t(".title")

    return not_github unless api_key_role.provider.github_actions?

    div(class: "t-body") do
      p do
        plain "This OIDC API Key Role is configured to allow pushing "
        link_to gem_name, rubygem_path(gem_name)
        plain " from GitHub Actions."
      end

      p do
        plain "To automate releasing "
        link_to gem_name, rubygem_path(gem_name)
        plain " when a new tag is pushed, add the following workflow to your repository."
      end

      h3(class: "t-list__heading") { code { ".github/workflows/push.yml" } }

      pre do
        code(class: "multiline") do
          workflow_yaml
        end
      end
    end
  end

  private

  def gem_name
    api_key_role.api_key_permissions.gems.first
  end

  def workflow_yaml
    YAML.safe_dump({
      on: { push: { tags: true } },
      jobs: {
        push: {
          "runs-on": "ubuntu-latest"
        },
        permissions: {
          contents: "write",
          "id-token": "write"
        },
        steps: [
          { uses: "rubygems/configure-rubygems-credentials@main",
            with: { "role-to-assume": api_key_role.token, audience: configured_audience }.compact },
          { uses: "actions/checkout@v4" },
          { name: "Set remote URL", run: set_remote_url_run },
          { name: "Set up Ruby", uses: "ruby/setup-ruby@v1", with: { "bundler-cache": true, "ruby-version": "ruby" } },
          { name: "Release", run: "bundle exec rake release" },
          { name: "Wait for release to propagate", run: await_run }
        ]
      }
    }.deep_stringify_keys)
  end

  def set_remote_url_run
    <<~BASH
      # Attribute commits to the last committer on HEAD
      git config --global user.email "$(git log -1 --pretty=format:'%ae')"
      git config --global user.name "$(git log -1 --pretty=format:'%an')"
      git remote set-url origin "https://x-access-token:${{ secrets.GITHUB_TOKEN }}@github.com/$GITHUB_REPOSITORY"
    BASH
  end

  def await_run
    <<~BASH
      gem install rubygems-await
      gem_tuple="$(ruby -rbundler/setup -rbundler -e '
          spec = Bundler.definition.specs.find {|s| s.name == ARGV[0] }
          raise "No spec for \#{ARGV[0]}" unless spec
          print [spec.name, spec.version, spec.platform].join(":")
        ' #{gem_name.dump})"
      gem await "${gem_tuple}"
    BASH
  end

  def not_github
    "This OIDC API Key Role is not configured for GitHub Actions."
  end

  def configured_audience
    auds = api_key_role.access_policy.statements.flat_map do |s|
      next unless s.effect == "allow"

      s.conditions.flat_map do |c|
        c.value if c.claim == "aud"
      end
    end
    auds.compact!
    auds.uniq!

    return unless auds.size == 1
    aud = auds.first
    aud if aud != "rubygems.org" # default in action
  end
end
