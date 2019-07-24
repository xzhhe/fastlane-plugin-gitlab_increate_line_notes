require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class GitlabIncreateLineNotesHelper
      # class methods that you define here become available in your action
      # as `Helper::GitlabIncreateLineNotesHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the gitlab_increate_line_notes plugin helper!")
      end
    end
  end
end
