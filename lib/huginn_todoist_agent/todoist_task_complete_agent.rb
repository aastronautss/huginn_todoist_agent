# frozen_string_literal: true

module Agents
  ##
  # = Huginn Todoist Task Complete Agent
  #
  class TodoistTaskCompleteAgent < Agent
    include FormConfigurable
    include TodoistAgentable

    cannot_create_events!

    description <<~MD
      Completes a task with a given ID. Can either be scheduled or used in conjunction with an agent like `TaskFinderAgent`.
    MD

    default_schedule 'every_1d'

    form_configurable :api_token
    form_configurable :task_id

    def working?
      !recent_error_logs?
    end

    def default_options
      {
        'task_id' => '{{ task_id }}'
      }
    end

    def validate_options
      errors.add(:base, 'task_id must be present') unless options['task_id'].present?

      unless options['api_token'].present? || credential('todoist_api_token').present?
        errors.add(:base, 'you need to specify your Todoist API token or provide a credential named todoist_api_token')
      end
    end

    def check
      complete_item(interpolated['task_id'])
    end

    def receive(incoming_events)
      incoming_events.each { |event| handle_event(event) }
    end

    private

    def handle_event(event)
      interpolate_with(event) { complete_item(interpolated['task_id']) }
    end
  end
end
