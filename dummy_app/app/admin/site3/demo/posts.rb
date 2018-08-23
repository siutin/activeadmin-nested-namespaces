ActiveAdmin.register Post, namespace: [:site3, :demo] do

  permit_params :title, :content, :author, :is_published

  actions :index, :show, :update, :edit

  menu label: "Articles"

  index do
    id_column
    column :title
    column :author
    actions
  end
end