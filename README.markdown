## Safemode

A library for safe evaluation of Ruby code based on RubyParser and
Ruby2Ruby. Provides Rails ActionView template handlers for ERB and Haml.

### Word of warning

This library is still highly experimental. Only use it at your own risk for
anything beyond experiments and playing.

That said, please **do** play with it, read and run the unit tests and provide
feedback to help make it waterproof and finally suitable for serious purposes.

### Installation

safemode is available as gem, therefore you can use bundler or gem install to the
tool. The above warning still applies.

### Usage

For manual evaluation of Ruby code and ERB templates see demo.rb

You can use the ActionView template handlers by registering them, e.g., in 
a config/initializer file like this:

```ruby
# in config/intializer/safemode_tempate_handlers.rb
ActionView::Template.register_template_handler :serb, ActionView::TemplateHandlers::SafeErb
ActionView::Template.register_template_handler :haml, ActionView::TemplateHandlers::SafeHaml
```

If you register the ERB template handler for the file extension :erb be aware
that this most probably will break when your application tries to render an
error message in development mode (because Rails will try to use the handler
to render the error message itself).

You will then have to "whitelist" all method calls to the objects that are
registered as template variables by explicitely allowing access to them. You
can do that by defining a Safemode::Jail class for your classes, like so:

```ruby
class User
  class Jail < Safemode::Jail
    allow :name
  end
end
```

This will allow your template users to access the name method on your User 
objects.

Class methods can be whitelisted by calling `allow_class_method :foo` from
within the Jail. Note that access to raw constants is not permitted, so the
class is only accessible when returned by a method or passed into a template.

For more details about the concepts behind Safemode please refer to the 
following blog posts until a more comprehensive writeup is available:

* Initial reasoning: http://www.artweb-design.de/2008/2/5/sexy-theme-templating-with-haml-safemode-finally
* Refined concept: http://www.artweb-design.de/2008/2/17/sending-ruby-to-the-jail-an-attemp-on-a-haml-safemode
* ActionView ERB handler: http://www.artweb-design.de/2008/4/22/an-erb-safemode-handler-for-actionview

### Dependencies

Requires the gems:

* RubyParser
* Ruby2Ruby

### Credits

* Sven Fuchs - Initial Maintainer
* Peter Cooper
* Matthias Viehweger
* Ohad Levy
* Kingsley Hendrickse
* Dmitri Dolguikh

This code and all of the Safemode library's code was initially written by
Sven Fuchs to allow Haml to have a safe mode. It was then modified and
re-structured by Peter Cooper and Sven Fuchs to extend the idea to generic
Ruby eval situations.

Thanks to Ohad Levy for gemifying the project and Kingsley Hendrickse for
securing the right gem name on rubygems.org.
