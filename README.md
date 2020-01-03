# debug_file plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-debug_file)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-debug_file`, add it to your project by running:

```bash
fastlane add_plugin debug_file
```

## About debug_file

debug_file plugin includes two actions:

- `dsym`: Find iOS/macOS app dSYM and compress automatically
- `proguard`: Find Android proguard and compress automatically

### dsym

Why another `dsym` action? fastlane was built-in simlar action named [dsym_zip](https://docs.fastlane.tools/actions/dsym_zip/) which it only accepts spetical path, our `dsym` it counld find dSYM
file automatically, even accpets multiple dSYM to compress.

### proguard

If Android app set `minifyEnabled = true`, it called proguard, `proguard` could find `mapping.txt`,
`R.txt` and `AndroidManifest.xml` automatically.

## Example

Check out the [example `Fastfile`](fastlane/Fastfile) to see how to use this plugin. Try it by cloning the repo, running `fastlane install_plugins` and `bundle exec fastlane test`.

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
