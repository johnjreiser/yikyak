#!/usr/bin/env python

import pyak
import psycopg2

### PostgreSQL connector
dsn = "dbname=yaktrak host=localhost user=dba"

### Home location
lon = "-75.119871"
lat = "39.707961"
loc = pyak.Location(lat, lon)

### open YikYak stream
yys = pyak.Yakker(None, loc, True)

with psycopg2.connect(dsn) as con:
    with con.cursor() as cur:
        yakmsgsql = """
            INSERT INTO yakmessages (message_id, poster_id, handle, message, likes, comments, longitude, latitude, message_ts) 
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        yakcmtsql = """
            INSERT INTO yakcomments (comment_id, message_id, poster_id, comment, likes, comment_ts) 
            VALUES (%s, %s, %s, %s, %s, %s);
        """
        for yak in yys.get_yaks():
            cur.execute(yakmsgsql, (yak.message_id, yak.poster_id, yak.handle, yak.message, yak.likes, yak.comments, yak.longitude, yak.latitude, yak.time))
            print "Message {0} ({1}).".format(yak.message_id, yak.message[:32].encode('ascii', 'ignore'))
            if yak.comments > 0:
                for cmt in yys.get_comments(yak.message_id):
                    cur.execute(yakcmtsql, (cmt.comment_id, cmt.message_id, cmt.poster_id, cmt.comment, cmt.likes, cmt.time))
                    print "Comment {0} ({1}).".format(cmt.comment_id, cmt.comment[:32].encode('ascii', 'ignore'))
