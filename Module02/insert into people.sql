DROP TABLE IF EXISTS people;
CREATE TABLE people(
   person VARCHAR(17) NOT NULL PRIMARY KEY
  ,region VARCHAR(7) NOT NULL
);
INSERT INTO people(person,region) VALUES ('Anna Andreadi','West');
INSERT INTO people(person,region) VALUES ('Chuck Magee','East');
INSERT INTO people(person,region) VALUES ('Kelly Williams','Central');
INSERT INTO people(person,region) VALUES ('Cassandra Brandow','South');