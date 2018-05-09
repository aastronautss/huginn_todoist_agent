# frozen_string_literal: true

require 'huginn_agent'
require 'todoist'

HuginnAgent.load 'huginn_todoist_agent/concerns/todoist_agentable'
HuginnAgent.register 'huginn_todoist_agent/todoist_agent'
HuginnAgent.register 'huginn_todoist_agent/todoist_task_finder_agent'
HuginnAgent.register 'huginn_todoist_agent/todoist_task_complete_agent'
