# frozen_string_literal: true

class ApplicationComponent < Phlex::HTML
  include Phlex::Rails::Helpers::Routes
  include Phlex::Translation

  def self.translation_path
    @translation_path ||= name&.dup.tap do |n|
      n.gsub!(/(::[^:]+)View/, '\1')
      n.gsub!("::", ".")
      n.gsub!(/([a-z])([A-Z])/, '\1_\2')
      n.downcase!
    end
  end

  alias t translate
  private :t

  if Rails.env.development?
    def before_template
      comment { "Before #{self.class.name}" }
      super
    end
  end
end
