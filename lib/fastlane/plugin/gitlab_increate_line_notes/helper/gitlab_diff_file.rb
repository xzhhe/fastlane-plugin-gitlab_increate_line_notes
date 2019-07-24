require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class GitlabDiffLine
      attr_accessor(:content, :line, :patch_position)
      def initialize(ctt, nbr, ppn)
        @content = ctt
        @line = nbr
        @patch_position = ppn
      end
    end

    class GitlabDiffFile
      require 'git_diff_parser'
      attr_accessor(:old_path, :new_path, :lines, :line_numbers)
      
      def initialize(oth, nth, diff)
        @old_path = oth
        @new_path = nth

        patch = GitDiffParser::Patch.new(diff)
        return unless patch

        @lines = patch.changed_lines.map do |git_diff_line|
          # #<GitDiffParser::Line:0x00007fd3cdb40ca0
          #   @content="+\n",
          #   @number=66,
          #   @patch_position=5>
          GitlabDiffLine.new(git_diff_line.content, git_diff_line.number, git_diff_line.patch_position)
        end

        @line_numbers = @lines.map(&:line)
      end
    end

    
  end
end
