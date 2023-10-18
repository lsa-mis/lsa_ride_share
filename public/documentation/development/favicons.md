# Favicons
[Home](./README.md) / [Development](development/README.md)

___

By default, favicons are derived from the site_logo.svg file using the [rails_real_favicon](https://github.com/RealFaviconGenerator/rails_real_favicon) gem. The we use the gem to interface with [realfavicongenerator](https://realfavicongenerator.net/favicon/ruby_on_rails) to generate a set of favicons and a browserconfig.xml file to load them for specific targets (iOS, Android, etc....). The favicons are stored in the `assets/images/favicon` directory.  

## Adding favicons to the application

- 1.) Create your logo and save it as an SVG. (**NOTE:** The logo should NOT include the word mark. 
- 2.) Replace the `site_logo.svg` file in the `assets/images` directory.
- 3.) Update the ```config/favicon.json``` file to customize the details of the favicons (such as background colors, masking etc). 
- 4.) run the favicon generator command:

```shell
  # Requires internet connection
  bin/rails generate favicon
```

- 5.) Uncomment the line to include the favicons partial in the application layout:

```ruby
  # app/views/layouts/application.html.erb
  <%= render 'application/favicon' %> 
```

Rename the browserconfig.xml.erb to browserconfig.xml in the app/assets/images/favicon directory.