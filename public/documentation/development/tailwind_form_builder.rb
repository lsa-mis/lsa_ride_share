module FormBuilders
  class TailwindFormBuilder < ActionView::Helpers::FormBuilder
    # Same list of dynamically-generated field helpers as in Rails:
    #   actionview/lib/action_view/helpers/form_helper.rb
    [:text_field,
      :password_field,
      :text_area,
      :color_field,
      :search_field,
      :telephone_field,
      :phone_field,
      :date_field,
      :time_field,
      :datetime_field,
      :datetime_local_field,
      :month_field,
      :week_field,
      :url_field,
      :email_field,
      :number_field,
      :range_field].each do |field_method|
      class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
          def #{field_method}(method, options = {})
            if options.delete(:tailwindified)
              super
            else
              text_like_field(#{field_method.inspect}, method, options)
            end
          end
      RUBY_EVAL
    end

    def submit(value = nil, options = {})
      value, options = nil, value if value.is_a?(Hash)
      value ||= submit_default_value

      classes = <<~CLASSES.strip
        mt-2 bg-transparent font-semibold hover:text-white py-1 px-3 border
        hover:border-transparent rounded cursor-pointer
      CLASSES

      classes += case options.delete(:variant) { :commit }
      when :commit then " hover:bg-blue-500 text-blue-700 border-blue-500"
      when :reset then " hover:bg-red-500 text-red-700 border-red-500"
      end

      super(value, {class: classes}.merge(options))
    end

    private

    def text_like_field(field_method, object_method, opts = {})
      custom_opts, opts = partition_custom_opts(opts)

      classes = <<~CLASSES.strip
        mt-1 block w-full rounded-md shadow-sm focus:ring focus:ring-indigo-200 focus:ring-opacity-50
      CLASSES

      classes << if @object.errors[object_method].present?
        " border-2 border-red-400 focus:border-rose-200"
      else
        " border border-gray-300 focus:border-indigo-300"
      end

      label = label(object_method, custom_opts[:label_text], class: "mt-1 block w-full")
      field = send(field_method, object_method, {
        class: classes
      }.merge(opts).merge({tailwindified: true}))

      label + field
    end

    CUSTOM_OPTS = [:label_text].freeze
    def partition_custom_opts(opts)
      opts.partition { |k, v| CUSTOM_OPTS.include?(k) }.map(&:to_h)
    end
  end
end