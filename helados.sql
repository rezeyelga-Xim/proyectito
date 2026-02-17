/*@author eliezer*/

/*
============================================================================================================|
esta base de datos no está para nada completa, faltan diagramas, testeos, debates y un monton de cosas mas, 
solo estan las piezas fundamentales para que nuestra aplicacion haga algo basico, 

esta seria la version 0.01
============================================================================================================|
*/

-- drop database helado;
create database helado;

use helado;
/*=================================================================================|
esta tabla va a guardar las indicaciónes paso a paso de como hacer los helados
*/
create table rectas(
id_receta int auto_increment,
nombre varchar(20) not null,
descripcion varchar(50),-- deprecated
primary key(id_receta)
); 
/*
==============================================================================================================|
esta tabla nos va a ayudar a guardar los ingredientes de cada usuario, por ejemplo el usuario pepito67 tiene 
en su heladera 17 unidades o kg (se vera cual se deja en futuras veriónes)
==============================================================================================================|
*/
create table ingredientes(
id_ingred int auto_increment,
nombre varchar(20) not null,
-- ==================================================================|
sabor varchar(15), -- aca podes poner: amargo, agrio, picante, etc...
-- ==================================================================|
primary key (id_ingred)

);

-- ============================================================================|
-- aca hice una nueva tabla por que una receta puede tener varios ingredientes,
--  y un ingrediente puede estar en varias recetas
-- ============================================================================|
create table helados(
id_receta int,
id_ingred  int,
id_helados int,
descripcion varchar(45),
primary key (id_helados),
foreign key (id_receta) references rectas(id_receta),
foreign key (id_ingred) references ingredientes(id_ingred)
);
/*
====================================================================|
aca vamos a guardar algunos datos de las personas
====================================================================|
*/
create table personas(
id_persona int auto_increment,
nombre varchar(15) not null,
fecha_creacion date not null,
primary key (id_persona)
);
/*
=============================================================|
en esta tabla vamos a relacionar las personas con los helados
=============================================================|
*/
create table helado_personas(
id int auto_increment, 
id_persona int,
id_helados int,
primary key (id),
foreign key (id_helados) references helados(id_helados),
foreign key (id_persona) references personas(id_persona)
);

