module Admin
  module Resourceful
    extend ActiveSupport::Concern

    included do
      class_attribute :admin_resource_key
      helper_method :admin_record_path, :resource
    end

    class_methods do
      def admin_resource(key)
        self.admin_resource_key = key
      end
    end

    def index
      @records = resource.model_class.order(id: :desc)
      render "admin/resourceful/index"
    end

    def show
      @record = find_record
      render "admin/resourceful/show"
    end

    def new
      @record = resource.model_class.new
      render "admin/resourceful/new"
    end

    def create
      @record = resource.model_class.new(resource_params)
      if @record.save
        redirect_to admin_record_path(@record), notice: t("admin.flash.created")
      else
        flash.now[:alert] = t("admin.flash.create_failed")
        render "admin/resourceful/new", status: :unprocessable_entity
      end
    end

    def edit
      @record = find_record
      render "admin/resourceful/edit"
    end

    def update
      @record = find_record
      if @record.update(resource_params)
        redirect_to admin_record_path(@record), notice: t("admin.flash.updated")
      else
        flash.now[:alert] = t("admin.flash.update_failed")
        render "admin/resourceful/edit", status: :unprocessable_entity
      end
    end

    def destroy
      @record = find_record
      @record.destroy!
      redirect_to resource.admin_index_path(helpers), notice: t("admin.flash.destroyed")
    end

    private

    def resource
      @resource ||= Admin::Resource.new(Admin::Resource.find(admin_resource_key))
    end

    def find_record
      resource.model_class.find(params[:id])
    end

    def admin_record_path(record)
      resource.admin_path(record, helpers)
    end

    def resource_params
      params.require(resource.singular_route_key).permit(*resource.writable_columns)
    end
  end
end
