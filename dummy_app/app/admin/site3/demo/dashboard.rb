ActiveAdmin.register_page "Dashboard", namespace: [:site3, :demo] do

  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    div class: "blank_slate_container", id: "dashboard_default_message" do
      span class: "blank_slate" do
        h1 "site 3"
      end
    end
  end

end