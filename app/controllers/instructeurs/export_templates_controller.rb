module Instructeurs
  class ExportTemplatesController < InstructeurController
    before_action :set_procedure, :set_groupe_instructeurs, :set_exportable_pjs
    before_action :set_groupe_instructeur, only: [:create, :update, :preview]
    before_action :set_export_template, only: [:edit, :update, :destroy]

    def new
      @export_template = ExportTemplate.new(kind: 'zip', groupe_instructeur: @groupe_instructeurs.first)
      @export_template.set_default_values
    end

    def create
      @export_template = @groupe_instructeur.export_templates.build(export_template_params)

      if @export_template.save
        redirect_to exports_instructeur_procedure_path(procedure: @procedure), notice: "Le modèle d'export #{@export_template.name} a bien été créé"
      else
        flash[:alert] = @export_template.errors.full_messages
        render :new
      end
    end

    def edit
    end

    def update
      @export_template.assign_attributes(export_template_params)
      @export_template.groupe_instructeur = @groupe_instructeur

      if @export_template.save
        redirect_to exports_instructeur_procedure_path(procedure: @procedure), notice: "Le modèle d'export #{@export_template.name} a bien été modifié"
      else
        flash[:alert] = @export_template.errors.full_messages
        render :edit
      end
    end

    def destroy
      if @export_template.destroy
        redirect_to exports_instructeur_procedure_path(procedure: @procedure), notice: "Le modèle d'export #{@export_template.name} a bien été supprimé"
      else
        redirect_to exports_instructeur_procedure_path(procedure: @procedure), alert: "Le modèle d'export #{@export_template.name} n'a pu être supprimé"
      end
    end

    def preview
      @export_template = @groupe_instructeur.export_templates.build(export_template_params)

      @sample_dossier = @procedure.dossier_for_preview(current_instructeur)

      render turbo_stream: turbo_stream.replace('preview', partial: 'preview', locals: { export_template: @export_template, procedure: @procedure, dossier: @sample_dossier })
    end

    private

    def export_template_params
      h = params.require(:export_template)
        .permit(:name, :kind, default_dossier_directory: [:template], export_pdf: [:enabled, :template], pjs: [:stable_id, :enabled, :template]).to_h

      [h[:default_dossier_directory], h[:export_pdf], *h[:pjs]].each { cast_in_json(_1) }

      # default_dossier_directory is always enabled
      h[:default_dossier_directory][:enabled] = true

      pj_stable_ids = @exportable_pjs.map { _1.stable_id.to_s }
      h[:pjs] = h[:pjs].filter { _1[:stable_id].in?(pj_stable_ids) }

      h
    end

    def cast_in_json(h)
      h[:template] = JSON.parse(h[:template]) if h[:template].present?
      h[:enabled] = h[:enabled] == 'true'
    end

    def set_procedure
      @procedure = current_instructeur.procedures.find(params[:procedure_id])
      Sentry.configure_scope { |scope| scope.set_tags(procedure: @procedure.id) }
    end

    def set_export_template
      @export_template = current_instructeur.export_templates.find(params[:id])
    end

    def set_groupe_instructeur
      @groupe_instructeur = @procedure.groupe_instructeurs.find(params.require(:export_template)[:groupe_instructeur_id])
    end

    def set_groupe_instructeurs
      @groupe_instructeurs = current_instructeur.groupe_instructeurs.where(procedure: @procedure)
    end

    def set_exportable_pjs
      @exportable_pjs = @procedure.exportables_pieces_jointes
    end
  end
end
