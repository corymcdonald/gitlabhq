# frozen_string_literal: true

module Terraform
  class State < ApplicationRecord
    include UsageStatistics
    include FileStoreMounter

    DEFAULT = '{"version":1}'.freeze
    HEX_REGEXP = %r{\A\h+\z}.freeze
    UUID_LENGTH = 32

    belongs_to :project
    belongs_to :locked_by_user, class_name: 'User'

    validates :project_id, presence: true
    validates :uuid, presence: true, uniqueness: true, length: { is: UUID_LENGTH },
              format: { with: HEX_REGEXP, message: 'only allows hex characters' }

    default_value_for(:uuid, allows_nil: false) { SecureRandom.hex(UUID_LENGTH / 2) }

    mount_file_store_uploader StateUploader

    default_value_for(:file) { CarrierWaveStringFile.new(DEFAULT) }

    def file_store
      super || StateUploader.default_store
    end

    def local?
      file_store == ObjectStorage::Store::LOCAL
    end

    def locked?
      self.lock_xid.present?
    end
  end
end

Terraform::State.prepend_if_ee('EE::Terraform::State')
