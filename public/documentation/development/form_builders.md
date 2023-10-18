# Form Builders
[Home](./README.md) / [Development](development/README.md)

The ModelRails template uses custom form builders to add our customizations without sacrificing the niceties that Rails provides. The form builders are located in `app/form_builders/`.

FormBuilders can be used on a per-form basis by passing the `builder` option to the `form_for` method. For example:

```ruby
<%= form_for @some_model, builder: TailwindFormBuilder do |f| %>
  ...  
<% end %>
```

FormBuilders can also be set as the default form builder for the entire application by adding the following to `config/application.rb`:

```ruby 
config.autoload_paths += %W(#{config.root}/app/form_builders)
config.action_view.default_form_builder = TailwindFormBuilder
```


