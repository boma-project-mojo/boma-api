class Api::V1::ActivitiesController < ApplicationController
  skip_before_action :verify_authenticity_token, :authenticate_user!
  
  # Create or update an Activity row for an addresss which stores the aggregated activity this address has completed for this festival.  
  # DEPRECATED in favour of 'report_activity_for_all_festivals', left for backwards compatibility.  
  def report_activity
		@activity = Activity.where(address_id: activity_params[:address_id]).where(festival_id: activity_params[:festival_id]).where(activity_type: activity_params[:activity_type]).first_or_initialize

		@activity.app_version = activity_params[:app_version]
		@activity.timezone = activity_params[:timezone]
		@activity.organisation_id = activity_params[:organisation_id]

		@activity.reported_data = JSON.parse(activity_params[:reported_data])

    if @activity.save
      render json: {success: true}
    else
      render json: {success: false}, status: :unprocessable_entity
    end
  end

  # Create or update an Activity row for an addresss which stores the aggregated activity this address has completed for all festivals stored in the app.  
  def report_activity_for_all_festivals
    activities = []

    begin
      activity_params[:activities].each do |activity|
        @activity = Activity.where(address_id: activity_params[:address_id]).where(festival_id: activity[1][:festival_id]).where(activity_type: activity_params[:activity_type]).first_or_initialize

        @activity.app_version = activity_params[:app_version]
        @activity.timezone = activity_params[:timezone]
        @activity.organisation_id = activity_params[:organisation_id]
        @activity.reported_data = JSON.parse(activity[1][:reported_data])

        activities << @activity
      end

      Activity.transaction do
        activities.each do |a|
          a.save if a.valid?
        end
      end

      render json: {success: true}
    rescue *[JSON::ParserError, ActiveRecord::RecordInvalid, NoMethodError] => exception
      render json: {success: false}, status: :unprocessable_entity
    end
  end

  private

    def activity_params
      params[:address_id] = Address.find_by_address(params[:address]).id rescue nil
      params.permit(:address_id, :app_version, :timezone, :festival_id, :activity_type, :reported_data, :organisation_id, activities: [:festival_id, :reported_data])
    end
end