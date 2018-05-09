# frozen_string_literal: true

module Agents
  ##
  # = Huginn Todoist Task Finder Agent
  #
  class TodoistTaskFinderAgent < Agent
    include FormConfigurable
    include TodoistAgentable

    description <<~MD
      Finds tasks based on a given set of criteria. Creates an event for each task found, optionally merged with the incoming event's payload. You may match against one or more of:

      1. The item's content, using a regex (`regex` field)
      2. The item's due date, using a string that can be parsed using Ruby's `Date.parse` method (`due_date` field)
      3. The item's labels, using a comma-separated list of label names (`labels` field)

      Future versions of this will hopefully be able to use Todoist's filter query syntax, but for now no such API
      exists to make use of that.
    MD

    default_schedule 'every_1d'

    form_configurable :api_token
    form_configurable :id_key

    form_configurable :regex
    form_configurable :due_date
    form_configurable :labels

    form_configurable :merge

    def working?
      !recent_error_logs?
    end

    def default_options
      {
        'id_key' => 'task_id',
        'merge' => 'true'
      }
    end

    def validate_options
      errors.add(:base, 'you must provide a regex, due date, or label(s)') unless at_least_one_parameter?
      errors.add(:base, 'merge must be present') unless options['merge'].present?
      errors.add(:base, 'id_key must be present') unless options['id_key'].present?

      unless options['api_token'].present? || credential('todoist_api_token').present?
        errors.add(:base, 'you need to specify your Todoist API token or provide a credential named todoist_api_token')
      end
    end

    def check
      handle_matching_items
    end

    def receive(incoming_events)
      incoming_events.each { |event| handle_event(event) }
    end

    private

    def at_least_one_parameter?
      options['regex'].present? || options['due_date'].present? || options['labels'].present?
    end

    def handle_event(event)
      interpolate_with(event) { handle_matching_items(event) }
    end

    def handle_matching_items(event = nil)
      matching_items.each { |item| handle_item(item, event) }
    end

    def matching_items
      items.select { |item| matching_item?(item) }
    end

    def matching_item?(item)
      matching_regex?(item) && matching_due_date?(item) && matching_labels?(item)
    end

    def matching_regex?(item)
      regex_str = interpolated['regex']

      return true unless regex_str.present?

      regex = Regexp.new(regex_str)
      regex =~ item.content
    end

    def matching_due_date?(item)
      due_date = interpolated['due_date']

      return true unless due_date.present?
      return false if item.due_date_utc.nil?

      target_date = Time.zone.parse(due_date).at_midnight
      item_date = Time.zone.parse(item.due_date_utc).at_midnight

      target_date == item_date
    end

    def matching_labels?(item)
      labels = interpolated['labels']

      return true unless labels.present?

      target_ids = label_ids_for(labels)
      target_ids.all? { |target_id| target_id.to_i.in?(item.labels) }
    end

    def handle_item(item, event)
      output = { interpolated['id_key'] => item.id }
      output.reverse_merge!(event.payload) if boolify(interpolated['merge']) && event.present?

      create_event payload: output
    end
  end
end
