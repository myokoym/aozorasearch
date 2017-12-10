# https://github.com/kaminari/kaminari-sinatra/blob/master/lib/kaminari/helpers/sinatra_helpers.rb
module Kaminari::Helpers
  module SinatraHelpers
    class ActionViewTemplateProxy
      def url_for(params)
        return params if String === params

        extra_params = {}
        if (page = params[@param_name]) && (Kaminari.config.params_on_first_page || (page.to_i != 1))
          extra_params[@param_name] = page
        end
        query = @current_params.merge(extra_params)
        if ENV["AOZORASEARCH_SUB_URL"]
          File.join(ENV["AOZORASEARCH_SUB_URL"], @current_path) + (query.empty? ? '' : "?#{query.to_query}")
        else
          @current_path + (query.empty? ? '' : "?#{query.to_query}")
        end
      end
    end
  end
end
