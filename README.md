# gitlab_increate_line_notes plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-gitlab_increate_line_notes)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-gitlab_increate_line_notes`, add it to your project by running:

```bash
fastlane add_plugin gitlab_increate_line_notes
```

## About gitlab_increate_line_notes

**Note to author:** Add a more detailed description about this plugin here. If your plugin contains multiple actions, make sure to mention them here.

## Example

Check out the [example `Fastfile`](fastlane/Fastfile) to see how to use this plugin. Try it by cloning the repo, running `fastlane install_plugins` and `bundle exec fastlane test`.

```ruby
gitlab_increate_line_notes(
  gitlab_host: "https://git.in.xxx.com/api/v4",
  gitlab_token: "xxxx",
  projectid: "16456",
  mrid: "33",
  swiftlint_result_json: JSON.parse(File.read('spec/swiftlint_result_json')),
  last_commit: "dc6b7b2f3875b338b4961eb40c878540be170bd1"
)
pp Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::GITLAB_LINT_ADD_DISCUSSIONS_LINE_NOTES]
```

![](Snip20190726_7.png)

## Run tests for this plugin

To run both the tests, and code style validation, run

```
rake
```

To automatically fix many of the styling issues, use
```
rubocop -a
```

## Issues and Feedback

For any other issues and feedback about this plugin, please submit it to this repository.

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
