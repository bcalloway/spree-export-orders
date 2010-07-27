map.namespace :admin do |admin|
  admin.export_report '/export_report', :controller => :orders, :action => :export_report
end