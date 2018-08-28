# ActiveAdmin Nested Namespace

This plugin allows you to register resources/pages with nested namespaces in ActiveAdmin. 

Here is the example project: https://github.com/siutin/activeadmin-nested-namespaces

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activeadmin-nested-namespaces'
```

And then execute:

    $ bundle install


Copy and paste these lines to `config/initializers/active_admin_nested_namespace.rb`

```ruby
require 'active_admin/nested_namespace'

if defined?(ActiveAdmin::NestedNamespace)
  ActiveAdmin::NestedNamespace.setup
end
```

# Get Started

Register resources to 2 different namespaces:  

```ruby
# /app/admin/site1/foo/bar/posts.rb
ActiveAdmin.register Post, namespace: [:admin, :site1, :foo, :bar] do
  ...
end
```

```ruby
# /app/admin/site2/demo/posts.rb 
ActiveAdmin.register Post, namespace: [:admin, :site2, :demo] do
  ...
end
```

It will generate routes like:

```
              admin_site1_foo_bar_root GET        /admin/site1/foo/bar(.:format)                    admin/site1/foo/bar/dashboard#index
                 admin_site2_demo_root GET        /admin/site2/demo(.:format)                       
batch_action_admin_site1_foo_bar_posts POST       /admin/site1/foo/bar/posts/batch_action(.:format) admin/site1/foo/bar/posts#batch_action
             admin_site1_foo_bar_posts GET        /admin/site1/foo/bar/posts(.:format)              admin/site1/foo/bar/posts#index
                                       POST       /admin/site1/foo/bar/posts(.:format)              admin/site1/foo/bar/posts#create
          new_admin_site1_foo_bar_post GET        /admin/site1/foo/bar/posts/new(.:format)          admin/site1/foo/bar/posts#new
         edit_admin_site1_foo_bar_post GET        /admin/site1/foo/bar/posts/:id/edit(.:format)     admin/site1/foo/bar/posts#edit
              admin_site1_foo_bar_post GET        /admin/site1/foo/bar/posts/:id(.:format)          admin/site1/foo/bar/posts#show
                                       PATCH      /admin/site1/foo/bar/posts/:id(.:format)          admin/site1/foo/bar/posts#update
                                       PUT        /admin/site1/foo/bar/posts/:id(.:format)          admin/site1/foo/bar/posts#update
                                       DELETE     /admin/site1/foo/bar/posts/:id(.:format)          admin/site1/foo/bar/posts#destroy
          admin_site1_foo_bar_comments GET        /admin/site1/foo/bar/comments(.:format)           admin/site1/foo/bar/comments#index
                                       POST       /admin/site1/foo/bar/comments(.:format)           admin/site1/foo/bar/comments#create
           admin_site1_foo_bar_comment GET        /admin/site1/foo/bar/comments/:id(.:format)       admin/site1/foo/bar/comments#show
                                       DELETE     /admin/site1/foo/bar/comments/:id(.:format)       admin/site1/foo/bar/comments#destroy
   batch_action_admin_site2_demo_posts POST       /admin/site2/demo/posts/batch_action(.:format)    admin/site2/demo/posts#batch_action
                admin_site2_demo_posts GET        /admin/site2/demo/posts(.:format)                 admin/site2/demo/posts#index
            edit_admin_site2_demo_post GET        /admin/site2/demo/posts/:id/edit(.:format)        admin/site2/demo/posts#edit
                 admin_site2_demo_post GET        /admin/site2/demo/posts/:id(.:format)             admin/site2/demo/posts#show
                                       PATCH      /admin/site2/demo/posts/:id(.:format)             admin/site2/demo/posts#update
                                       PUT        /admin/site2/demo/posts/:id(.:format)             admin/site2/demo/posts#update
             admin_site2_demo_comments GET        /admin/site2/demo/comments(.:format)              admin/site2/demo/comments#index
                                       POST       /admin/site2/demo/comments(.:format)              admin/site2/demo/comments#create
              admin_site2_demo_comment GET        /admin/site2/demo/comments/:id(.:format)          admin/site2/demo/comments#show
                                       DELETE     /admin/site2/demo/comments/:id(.:format)          admin/site2/demo/comments#destroy

```

# Configuration

In your initializers/active_admin.rb, you can define your own handler to the following methods.

* authentication_method
* current_user_method
* logout_link_path

For example:

``` ruby
# config.authentication_method = :authenticate_admin_user!
config.authentication_method = Proc.new do |name_path|
    if [config.default_namespace, :root].include?(name_path.first)
      :authenticate_admin_user!
    else
      "authenticate_#{name_path.map(&:to_s).join('_').underscore}_admin_user!".to_sym
    end
end

# config.current_user_method = :current_admin_user
config.current_user_method = Proc.new do |name_path|
  if [config.default_namespace, :root].include?(name_path.first)
    :current_admin_user
  else
    "current_#{name_path.map(&:to_s).join('_').underscore}_admin_user".to_sym
  end
end

# config.logout_link_path = :destroy_admin_user_session_path 
config.logout_link_path = Proc.new do |name_path|
    if [config.default_namespace, :root].include?(name_path.first)
      :destroy_admin_user_session_path
    else
      "destroy_#{name_path.map(&:to_s).join('_').underscore}_admin_user_session_path".to_sym
    end
end
    
```

And in your routes.rb:

```ruby
  namespace :site1 do
    namespace :foo do
      namespace :bar do
        devise_for :admin_users, ActiveAdmin::Devise.config
      end
    end
  end
  namespace :site2 do
    namespace :demo do
      devise_for :admin_users, ActiveAdmin::Devise.config
    end
  end
```

## Contributors
 [Martin Chan](https://twitter.com/osiutino) - creator 

## License

[MIT](https://opensource.org/licenses/MIT)
