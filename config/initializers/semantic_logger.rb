SemanticLogger.application = "rubygems.org"

module SemanticLoggerFix
  def silenced?(event)
    case logger
    when nil
      true
    when SemanticLogger::Logger
      logger.send(:level_index) - 1 > @event_levels.fetch(event, Float::INFINITY)
    when ActiveSupport::BroadcastLogger
      level = logger.broadcasts.map { |b| b.send(:level_index) }.min - 1
      level > @event_levels.fetch(event, Float::INFINITY)
    else
      super
    end
  end
end

ActiveSupport::LogSubscriber.prepend(SemanticLoggerFix)

ActiveSupport.on_load(:action_controller) do
  def append_info_to_payload(payload)
    payload.merge!(
      timestamp: Time.now.utc,
      env: Rails.env,
      network: {
        client: {
          ip: request.ip
        }
      }
    )
    super
    payload[:rails] = {
      controller: payload.fetch(:controller),
      action: payload.fetch(:action),
      params: request.filtered_parameters.except('controller', 'action', 'format', 'utf8'),
      format: payload.fetch(:format),
      view_time_ms: payload.fetch(:view_runtime, 0.0),
      db_time_ms: payload.fetch(:db_runtime, 0.0)
    }
    payload[:http] = {
      request_id: request.uuid,
      method: request.method,
      status_code: response.status,
      response_time_ms: request.url,
      useragent: request.user_agent,
      url: request.url
    }

    method_and_path = [request.method, request.path].select(&:present?)
    method_and_path_string = method_and_path.empty? ? ' ' : " #{method_and_path.join(' ')} "

    payload[:message] ||= "[#{response.status}]#{method_and_path_string}(#{payload.fetch(:controller)}##{payload.fetch(:action)})"
  end
end

class SemanticErrorSubscriber
  include SemanticLogger::Loggable
  def report(error, handled:, severity:, context:, source: nil)
    logger.send severity.to_s.sub(/ing$/, ''), { exception: error, handled:, context:, source: }
  end
end

Rails.error.subscribe(SemanticErrorSubscriber.new)
