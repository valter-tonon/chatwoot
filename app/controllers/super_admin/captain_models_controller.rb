class SuperAdmin::CaptainModelsController < SuperAdmin::ApplicationController
  def index
    provider = params[:provider]
    result = Llm::ModelListService.new(provider).perform

    render json: result
  end
end
