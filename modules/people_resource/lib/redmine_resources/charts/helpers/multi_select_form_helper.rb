# class MultiSelectForm < ApplicationForm
#     form do |select_form|
#       select_form.select_list(name: "been", label: "Places you've been", caption: "Select all that apply", multiple: true, include_hidden: false) do |been_list|
#         been_list.option(label: "Lima, Peru", value: "lima")
#         been_list.option(label: "Tokyo, Japan", value: "tokyo")
#         been_list.option(label: "Reykjavík, Iceland", value: "reykjavik")
#         been_list.option(label: "Chiang Mai, Thailand", value: "chiang_mai")
#         been_list.option(label: "Queenstown, New Zealand", value: "queenstown")
#       end
#     end
#   end


module RedmineResources
  module Charts
    module Helpers
      module MultiSelectFormHelper
        include ActionView::Helpers::FormOptionsHelper

        def multi_select_form
          form_tag(url: '/your_form_url', method: 'post') do
            content_tag(:div, class: 'form-group') do
              label_tag('been', "Places you've been") +
              content_tag(:select, multiple: true, name: 'been[]', id: 'been') do
                option_tag("Lima, Peru", value: 'lima') +
                option_tag("Tokyo, Japan", value: 'tokyo') +
                option_tag("Reykjavík, Iceland", value: 'reykjavik') +
                option_tag("Chiang Mai, Thailand", value: 'chiang_mai') +
                option_tag("Queenstown, New Zealand", value: 'queenstown')
              end +
              content_tag(:small, "Select all that apply", class: 'form-text text-muted')
            end
          end
        end
      end
    end
  end
end