-- Title: DB Assignment 4
-- Name: Paul Anderson
-- Date: 30 October 2025

-- all tables must have primary keys [done]
-- Category names com from the set {Animation, Comedy, Family, Foreign, Sci-Fi, Travel, Children, Drama, Horror, Action, Classics, Games, New, Documentary, Sports, Music}
-- A fulm's special_features attribute comes from the set {Behind the Scenes, Commentaries, Deleted Scenes, Trailers}
-- all dates must be valid
-- active is from the set [0,1], 1 is active, 0 inactive 
-- rental duration is a positive number of days between 2 and 8
-- rental rate per day is between 0.99 and 6.99
-- film length is between 30 and 200 minutes
-- ratings are {PG, G, NC-17, PG-13, R}
-- replacement cost is between 5.00 and 100.00
-- Amount should be >= 0

-- giving all tables primary or foreign keys
alter table actor
add constraint primary key (actor_id); 

alter table category
add constraint primary key (category_id),
add constraint check (name in ('Animation', 'Comedy', 'Family', 'Foreign', 'Sci-Fi', 'Travel', 'Children', 'Drama', 'Horror', 'Action', 'Classics', 'Games', 'New', 'Documentary', 'Sports', 'Music'));

alter table country
add constraint primary key (country_id);

alter table language
add constraint primary key (language_id);

-- do film csv when I can
alter table film
add constraint primary key (film_id),
add constraint foreign key (language_id) references language(language_id),
add constraint check (rental_duration between 2 and 8),
add constraint check (special_features in ('Behind the Scenes', 'Commentaries', 'Deleted Scenes', 'Trailers')),
add constraint check (rental_rate between 0.99 and 6.99),
add constraint check (length between 30 and 200), 
add constraint check (rating in ('PG', 'G','NC-17','PG-13','R')),
add constraint check (replacement_cost between 5.00 and 100.00);

alter table film_actor
add constraint foreign key (actor_id) references actor(actor_id),
add constraint foreign key (film_id) references film(film_id);

alter table film_category
add constraint foreign key (film_id) references film(film_id),
add constraint foreign key (category_id) references category(category_id);



alter table city
add constraint primary key (city_id),
add constraint foreign key (country_id) references country(country_id);



alter table address
add constraint primary key (address_id),
add constraint foreign key (city_id) references city(city_id);

alter table store
add constraint primary key (store_id), 
add constraint foreign key (address_id) references address(address_id);

alter table inventory
add constraint primary key (inventory_id),
add constraint foreign key (film_id) references film(film_id),
add constraint foreign key (store_id) references store(store_id); 

alter table staff
add constraint primary key (staff_id),
add constraint foreign key (address_id) references address(address_id),
add constraint foreign key (store_id) references store(store_id);


alter table customer
add constraint primary key (customer_id),
add constraint foreign key (store_id) references store(store_id),
add constraint foreign key (address_id) references address(address_id),
add constraint check (active in (1,0));



alter table rental
add constraint primary key (rental_id),
add constraint foreign key (inventory_id) references inventory(inventory_id),
add constraint foreign key (customer_id) references customer(customer_id),
add constraint foreign key (staff_id) references staff(staff_id);


alter table payment
add constraint primary key (payment_id),
add constraint foreign key (customer_id) references customer(customer_id),
add constraint foreign key (staff_id) references staff(staff_id),
add constraint foreign key (rental_id) references rental(rental_id),
add constraint check (amount >= 0);


-- Query 1: What is the average length of films in each category? List the results in alphabetic order of categories
-- getting the category name and getting all the film length averages and grouping them by category
select category.name, avg(film.length) as avg_film_length
from category
join film_category on category.category_id = film_category.category_id
join film on film_category.film_id = film.film_id
group by category.name 
order by category.name;



