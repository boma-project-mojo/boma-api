class AdminApi::V1::ActivitiesController < AdminApi::V1::AdminApiController

  before_action :set_from_and_to

  def index
    sds = StatsDisplayService.new(activity_params[:festival_id], @from, @to, @time_config)
    
    render json: {
      total_users: OrganisationAddress.where(organisation_id: Festival.find(activity_params[:festival_id]).organisation_id).count,
      app_versions: sds.app_versions(activity_params[:festival_id], @from, @to, @time_config),
      main_chart: sds.stats_for_main_chart(activity_params[:festival_id], @from, @to, @time_config),
      stats_by_model_type_for_chart: sds.stats_by_model_type_for_chart(activity_params[:festival_id], @from, @to, @time_config),
      stat_types_by_tag_for_chart: sds.stat_types_by_tag_for_chart(activity_params[:festival_id], @from, @to, @time_config),
      stats_for_users: sds.stats_for_users(activity_params[:festival_id], @from, @to, @time_config),
      notifications_and_publishing: sds.notifications_and_publishing(activity_params[:festival_id], @from, @to, @time_config),
      counts: sds.cumulative_stats_report(activity_params[:festival_id]),
    }
  end

  # The following actions are deprecated since implementing the one line per period stats_cache method
  # Retained for reference in future.

  # def stats_for_main_chart
  #   main = StatsDisplayService.stats_for_main_chart(activity_params[:festival_id], @from, @to, @time_config)

  #   render json: main.to_json
  # end

  # def stats_by_model_type_for_chart
  #   model_type = StatsDisplayService.stats_by_model_type_for_chart(activity_params[:festival_id], @from, @to, @time_config)
    
  #   render json: model_type
  # end

  # def stat_types_by_tag_for_chart
  #   tag = StatsDisplayService.stat_types_by_tag_for_chart(activity_params[:festival_id], @from, @to, @time_config)
  #   render json: tag
  # end

  # def stats_for_users
  #   users = StatsDisplayService.stats_for_users(activity_params[:festival_id], @from, @to, @time_config)
    
  #   render json: users
  # end

  # def notifications_and_publishing
  #   notifications_and_publishing = StatsDisplayService.notifications_and_publishing(activity_params[:festival_id], @from, @to, @time_config)
    
  #   render json: notifications_and_publishing
  # end

  private

    def set_from_and_to 
      if params[:from] and params[:to]
        @from = DateTime.strptime(params[:from],'%s').beginning_of_day
        @to = DateTime.strptime(params[:to],'%s').end_of_day

        period_length = (@to.to_date - @from.to_date).to_i

        if(period_length <= 1)
          @time_config = {
            unit: 'minute',
            stepSize: 10
          }
        elsif(period_length > 1 && period_length <= 7)
          @time_config = {
            unit: 'hour',
            stepSize: 1
          }
        elsif(period_length > 7) #&& period_length < 31)
          @time_config = {
            unit: 'day',
            stepSize: 1
          }
        # elsif(period_length > 31)
        #   @time_config = {
        #     unit: 'week',
        #     stepSize: 1
        #   }          
        end
      else
        @from = DateTime.now.beginning_of_day-1.day
        @to =  DateTime.now.end_of_day
        @time_config = {
          unit: 'minute',
          stepSize: 10
        }
      end
    end

    def activity_params
      params.permit(:festival_id, :from, :to, :all_time)
    end
end