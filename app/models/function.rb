require "ostruct"

class Function < ApplicationRecord
  validates :name, presence: true
  validates :code, presence: true
  validates :description, presence: true
  validates :tool_type, inclusion: { in: %w[custom system built_in] }
  validates :parameters, presence: true

  belongs_to :workspace
  has_many :agent_functions, dependent: :destroy
  has_many :agents, through: :agent_functions

  scope :enabled, -> { where(enabled: true) }
  scope :for_agent, ->(agent) { joins(:agents).where(agents: { id: agent.id }) }

  after_save :generate_tool_file


  def generate_tool_file
    return if Rails.env.test?

    workspace_folder = File.join(Rails.root, "app", "tool", workspace.name.parameterize)
    FileUtils.mkdir_p(workspace_folder) unless Dir.exist?(workspace_folder)

    template_path = File.join(Rails.root, "app", "tool", "template.txt")
    template_content = File.read(template_path)

    # Generate parameters string for template
    params_string = generate_params_string
    inputs_string = generate_inputs_string

    # Replace template variables
    tool_content = template_content
      .gsub("{{ ClassName }}", name.camelize)
      .gsub("{{ description }}", description)
      .gsub("{{params}}", params_string)
      .gsub("{{inputs}}", inputs_string)
      .gsub("{{code}}", code)

    # Write file
    file_path = File.join(workspace_folder, "#{name.underscore}.rb")
    File.write(file_path, tool_content)
  end

  def generate_params_string
    return "" if parameters.blank?

    param_lines = []
    parameters.each do |key, config|
      type = config["type"] || "string"
      required = config["required"] == true
      description = config["description"] || key.humanize

      param_line = "  parameter :#{key}, type: :#{type}"
      param_line += ", required: true" if required
      param_line += ", description: \"#{description}\""
      param_lines << param_line
    end

    param_lines.join("\n")
  end

  def generate_inputs_string
    return "" if parameters.blank?
    parameters.keys.join(", ")
  end
end
