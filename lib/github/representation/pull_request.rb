module Github
  module Representation
    class PullRequest < Representation::Issuable
      delegate :user, :repo, :ref, :sha, to: :source_branch, prefix: true
      delegate :user, :exists?, :repo, :ref, :sha, :short_sha, to: :target_branch, prefix: true

      def source_project
        project
      end

      def source_branch_name
        @source_branch_name ||=
          if !opened? && (cross_project? || !source_branch_exists?)
            source_branch_name_prefixed
          else
            source_branch_ref
          end
      end

      def source_branch_exists?
        return @source_branch_exists if defined?(@source_branch_exists)

        @source_branch_exists = repository.branch_exists?(source_branch_name)
      end

      def target_project
        project
      end

      def target_branch_name
        @target_branch_name ||= target_branch_exists? ? target_branch_ref : target_branch_name_prefixed
      end

      def target_branch_exists?
        @target_branch_exists ||= target_branch.exists?
      end

      def state
        return 'merged' if raw['state'] == 'closed' && raw['merged_at'].present?
        return 'closed' if raw['state'] == 'closed'

        'opened'
      end

      def opened?
        state == 'opened'
      end

      def valid?
        source_branch.valid? && target_branch.valid?
      end

      def restore_branches!
        restore_source_branch!
        restore_target_branch!
      end

      private

      def project
        @project ||= options.fetch(:project)
      end

      def source_branch
        @source_branch ||= Representation::Branch.new(raw['head'], repository: project.repository)
      end

      def source_branch_name_prefixed
        "refs/merge-requests/#{pull_request.iid}/head"
      end

      def target_branch
        @target_branch ||= Representation::Branch.new(raw['base'], repository: project.repository)
      end

      def target_branch_name_prefixed
        "gl-#{target_branch_short_sha}/#{iid}/#{target_branch_user}/#{target_branch_ref}"
      end

      def cross_project?
        return true if source_branch_repo.nil?

        source_branch_repo.id != target_branch_repo.id
      end

      def restore_source_branch!
        return if source_branch_exists?

        source_branch.restore!(source_branch_name)
      end

      def restore_target_branch!
        return if target_branch_exists?

        target_branch.restore!(target_branch_name)
      end
    end
  end
end
