
set SQL_SAFE_UPDATES = 0;
set FOREIGN_KEY_CHECKS = 0;

-- 1: average price of foods at each restaurant

-- selecting the restaurant prices
select restaurants.restID, restaurants.name, AVG(foods.price) as averagePrice
-- Joinging the tables restaurants, serves, and foods by their IDs
from restaurants 
join serves
on restaurants.restID = serves.restID
join foods
on foods.foodID = serves.foodID
-- Group by the restaurant ID and name
group by restaurants.restID, restaurants.name
-- Order by the average price descending
order by avg(foods.price) desc;

-- -----------------------------------------------------------------
-- 2: maximum food price at each restaurant

-- Selecting the restaurant id, name, and prices of food
select restaurants.restID, restaurants.name, max(foods.price) as maxPrice
-- Joining the tables restaurants, serves, and foods by their IDs
from restaurants 
join serves
on restaurants.restID = serves.restID
join foods
on foods.foodID = serves.foodID
-- Group by the restaurant id and name
group by restaurants.restID, restaurants.name
-- Order by the max price descending
order by max(foods.price) desc;

-- ------------------------------------------------------------
-- 3 count of different food types served at each restaurant


select restaurants.restID, restaurants.name, count(foods.type) as typesServed
-- Joining the tables restaurants, serves, and foods by their IDs
from restaurants 
join serves
on restaurants.restID = serves.restID
join foods
on foods.foodID = serves.foodID
-- Group by the restaurant id and name
group by restaurants.restID, restaurants.name
-- Order by the count of foods served descending
order by count(foods.type) desc;

-- ----------------------------------------------
-- 4 average price of foods served by each chef

-- Creating a view to keep later statement cleaner
create view cs as
(
	select chefs.chefID, chefs.name as cname, restaurants.restID
    from chefs 
    join works
    on chefs.chefID = works.chefID
    join restaurants
    on restaurants.restID = works.restID
);

-- selecting chefID, chef name, and average prices
select chefID, cname, avg(foods.price) as averagePrice
from cs
join serves
on cs.restID = serves.restID
join foods
on foods.foodID = serves.foodID
group by chefID, cname
order by avg(foods.price) desc;

-- ------------------------------------------------------------------
-- 5 find the restaurant with the highest average food price
select restaurants.restID, restaurants.name, avg(foods.price) as averagePrice
from restaurants
join serves
on restaurants.restID = serves.restID
join foods
on foods.foodID = serves.foodID
group by restaurants.restID, restaurants.name
having avg(foods.price) >= all(
-- Subquery to get the restaurant with the highest average food price
	select avg(foods.price) 
    from restaurants
    join serves 
    on restaurants.restID = serves.restID
    join foods
    on foods.foodID = serves.foodID
    group by restaurants.restID, restaurants.name
);

