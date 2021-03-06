# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CI YML Templates' do
  subject { Gitlab::Ci::YamlProcessor.new(content).execute }

  let(:all_templates) { Gitlab::Template::GitlabCiYmlTemplate.all.map(&:full_name) }

  let(:disabled_templates) do
    Gitlab::Template::GitlabCiYmlTemplate.disabled_templates.map do |template|
      template + Gitlab::Template::GitlabCiYmlTemplate.extension
    end
  end

  context 'included in a CI YAML configuration' do
    using RSpec::Parameterized::TableSyntax

    where(:template_name) do
      all_templates - disabled_templates
    end

    with_them do
      let(:content) do
        <<~EOS
          include:
            - template: #{template_name}

          concrete_build_implemented_by_a_user:
            stage: test
            script: do something
        EOS
      end

      it 'is valid' do
        expect(subject).to be_valid
      end

      it 'require default stages to be included' do
        expect(subject.stages).to include(*Gitlab::Ci::Config::Entry::Stages.default)
      end
    end
  end
end
