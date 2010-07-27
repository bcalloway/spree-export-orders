# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class ExportOrdersExtension < Spree::Extension
  version "1.0"
  description "Spree extension to provides functionality to export order reports on a per-product basis"
  url "http://github.com/bcalloway/spree-export-orders"
  
  def activate
    
    Admin::OrdersController.class_eval do

      def export_report
        @product=Product.find(params[:product_id])
        @orders=Order.find_by_sql("select orders.id, orders.user_id, addresses.firstname, addresses.lastname, addresses.address1, addresses.address2, addresses.city, states.abbr, addresses.zipcode, addresses.phone, orders.number, orders.item_total, orders.total, orders.created_at, orders.updated_at, orders.state, orders.adjustment_total, orders.credit_total, orders.completed_at, line_items.quantity, line_items.price, variants.product_id, variants.sku from orders, checkouts, addresses, states, line_items, variants where orders.id=checkouts.order_id and checkouts.ship_address_id=addresses.id and addresses.state_id=states.id and line_items.order_id=orders.id and line_items.variant_id=variants.id and variants.product_id=#{params[:product_id]} and checkouts.state='complete'")
        self.generate_csv("#{@product.permalink}-sales")
      end
      
      def generate_csv(context)
        orders_csv = FasterCSV.generate do |csv|
          # header row
          csv << ["Order ID",	"User ID", "First Name", "Last Name", "Address1", "Address2", "City", "State", "Zip", "Phone", "Order Number", "Item Total",	"Order Total", "Created At", "Updated At", "Order State", "Adjustment Total",	"Credit Total",	"Completed At",	"Quantity",	"Price", "Product ID", "Sku"]

          # data rows
          @orders.each do |order|
            csv << [order.id,	order.user_id, order.firstname, order.lastname, order.address1, order.address2, order.city, order.abbr, order.zipcode, order.phone, order.number,	order.item_total,	order.total, order.created_at, order.updated_at, order.state, order.adjustment_total,	order.credit_total,	order.completed_at,	order.quantity,	order.price, order.product_id, order.sku]
          end
        end

        send_data(orders_csv, :type => 'text/csv', :filename => "#{context}.csv")
      end
      
      
      def collection
        
        @search = Order.searchlogic(params[:search])
        
        if params[:search]
          @search.order ||= "descend_by_created_at"
        else
          @search.state ||= "new"
        end
        
        # QUERY - get per_page from form ever???  maybe push into model
        # @search.per_page ||= Spree::Config[:orders_per_page]

        # turn on show-complete filter by default
        unless params[:search] && params[:search][:completed_at_not_null]
          @search.completed_at_not_null = true
        end

        @collection = @search.paginate(:include  => [:user, :shipments, :payments],
                                       :per_page => Spree::Config[:orders_per_page],
                                       :page     => params[:page])
      end
    end
    
  end
end
