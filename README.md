1) "calculate_order_total" function returns the price of all order items, and 0 if there are no items
2) "create_order" procedure creates a new order if customer id exists
3) "add_product_to_order" procedure creates a row in order_items and decreases stock amount from products if all the parameters are right
4) "update_order_total_triger" uses the first function to update total amount in order when there are changes in order items
5) "order_log_triger" adds a row to order_logs when a new order is created
