------------------------------------------------------------------------------------------------------------------------------------------------------------------

--DDL Queries

-- Users TABLE

CREATE TABLE "users" (
    "id" SERIAL PRIMARY KEY,
    "username" VARCHAR(25) UNIQUE NOT NULL  
);

-- Topics TABLE

CREATE TABLE "topics" (
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR(30) UNIQUE NOT NULL,
    "description" TEXT
);


-- Posts TABLE

CREATE TABLE "posts" (
    "id" SERIAL PRIMARY KEY,
    "title" VARCHAR(100) NOT NULL,
    "content" TEXT,
    "url" TEXT,
    "topic_id" INTEGER REFERENCES "topics" ON DELETE CASCADE,
    "user_id" INTEGER REFERENCES "users" ON DELETE SET NULL,
    CONSTRAINT "content_or_url" CHECK (
        (content IS NOT NULL AND url IS NULL) OR
        (content IS NULL AND url IS NOT NULL)
    )   
);


-- Comments TABLE

CREATE TABLE "comments" (
    "id" SERIAL PRIMARY KEY,
    "content" TEXT NOT NULL,
    "post_id" INTEGER REFERENCES "posts" ON DELETE CASCADE,
    "user_id" INTEGER REFERENCES "users" ON DELETE SET NULL,
    "parent_id" INTEGER REFERENCES "comments" ON DELETE CASCADE
);

-- Votes TABLE

CREATE TABLE "votes" (
    "id" SERIAL PRIMARY KEY,
    "value" SMALLINT NOT NULL CHECK ("value" IN (-1, 1)),
    "post_id" INTEGER REFERENCES "posts" ON DELETE CASCADE,
    "user_id" INTEGER REFERENCES "users" ON DELETE SET NULL
);



------------------------------------------------------------------------------------------------------------------------------------------------------------------

--DML Queries

-- Users TABLE

INSERT INTO "users" ("username")
SELECT DISTINCT "username" FROM (
    SELECT "username" FROM "bad_posts"
    UNION
    SELECT "username" FROM "bad_comments"
) AS "unique_usernames";



-- Topics TABLE

INSERT INTO "topics" ("name","description")
SELECT DISTINCT "topic",
                NULL
FROM "bad_posts";


-- Posts TABLE

INSERT INTO "posts" ("title", "content", "url", "topic_id", "user_id")
SELECT
    CASE WHEN LENGTH(bp."title") > 100 THEN SUBSTRING(bp."title" FROM 1 FOR 100) ELSE bp."title" END AS "title",
    bp."text_content",
    bp."url",
    t."id" AS "topic_id",
    u."id" AS "user_id"
FROM "bad_posts" bp
JOIN "topics" t 
ON bp."topic" = t."name"
JOIN "users" u 
ON bp."username" = u."username";


-- Comments TABLE

INSERT INTO "comments" ("content", "post_id", "user_id", "parent_id")
SELECT bc."text_content", 
  bc."post_id" AS "post_id", 
  u."id" AS "user_id", 
  NULL
FROM "bad_comments" bc
JOIN "users" u 
ON bc."username" = u."username";



-- Votes TABLE

INSERT INTO "votes" ("value", "post_id", "user_id")
SELECT 1 
AS "value", 
bp."id" AS "post_id", 
u."id" AS "user_id"
FROM "bad_posts" bp
JOIN "users" u 
ON u."username" = ANY(string_to_array(bp."upvotes", ','));


INSERT INTO "votes" ("value", "post_id", "user_id")
SELECT -1 
AS "value", 
bp."id" AS "post_id", 
u."id" AS "user_id"
FROM "bad_posts" bp
JOIN "users" u 
ON u."username" = ANY(string_to_array(bp."downvotes", ','));


------------------------------------------------------------------------------------------------------------------------------------------------------------------

--DQL Queries

a.List all users who haven’t logged in in the last year.

SELECT * FROM "users"
WHERE "id" NOT IN (
  SELECT "user_id" FROM "sessions"
  WHERE "created_at" > NOW() - INTERVAL '1 YEAR'
);


b.List all users who haven’t created any post.

SELECT * FROM "users"
WHERE "id" NOT IN (
  SELECT "user_id" FROM "posts"
);

c.Find a user by their username.

SELECT * FROM "users"
WHERE "username" = 'Ada66';

d.List all topics that don’t have any posts.

SELECT * FROM "topics"
WHERE "id" NOT IN (
  SELECT "topic_id" FROM "posts"
);

e.Find a topic by its name.

SELECT * FROM "topics"
WHERE "name" = 'road';

f.List the latest 20 posts for a given topic.

SELECT * FROM "posts"
WHERE "topic_id" = 1
ORDER BY "created_at" DESC
LIMIT 20;

g.List the latest 20 posts made by a given user.

SELECT * FROM "posts"
WHERE "user_id" = 40
ORDER BY "created_at" DESC
LIMIT 20;


h.Find all posts that link to a specific URL, for moderation purposes.

SELECT * FROM "posts"
WHERE "url" = 'http://ambrose.info';    

i.List all the top-level comments (those that don’t have a parent comment) for a given post.

SELECT * FROM "comments"
WHERE "post_id" = 1
AND "parent_id" IS NULL;

j.List all the direct children of a parent comment.

SELECT * FROM "comments"
WHERE "parent_id" = 1;

k.List the latest 20 comments made by a given user.

SELECT * FROM "comments"
WHERE "user_id" = 1
ORDER BY "created_at" DESC
LIMIT 20;

l.Compute the score of a post, defined as the difference between the number of upvotes and the number of downvotes

SELECT 
(SELECT COUNT(*) 
FROM "votes" 
WHERE "post_id" = 52 
AND "value" = 1) -
(SELECT COUNT(*) 
FROM "votes" 
WHERE "post_id" = 52
AND "value" = -1) 
AS "score";


