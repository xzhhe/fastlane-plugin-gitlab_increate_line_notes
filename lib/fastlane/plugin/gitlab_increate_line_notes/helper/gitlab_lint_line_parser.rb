require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class GitlabLintLine
      attr_accessor(:character, :new_path, :basename, :old_path, :line, :reason, :rule_id, :type, :severity, :commit)
      def initialize(args)
        @character = args['character']
        @new_path = args['new_path']
        @basename = File.basename(@new_path) if @new_path
        @old_path = args['old_path']
        @line = args['line']
        @reason = args['reason']
        @rule_id = args['rule_id']
        @type = args['type']
        @severity = args['severity']
        @commit = args['commit']
      end
  
      # @param position
      # {
      #   "base_sha": "16692b5cfa1d4dba9a6d060368942992ffba3680",
      #   "start_sha": "16692b5cfa1d4dba9a6d060368942992ffba3680",
      #   "head_sha": "6216046ac5a36d0273754c22b06b08236ec6c133",
      #   "old_path": "ZHCoreHybrid/Classes/Haha.swift",
      #   "new_path": "ZHCoreHybrid/Classes/Haha.swift",
      #   "position_type": "text",
      #   "old_line": null,
      #   "new_line": 18
      # }
      def equal_to_position?(position)
        position_base_sha = position['base_sha']
        position_start_sha = position['start_sha']
        position_head_sha = position['head_sha']
        position_old_path = position['old_path']
        position_new_path = position['new_path']
        position_old_line = position['old_line']
        position_new_line = position['new_line']
  
        # puts line == position_new_line
        # puts basename == File.basename(position_new_path)
        # puts commit == position_head_sha
  
        # if line == position_new_line && basename == File.basename(position_new_path) && commit == position_head_sha
        if line == position_new_line && basename == File.basename(position_new_path)
          true
        else
          false
        end
      end
  
      def line_in_positons?(positions)
        positions.each do |position|
          return true if equal_to_position?(position)
        end
        false
      end
  
      def to_discussion
        # eg: "swiftlint|ZHModuleCreationObjecs.swift|Function should have complexity 10 or less: currently complexity equals 11|101|21dc9ccdc021f0f489f9b9fa50b76d60cee3f04e"
        # "swiftlint|%s|%s|%s|%s" % [basename, reason, line, commit]
  
        # 不需要保存 line、basename
        # (line、basename 都可以直接从 note/position/new_line 或 old_line 获取到)
        rule_id_str = rule_id.gsub('_', '-')
        rule_info = "[#{rule_id}](https://github.com/realm/SwiftLint/blob/master/Rules.md##{rule_id_str})"
        "swiftlint|%s|%s|%s" % [reason, rule_info, commit]
      end

      def to_hash
        {
          basename: @basename,
          character: @character,
          commit: @commit,
          line: @line,
          new_path: @new_path,
          old_path: @old_path,
          reason: @reason,
          rule_id: @rule_id,
          severity: @severity,
          type: @type
        }
      end
  
      class << self
        def from_discussion(discussion)
          rt = discussion.match(/swiftlint\|(.*)\|(.*)\|(.*)/)
          return nil unless rt
  
          line = LintLine.new({})
          line.reason = rt[1]
          line.commit = rt[3]
  
          ru_info = rt[2]
          rt2 = ru_info.match(/\[(.*).*\]/)
          line.rule_id = rt2[1]
          
          line
        end
  
        # def from_discussion(discussion)
        #   # str = "swiftlint|ZHModuleCreationObjecs.swift|Function should have complexity 10 or less: currently complexity equals 11|101|21dc9ccdc021f0f489f9b9fa50b76d60cee3f04e"
        #   # rt = str.match(/swiftlint\|(.*)\|(.*)\|(.*)\|(.*)/)
        #   # pp rt[1]  #=> "ZHModuleCreationObjecs.swift"
        #   # pp rt[2]  #=> "Function should have complexity 10 or less: currently complexity equals 11"
        #   # pp rt[3]  #=> "101"
        #   # pp rt[4]  #=> "21dc9ccdc021f0f489f9b9fa50b76d60cee3f04e"
        #   return nil unless discussion
        #
        #   rt = discussion.match(/swiftlint\|(.*)\|(.*)\|(.*)\|(.*)/)
        #   return nil unless rt
        #
        #   line = LintLine.new({})
        #   line.basename = rt[1]
        #   line.reason = rt[2]
        #   line.line = rt[3].to_i
        #   line.commit = rt[4]
        #   line
        # end
      end
    end
    
    class GitlabLintLineParser
      attr_accessor(:lines, :lint_line_jsons, :gitlab_changes_files, :git_commit)
  
      def initialize(lint_line_jsons, gitlab_changes_files, git_commit)
        @lint_line_jsons = lint_line_jsons
        @gitlab_changes_files = gitlab_changes_files
        @git_commit = git_commit
      end
  
      #
      # 从 lint_line_jsons 中【过滤出】gitlab_changes_files 存在修改的 <代码行>
      #
      # - 1) lint_line_jsons: swiftlint.result.json 文件中扫描出的不符合规范的 <代码行>
      # - 2) gitlab_changes_files: MR git commit 对应的所有改动的 <代码行>
      #
      def parse
        return @lines if @lines
  
        @lines = []
        lint_line_jsons.each do |lint|
          lint_file = lint['file'] #=> 绝对路径: /Users/xiongzenghui/ci-jenkins/workspace/xxx-iOS-module/ZHDiagnosisTool/ZHDiagnosisTool/Classes/Core/ProviderContext.swift
          lint_line = lint['line']
  
          # 从 【lint_line_jsons 所有行】中过滤出【gitlab_changes_files 变动行】lint 记录
          gitlab_changes_files.each do |c|
            diff_new_path = c.new_path #=> 相对路径: ZHDiagnosisTool/Classes/Core/ProviderContext.swift
            diff_old_path = c.old_path
  
            next unless lint_file.include?(diff_new_path) #=> 增量 diff
            next unless c.line_numbers.include?(lint_line) #=> change line 发生 lint 事件
  
            # fix path 相对路径
            lint['new_path'] = diff_new_path
            lint['old_path'] = diff_old_path
            lint['commit'] = git_commit
            
            @lines.push(GitlabLintLine.new(lint))
          end
        end
        @lines
      end
    end
  end
end