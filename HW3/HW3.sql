-- Paul Anderson
-- Database Management Systems D01
-- 15 October 2025
-- Assignment 3

set SQL_SAFE_UPDATES=0;
set FOREIGN_KEY_CHECKS=0;

-- Setting up constraints 
-- Added a primary key
alter table merchants
add constraint primary key (mid);

-- Added a primary key
alter table products
add constraint primary key (pid),
add constraint steve check (name in ('Printer', 'Ethernet Adapter', 'Desktop', 'Hard Drive', 'Laptop', 'Super Drive', 'Monitor', 'Network Card', 'Router')),
add constraint check (products.category in ('Peripheral', 'Networking', 'Computer'));  

-- Constraining shipping cost to > 0 and < 500; Added primary key
alter table orders 
add constraint check (shipping_cost >= 0),
add constraint check (shipping_cost <= 500),
add constraint primary key (oid),
add constraint check (shipping_method in ('UPS', 'FedEx', 'USPS'));

-- Added a primary key
alter table customers
add constraint primary key (cid);

-- Added foreign keys
alter table contain
add constraint foreign key (oid) references orders(oid),
add constraint foreign key (pid) references products(pid);





-- Constraining price and quantity available; adding foreign keys
alter table sell
add constraint check (price >= 0),
add constraint check (price <= 100000),
add constraint check (quantity_available >= 0),
add constraint check (quantity_available <= 1000),
add constraint foreign key (mid) references merchants(mid),
add constraint foreign key (pid) references products(pid);



-- Checking for a valid date and adding foreign keys
alter table place
add constraint foreign key (cid) references customers(cid),
add constraint foreign key (oid) references orders(oid);

-- Queries
-- query 1: List names and sellers of products that are no longer available
-- simply finding products that have a quantity of 0, implying they have sold out or are nolonger available 
select merchants.name, products.name, sell.quantity_available
from merchants
join sell on merchants.mid = sell.mid
join products on products.pid = sell.pid
where quantity_available = 0; 


-- query 2: List names and descriptions of products thare are not sold
-- getting a list of not sold items via the except function
select products.name, products.description
from products

except 

select products.name, products.description
from products natural join sell;


-- query 3: How many customers bought SATA drives but not any routers
-- using the except function to remove the count of people who bought sata but not routers
-- Getting everyone who bought an SSD
select products.name, count(customers.cid) as purchase_count
from products
join contain
on products.pid = contain.pid 
join orders
on contain.oid = orders.oid
join place
on orders.oid = place.oid
join customers on place.cid = customers.cid
group by products.name
having products.name = 'Super Drive'

-- Leaving out
except

-- Getting everyone who purchased a router
select products.name, count(customers.cid) as purchase_count
from products
join contain
on products.pid = contain.pid 
join orders
on contain.oid = orders.oid
join place
on orders.oid = place.oid
join customers on place.cid = customers.cid
group by products.name
having products.name = 'Routers';

-- query 4: HP has 20% sale on all its networking products
-- applying a 20% discount by mutliplcation of sell.price by 0.8
select products.name, products.category, sell.price, sell.price * .8 as discounted_price, merchants.name
from products 
join sell on products.pid = sell.pid
join merchants on sell.mid = merchants.mid
where merchants.name = 'HP' and products.category = 'Networking'; 


-- query 5: What did Uriel Whitney order(get product name and price)
-- getting everything Uriel ordered 
select customers.fullname, products.name, sell.price
from customers
join place on customers.cid = place.cid
join orders on place.oid = orders.oid
join contain on orders.oid = contain.oid
join products on contain.pid = products.pid
join sell on products.pid = sell.pid
where customers.fullname = 'Uriel Whitney';


-- query 6: List the annual total sales for each company (sort along company and year attribute)
-- Extracting the year from order_date and then finding the average annual revenue
select merchants.name, extract(year from order_date) as salesyear, avg(price * quantity_available) as yearly_average_price
from merchants 
join sell on merchants.mid = sell.mid
join contain on sell.pid = contain.pid
join orders on contain.oid = orders.oid
join place on orders.oid = place.oid
group by merchants.name, salesyear
order by merchants.name, salesyear;

-- query 7: Which company has the highest annual revenue & what year
-- Extracting the year from order_date and then finding the highest annual revenue
select merchants.name, extract(year from order_date) as salesyear, avg(price * quantity_available) as yearly_average_price
from merchants 
join sell on merchants.mid = sell.mid
join contain on sell.pid = contain.pid
join orders on contain.oid = orders.oid
join place on orders.oid = place.oid
group by merchants.name, salesyear
order by yearly_average_price desc
limit 1;

-- query 8: on average what was the cheapest shipping method available
-- relatively simple query, just getting the average_shipping_cost and just finding the cheapest one
select shipping_method, avg(shipping_cost) as average_shipping_cost
from orders
group by shipping_method
order by average_shipping_cost asc 
limit 1;



-- query 9: What is the best sold ($) category for each company
-- Using a CTE to make it readable. 
with amount_sold as (
	select products.pid, products.category, count(orders.oid) as num_orders
    from products
    join contain on products.pid = contain.pid
    join orders on contain.oid = orders.oid
    group by products.pid, products.category
    having num_orders >= all ( -- ranking products category as having the most out of all the category, groupe. 
		select count(orders.oid)
		from products
		join contain on products.pid = contain.pid
		join orders on contain.oid = orders.oid
		group by products.pid, products.category
    )
)

-- Main query
select merchants.name, amount_sold.category
from merchants
join sell on merchants.mid = sell.mid
join amount_sold on sell.pid = amount_sold.pid
order by amount_sold.num_orders desc;

-- query 10: for each company find out which customers have spent the most and the least amounts
-- CTE to find most and least spender
-- this subquery find the most spending and least spending customer
with most_spent as (
	select merchants.name, customers.fullname, sum(sell.price * sell.quantity_available) as max_total_spent
    from merchants
    join sell on merchants.mid = sell.mid
    join products on sell.pid = products.pid
    join contain on products.pid = contain.pid
    join orders on contain.oid = orders.oid 
    join place on orders.oid = place.oid
    join customers on place.cid = customers.cid
    group by merchants.name , customers.fullname
    having max_total_spent >= all ( -- searching for the most spending
		select sum(sell.price * sell.quantity_available) 
		from merchants
		join sell on merchants.mid = sell.mid
		join products on sell.pid = products.pid
		join contain on products.pid = contain.pid
		join orders on contain.oid = orders.oid 
		join place on orders.oid = place.oid
		join customers on place.cid = customers.cid
        group by merchants.name, customers.fullname
    ) or max_total_spent <= all ( -- searching for the least spending
		select sum(sell.price * sell.quantity_available)
		from merchants
		join sell on merchants.mid = sell.mid
		join products on sell.pid = products.pid
		join contain on products.pid = contain.pid
		join orders on contain.oid = orders.oid 
		join place on orders.oid = place.oid
		join customers on place.cid = customers.cid
        group by merchants.name, customers.fullname
    )
    order by merchants.name, customers.fullname
)

-- main query
select most_spent.name, most_spent.fullname
from most_spent
group by most_spent.name, most_spent.fullname;