-- Query 2: Which categories have the longest and shortest average film lengths?
-- initial search looking for the longest average film length
select category.name, avg(film.length) as avg_film_length
from category
join film_category on category.category_id = film_category.category_id
join film on film_category.film_id = film.film_id
group by category.name 
having avg_film_length >= all ( -- seeing which film category has the greatest average
	select avg(film.length)
    from category
	join film_category on category.category_id = film_category.category_id
	join film on film_category.film_id = film.film_id
	group by category.name)

union 

-- search looking for the shortest average film length
select category.name, avg(film.length) as avg_film_length
from category
join film_category on category.category_id = film_category.category_id
join film on film_category.film_id = film.film_id
group by category.name 
having avg_film_length <= all ( -- seeing which film category has the greatest average
	select avg(film.length)
    from category
	join film_category on category.category_id = film_category.category_id
	join film on film_category.film_id = film.film_id
	group by category.name);


-- Query 3: Which customers have rented action but not comedy or classic movies?
-- getting customers who rented out action movies
select customer.customer_id, customer.first_name, customer.last_name 
from customer
join rental on customer.customer_id = rental.customer_id
join inventory on rental.rental_id = inventory.inventory_id
join film on inventory.film_id = film.film_id
join category on film.film_id = category.category_id
where category.name = 'Action'

-- remove the next query
except

-- getting customers who rented out comedy or classics
select customer.customer_id, customer.first_name, customer.last_name 
from customer
join rental on customer.customer_id = rental.customer_id
join inventory on rental.rental_id = inventory.inventory_id
join film on inventory.film_id = film.film_id
join category on film.film_id = category.category_id
where category.name = 'Comedy' or 'Classics';




-- Query 4: Which actor has appeared in the most English-language movies?

-- gets a list of all the films that are english
with english_movies as (
select film.film_id, film.title
from film
join language on film.language_id = language.language_id
where language.name = 'English'
)

-- uses the previous cte to get the actors who have appeared in all english movies
select actor.actor_id, actor.first_name, actor.last_name, count(english_movies.title) as num_of_english_movies
from english_movies
join film_actor on english_movies.film_id = film_actor.film_id
join actor on film_actor.actor_id = actor.actor_id
group by actor.actor_id, actor.first_name, actor.last_name
having num_of_english_movies >= all ( -- sorts for the actor who has been in the most english movies
	select count(english_movies.title)
    from english_movies
	join film_actor on english_movies.film_id = film_actor.film_id
	join actor on film_actor.actor_id = actor.actor_id
	group by actor.actor_id, actor.first_name, actor.last_name
);


-- Query 5: How many distinct movies were rented for exactly 10 days from the store where Mike works?
-- CTE to get the store where mike worked at
with store_where_mike_works as (
	select store.store_id 
    from store
    join staff on store.store_id = staff.store_id
    where staff.first_name = 'Mike'
)

-- main query getting the count of movies that were rented for 10 days. 
select distinct store_where_mike_works.store_id, count(film.title) as number_of_movies_rented
from store_where_mike_works
join inventory on store_where_mike_works.store_id = inventory.store_id
join film on inventory.film_id = film.film_id
where film.rental_duration = 10
group by store_where_mike_works.store_id;

-- Query 6: Alphabetically list actors who appeared in the movie with the largest cast of actors.
-- CTE to find which film has the most actors
with largest_actors as (
	select film.film_id, count(actor.actor_id) as num_of_actors
    from actor
    join film_actor on actor.actor_id = film_actor.actor_id
    join film on film_actor.film_id = film.film_id
    group by film.film_id
    having num_of_actors >= all ( -- searching for the film with the greatest number of actors
		select count(actor.actor_id)
        from actor
		join film_actor on actor.actor_id = film_actor.actor_id
		join film on film_actor.film_id = film.film_id 
		group by film.film_id
    )
)

-- Main query, just getting the actors first and last name that are in the result from the CTE search
select largest_actors.film_id, actor.first_name, actor.last_name
from largest_actors
join film_actor on largest_actors.film_id = film_actor.film_id
join actor on film_actor.actor_id = actor.actor_id
order by actor.last_name;



