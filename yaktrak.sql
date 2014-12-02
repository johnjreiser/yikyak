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
    DO INSTEAD 
    UPDATE yakmessages
       SET likes = NEW.likes
         , comments = NEW.comments
         , longitude = NEW.longitude
         , latitude = NEW.latitude
     WHERE message_id = NEW.message_id;

CREATE OR REPLACE RULE yakcomments_ignore_duplicate_inserts AS
    ON INSERT TO yakcomments
 WHERE (EXISTS ( SELECT 1
				   FROM yakcomments
				  WHERE yakcomments.comment_id = NEW.comment_id))
    DO INSTEAD
    UPDATE yakcomments
       SET likes = NEW.likes
     WHERE comment_id = NEW.comment_id AND message_id = NEW.message_id;

CREATE OR REPLACE VIEW poster_stats AS
SELECT q.poster_id, max(q.messages) as messages, max(q.comments) as comments, sum(total_likes) as total_likes, sum(message_likes) as message_likes, sum(comment_likes) as comment_likes, min(timefirst) as timefirst, max(timelast) as timelast
FROM(
SELECT poster_id, count(message_id) as messages, 0 as comments, sum(likes) as total_likes, sum(likes) as message_likes, 0 as comment_likes, min(message_ts) as timefirst, max(message_ts) as timelast
  FROM yakmessages
 GROUP BY poster_id
UNION ALL
SELECT poster_id, 0 as messages, count(comment_id) as comments, sum(likes) as total_likes, 0 as message_likes, sum(likes) as comment_likes, min(comment_ts) as timefirst, max(comment_ts) as timelast
  FROM yakcomments
 GROUP BY poster_id
) q
GROUP BY q.poster_id;