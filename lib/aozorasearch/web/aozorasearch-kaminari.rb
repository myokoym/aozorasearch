# https://github.com/kaminari/kaminari-sinatra/blob/master/lib/kaminari/helpers/sinatra_helpers.rb
module Kaminari::Helpers
  module SinatraHelpers
    module AozorasearchPatch
      # actionview 8 では initialize が lookup_context, assigns, controller を必須にしたため、
      # kaminari-sinatra 1.0.1 の super() 呼び出しだけでは初期化できない。
      def initialize(*args, current_path: nil, param_name: nil, current_params: nil)
        if args.empty?
          view_paths = [
            SinatraHelpers.view_paths,
            File.join(Gem.loaded_specs["kaminari-core"].gem_dir, "app/views"),
          ]
          ActionView::Base.instance_method(:initialize).bind_call(
            self,
            ActionView::LookupContext.new(view_paths),
            {},
            nil,
          )
        else
          ActionView::Base.instance_method(:initialize).bind_call(self, *args)
        end

        @current_path = current_path
        @param_name = param_name || Kaminari.config.page_method_name
        @current_params = current_params || {}
        @current_params.delete(@param_name)
      end

      def url_for(params)
        return params if String === params

        extra_params = {}
        if (page = params[@param_name]) && (Kaminari.config.params_on_first_page || (page.to_i != 1))
          extra_params[@param_name] = page
        end
        query = @current_params.merge(extra_params)
        if ENV["AOZORASEARCH_SUB_URL"]
          File.join(ENV["AOZORASEARCH_SUB_URL"], @current_path) + (query.empty? ? "" : "?#{query.to_query}")
        else
          super
        end
      end
    end
  end
end

Kaminari::Helpers::SinatraHelpers::ActionViewTemplateProxy.prepend(
  Kaminari::Helpers::SinatraHelpers::AozorasearchPatch,
)
