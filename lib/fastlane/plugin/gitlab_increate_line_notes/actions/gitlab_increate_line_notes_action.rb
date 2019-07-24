require 'fastlane/action'
require_relative '../helper/gitlab_increate_line_notes_helper'
require_relative '../helper/gitlab_diff_file'
require_relative '../helper/gitlab_lint_line_parser'

module Fastlane
  module Actions
    module SharedValues
      GITLAB_INCREATE_LINE_NOTES_ACTION_NOTES = :GITLAB_INCREATE_LINE_NOTES_ACTION_NOTES
    end

    require 'httparty'
    class GitlabIncreateLineNotesAction < Action
      include(HTTParty)
      
      def self.run(params)
        require 'pp'
        require 'json'
        require 'gitlab'

        gitlab_host = params[:gitlab_host]
        gitlab_token = params[:gitlab_token]
        projectid = params[:projectid]
        mrid = params[:mrid]
        swiftlint_result_json = params[:swiftlint_result_json]
        last_commit = params[:last_commit]

        base_uri(gitlab_host)
        headers('PRIVATE-TOKEN' => gitlab_token)
        gc = Gitlab.client(endpoint: gitlab_host, private_token: gitlab_token)
        mr_hash = gc.merge_request_changes(projectid, mrid).to_hash

        # 1. 当前 mr changes 执行 lint 存在问题的 所有代码行
        lint_lines = merge_request_lint_lines(
          swiftlint_result_json, 
          gitlab_changes_files(mr_hash), 
          last_commit
        )

        # 2. mr 所有带有 position 的 note 评论
        notes = merge_request_position_notes(merge_request_discussions(projectid, mrid))

        # 3. 如果 file - line 已经添加 评论，则不再重复添加
        lint_lines = lint_lines.reject do |ll|
          ll.line_in_positons?(notes)
        end

        lint_lines = lint_lines.map(&:to_hash)
        Actions.lane_context[SharedValues::GITLAB_INCREATE_LINE_NOTES_ACTION_NOTES] = 
        lint_lines
      end

      # MR commit 中【修改】过的【代码行】
      def self.gitlab_changes_files(mr_hash)
        # CI 绝对路径 ==> 相对于 pod 组件仓库 中的路径
        #
        # gitlab merge request changes = [
        #   "AFNeworking/Classes/Views/Animators/CreationPanelV2TransitionAnimator.swift",
        #   "AFNeworking/Classes/Views/Animators/RecommendV2TransitionAnimator.swift"
        # ]
        #
        # swiftlint_result files = [
        #   "/Users/xiongzenghui/ci-jenkins/workspace/xxx-iOS-module/AFNeworking/AFNeworking/Classes/Views/Animators/CreationPanelV2TransitionAnimator.swift",
        #   "/Users/xiongzenghui/ci-jenkins/workspace/xxx-iOS-module/AFNeworking/AFNeworking/Classes/Views/Animators/RecommendV2TransitionAnimator.swift"
        # ]

        changes_hash = mr_hash['changes']

        # changes Hash => changes Model
        changes = []
        changes_hash.each do |c|
          # pp c
          #------------------------------------------------
          # {
          #   "old_path":"AFNeworking/Classes/Commons/AFNeworkingObjecs.m",
          #   "new_path":"AFNeworking/Classes/Commons/AFNeworkingObjecs.m",
          #   "a_mode":"100644",
          #   "b_mode":"100644",
          #   "new_file":false,
          #   "renamed_file":false,
          #   "deleted_file":false,
          #   "diff":"@@ -10,6 +10,8 @@ ... "
          # }
          #------------------------------------------------

          #=> 过滤掉 renamed 和 delete 文件，只保留 new 和 update 文件
          # next if c['renamed_file'] || c['deleted_file']

          git_diff_file = Fastlane::Helper::GitlabDiffFile.new(c['old_path'], c['new_path'], c['diff'])
          changes.push(git_diff_file)
        end
        changes
      end

      # 过滤得到 gitlab merge request 中需要添加 discussion 的 line 代码行
      # - 1) swiftlint result json  => files 1
      # - 2) gitlab changes         => files 2
      # 计算 [swiftlint result json] - [gitlab changes] 差值 = 当前 MR commit swiftlint 存在问题的【所有代码行】
      def self.merge_request_lint_lines(swift_lint_lines, git_changes, last_commit)
        lrp = Fastlane::Helper::GitlabLintLineParser.new(
          swift_lint_lines,
          git_changes,
          last_commit
        )
        lrp.parse
      end

      # 获取 MR 当前所有 discussions
      def self.merge_request_discussions(project_id, mr_iid, per_page = 100)
        self.get("/projects/#{project_id}/merge_requests/#{mr_iid}/discussions?per_page=#{per_page}")
      end

      # 从当前 lint results 中过滤掉【已经】存在的 line note
      def self.merge_request_position_notes(discussions)
        notes = []
        discussions.each_with_index { |discuss, idx|
          # puts "--------- discussion #{idx+1}" + '-' * 30
          ith = discuss.to_hash
          # pp ith

          ith['notes'].each_with_index { |note, iidx|
            # puts "------------------ note #{iidx+1}" + '-' * 30
            iith = note.to_hash
            # pp iith
            # pp iith['body']
            note_type = iith['type']
            note_position = iith['position']
            # pp note_position

            notes << note_position if note_type == 'DiffNote' && note_position
          }
        }
        notes
      end

      def self.description
        "filter gitlab merge request changes files & swiftlint json, last add line code with gitlab discussion"
      end

      def self.authors
        ["xiongzenghui"]
      end

      def self.return_value
        "Array"
      end

      def self.output
        [
          ['GITLAB_INCREATE_LINE_NOTES_ACTION_NOTES', 'gitlab merge request changes swiftlint line notes']
        ]
      end

      def self.details
        "filter gitlab merge request changes files & swiftlint json, last add line code with gitlab discussion"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :gitlab_host,
            description: "your gitlab host"
          ),
          FastlaneCore::ConfigItem.new(
            key: :gitlab_token,
            description: "your gitlab token"
          ),
          FastlaneCore::ConfigItem.new(
            key: :projectid,
            description: "your gitlab project id"
          ),
          FastlaneCore::ConfigItem.new(
            key: :mrid,
            description: "your gitlab merge request id"
          ),
          FastlaneCore::ConfigItem.new(
            key: :swiftlint_result_json,
            description: "swiftlint report json",
            is_string: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :last_commit,
            description: "gitlab merge requst current newest/lastest commit hash",
          )
        ]
      end

      def self.example_code
        [
          'gitlab_increate_line_notes(
            gitlab_host: "https://git.in.xxx.com/api/v4",
            gitlab_token: "xxxx",
            projectid: "16456",
            mrid: "33",
            swiftlint_result_json: JSON.parse(File.read("spec/swiftlint_result_json")),
            last_commit: "dc6b7b2f3875b338b4961eb40c878540be170bd1"
          )
          pp Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::GITLAB_LINT_ADD_DISCUSSIONS_LINE_NOTES]'
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
