ActiveAdmin.register Post, namespace: [:site1] do
  permit_params :title, :content, :author, :is_published
end