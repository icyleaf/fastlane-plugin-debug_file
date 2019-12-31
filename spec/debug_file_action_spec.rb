describe Fastlane::Actions::DebugFileAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The debug_file plugin is working!")

      Fastlane::Actions::DebugFileAction.run(nil)
    end
  end
end
