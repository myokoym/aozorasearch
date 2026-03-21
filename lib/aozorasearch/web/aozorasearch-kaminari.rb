# https://github.com/kaminari/kaminari-sinatra/blob/master/lib/kaminari/helpers/sinatra_helpers.rb
module Kaminari::Helpers
  module SinatraHelpers
    module AozorasearchPaginateKeywordCompatibilityPatch
      # kaminari-sinatra 1.0.1 は Ruby 3 の keyword arguments 分離に未対応で、
      # paginate 内の super 呼び出しが `wrong number of arguments (given 2, expected 1)`
      # で落ちる。壊れた super チェインは使わず、kaminari-core 相当の処理を
      # Sinatra 用 template 構築込みでここに最小実装する。
      def paginate(scope, paginator_class: Kaminari::Helpers::Paginator, template: nil, **options)
        current_path = env["PATH_INFO"]
        current_params = Rack::Utils.parse_query(env["QUERY_STRING"].to_s).symbolize_keys

        template ||= Kaminari::Helpers::SinatraHelpers::ActionViewTemplateProxy.new(
          current_params: current_params,
          current_path: current_path,
          param_name: options[:param_name] || Kaminari.config.param_name,
        )

        options[:total_pages] ||= scope.total_pages
        options.reverse_merge!(
          current_page: scope.current_page,
          per_page: scope.limit_value,
          remote: false,
        )

        paginator = paginator_class.new(template, **options)
        paginator.to_s
      end
    end

    module AozorasearchActionViewCompatibilityPatch
      # kaminari-sinatra 1.0.1 は 2017 年の実装のままで、ActionViewTemplateProxy#initialize
      # から ActionView::Base に super() を無引数で渡している。
      # actionview 7.2.3 でも /search の HTML 描画時に
      # `ArgumentError: wrong number of arguments (given 0, expected 3)` が再現したため、
      # 互換引数をここで補う。
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

      def compiled_method_container
        self.class
      end
    end

    module AozorasearchSubUrlPatch
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

Kaminari::Helpers::HelperMethods.prepend(
  Kaminari::Helpers::SinatraHelpers::AozorasearchPaginateKeywordCompatibilityPatch,
)

Kaminari::Helpers::SinatraHelpers::ActionViewTemplateProxy.singleton_class.class_eval do
  define_method(:compiled_method_container) { self }
end

Kaminari::Helpers::SinatraHelpers::ActionViewTemplateProxy.prepend(
  Kaminari::Helpers::SinatraHelpers::AozorasearchActionViewCompatibilityPatch,
)

Kaminari::Helpers::SinatraHelpers::ActionViewTemplateProxy.prepend(
  Kaminari::Helpers::SinatraHelpers::AozorasearchSubUrlPatch,
)
