# frozen_string_literal: true

module Maintenance
  class CreatePreviewsForPjsFromMessagerieTask < MaintenanceTasks::Task
    attribute :start_text, :string
    validates :start_text, presence: true

    attribute :end_text, :string
    validates :end_text, presence: true

    def collection
      start_date = DateTime.parse(start_text)
      end_date = DateTime.parse(end_text)

      Dossier
        .state_en_construction_ou_instruction
        .where(depose_at: start_date..end_date)
    end

    def process(dossier)
      commentaire_ids = Commentaire
        .where(dossier_id: dossier)
        .pluck(:id)

      attachments = ActiveStorage::Attachment
        .where(record_id: commentaire_ids)

      attachments.each do |attachment|
        next if !(attachment.previewable? && attachment.representation_required?)
        attachment.preview(resize_to_limit: [400, 400]).processed unless attachment.preview(resize_to_limit: [400, 400]).image.attached?
      rescue MiniMagick::Error
      end
    end
  end
end
