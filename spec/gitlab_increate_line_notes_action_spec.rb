describe Fastlane::Actions::GitlabIncreateLineNotesAction do
  describe '#run' do
    it 'prints a message' do
      require 'json'

      Fastlane::Actions::GitlabIncreateLineNotesAction.run(
        gitlab_host: 'https://git.in.xxxx.com/api/v4',
        gitlab_token: 'xxxx',
        projectid: "16456",
        mrid: "33",
        swiftlint_result_json: JSON.parse(File.read('spec/swiftlint_result_json')),
        last_commit: "dc6b7b2f3875b338b4961eb40c878540be170bd1"
      )
      pp Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::GITLAB_INCREATE_LINE_NOTES_ACTION_NOTES]
    end
  end
end
