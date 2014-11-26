--- PostgreSQL tables, rules, triggers for tracking YikYak data

/* Table for storing messages. */
CREATE TABLE yakmessages
(
  message_id character varying(64) NOT NULL,
  poster_id character varying(32),
  handle text,
  message text,
  likes integer,
  comments integer,
  longitude numeric(10,7),
  latitude numeric(10,7),
  message_ts timestamp without time zone,
  CONSTRAINT yakmessages_pkey PRIMARY KEY (message_id)
)
WITH (
  OIDS=FALSE
);

/* Table for storing comments. References the messages table. */
CREATE TABLE yakcomments
(
  comment_id character varying(64) NOT NULL,
  message_id character varying(64),
  poster_id character varying(32),
  comment text,
  likes integer,
  comment_ts timestamp without time zone,
  CONSTRAINT yakcomments_pkey PRIMARY KEY (comment_id),
  CONSTRAINT yakcomments_message_id_fkey FOREIGN KEY (message_id)
      REFERENCES yakmessages (message_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);

/* Insert all the things! */
CREATE OR REPLACE RULE yakmessages_ignore_duplicate_inserts AS
    ON INSERT TO yakmessages
 WHERE (EXISTS ( SELECT 1
				   FROM yakmessages
				  WHERE yakmessages.message_id = NEW.message_id))
    DO INSTEAD NOTHING;
/* should change the above to update the number of comments, etc. */ 

CREATE OR REPLACE RULE yakcomments_ignore_duplicate_inserts AS
    ON INSERT TO yakcomments
 WHERE (EXISTS ( SELECT 1
				   FROM yakcomments
				  WHERE yakcomments.comment_id = NEW.comment_id))
    DO INSTEAD NOTHING;