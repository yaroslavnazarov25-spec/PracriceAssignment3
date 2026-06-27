explain analyze
select
    oi.order_id,
    p.product_name,
    oi.quantity,
    oi.price,
    oi.quantity * oi.price as item_total
from order_items oi
join products p on oi.product_id = p.product_id
where oi.order_id = 1;

1) The execution plan:
Hash Join  (cost=27.09..41.32 rows=7 width=274) (actual time=0.057..0.066 rows=4.00 loops=1)
  Hash Cond: (p.product_id = oi.product_id)
  Buffers: shared hit=2
  ->  Seq Scan on products p  (cost=0.00..13.00 rows=300 width=222) (actual time=0.017..0.019 rows=6.00 loops=1)
        Buffers: shared hit=1
  ->  Hash  (cost=27.00..27.00 rows=7 width=28) (actual time=0.027..0.028 rows=4.00 loops=1)
        Buckets: 1024  Batches: 1  Memory Usage: 9kB
        Buffers: shared hit=1
        ->  Seq Scan on order_items oi  (cost=0.00..27.00 rows=7 width=28) (actual time=0.012..0.015 rows=4.00 loops=1)
              Filter: (order_id = 1)
              Rows Removed by Filter: 4
              Buffers: shared hit=1
Planning Time: 0.318 ms
Execution Time: 0.176 ms

2) A short explanation of how PostgreSQL executes the query:
PostgreSQL first performs a Sequential Scan on the order_items table and filters rows where order_id = 1.
It then performs a Sequential Scan on the products table and builds a hash table from the filtered order_items rows. 
Lastky PostgreSQL uses a Hash Join to match rows from products with order_items based on product_id.

3) Identification of whether PostgreSQL uses some operations:
Sequential Scan on order_items to filter rows by order_id;
Sequential Scan on products to read all product records;
Hash to build a hash table;
Hash Join to join products and order_items using product_id.
