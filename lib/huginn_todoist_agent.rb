# frozen_string_literal: true

require 'huginn_agent'
require 'todoist'

# HuginnAgent.load 'huginn_todoist_agent/concerns/my_agent_concern'
HuginnAgent.register 'huginn_todoist_agent/todoist_agent'
