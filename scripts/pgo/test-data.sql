CREATE TABLE fruit (
  id VARCHAR(100) PRIMARY KEY,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO fruit (id) VALUES ('apple');
INSERT INTO fruit (id) VALUES ('pear');
INSERT INTO fruit (id) VALUES ('cherry');

INSERT INTO fruit (id) VALUES ('mango');
INSERT INTO fruit (id) VALUES ('maracuja');
INSERT INTO fruit (id) VALUES ('banana');

INSERT INTO fruit (id) VALUES ('lemon');
INSERT INTO fruit (id) VALUES ('orange');
INSERT INTO fruit (id) VALUES ('pomelo');

INSERT INTO fruit (id) VALUES ('papaja');
INSERT INTO fruit (id) VALUES ('kiwi');

SELECT * FROM fruit;

--DROP TABLE fruit;