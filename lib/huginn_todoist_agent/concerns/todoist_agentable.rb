# frozen_string_literal: true

##
# A mixin for adding Todoist API functionality to Huginn agents.
#
module TodoistAgentable
  extend ActiveSupport::Concern

  included do
    gem_dependency_check { defined?(Todoist::Client) }
  end

  def todoist
    @todoist ||= Todoist::Client.create_client_by_token(
      interpolated['api_token'].present? ? interpolated['api_token'] : credential('todoist_api_token')
    )
  end

  def items
    @items ||= todoist.sync_items.collection.values
  end

  def add_item(item_params)
    todoist.sync_items.add(item_params)
    todoist.sync
  end

  def labels
    @labels ||= todoist.sync_labels.collection.values
  end

  def label_ids_for(label_list)
    label_names = label_list.split(/,\s*/)
    label_names.map { |label_name| label_id_for(label_name) }.compact
  end

  def label_id_for(label_name)
    labels.find { |label| label.name == label_name }.try(:id)
  end
end
