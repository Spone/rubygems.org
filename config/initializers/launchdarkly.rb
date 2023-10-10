# DEPRECATION WARNING: `Rails.application.secrets` is deprecated in favor of `Rails.application.credentials` and will be removed in Rails 7.2. (called from block in <top (required)> at /Users/segiddins/Development/github.com/rubygems/rubygems.org/config/initializers/launchdarkly.rb:4)
Rails.application.configure do
  ld_config = LaunchDarkly::Config.new(
    logger: SemanticLogger[LaunchDarkly],
    offline: Rails.application.secrets.launch_darkly_sdk_key.blank?
  )

  config.launch_darkly_client = LaunchDarkly::LDClient.new(
    Rails.application.secrets.launch_darkly_sdk_key.to_s,
    ld_config
  )
end
