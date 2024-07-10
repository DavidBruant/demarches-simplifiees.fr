describe ExportItem do
  let(:export_item) { described_class.new('template' => template) }
  let(:template) { nil }

  describe '.leaves' do
    subject { export_item.send(:leaves) }

    context 'with a string' do
      let(:template) { 'invalid' }

      it { is_expected.to eq([]) }
    end

    context 'with a well formed tiptap content' do
      let(:template) do
        {
          "content" => [{ 'content' => [:leaf_1, :leaf_2] }, { 'content' => [:leaf_3] }]
        }
      end

      it { is_expected.to eq([:leaf_1, :leaf_2, :leaf_3]) }
    end
  end

  describe '.texts' do
    before { allow(export_item).to receive(:leaves).and_return(leaves) }

    subject { export_item.send(:texts) }

    context 'with some text' do
      let(:leaves) { [{ 'type' => 'text', 'text' => 'hello' }, { 'type' => 'mention' }] }

      it { is_expected.to eq(['hello']) }
    end

    context 'with a empty text' do
      let(:leaves) { [{ 'type' => 'text', 'text' => '' }] }

      it { is_expected.to eq([]) }
    end
  end
end
