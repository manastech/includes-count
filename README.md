Includes Count
==============

This gem adds an `includes_count` method to active record queries, which adds the count of an association to a relation using a simple `SELECT` SQL query in a similar way as the `includes` method does, only that retrieving counts instead of the full records collection. 

This gem has been tested with ActiveRecord version 3.1.3.

Usage
=====

For example, in the following model:

    class Blog
      has_many :posts
      has_many :comments, :through => :posts
    end
    
    class Post
      belongs_to :blog
      has_many :comments
    end
    
    class Comment
      belongs_to :post
    end

It is possible to retrieve the number of posts in every blog with the command:

    blogs_with_posts_count = Blog.scoped.includes_count(:posts)

This will issue a simple `SELECT` query retrieving all counts and assigning them in memory, thus not requiring an `INNER JOIN` that could be expensive to handle in the database:

    SELECT SQL_NO_CACHE posts.blog_id, COUNT(id) AS posts_count FROM `posts` WHERE `posts`.`blog_id` IN (1, 2, 3, 4, 5, 6, 7, 8) GROUP BY `posts`.`blog_id`
    
The count is projected to a field named by default `association_name_count`:

    blogs_with_posts_count.map(&:posts_count)
    
The name of the method can be changed by supplying the `count_name` option:

    blogs_with_posts_count = Blog.scoped.includes_count(:posts, :count_name => 'number_of_posts')
    blogs_with_posts_count.map(&:posts_count)
    
The execution of the count is delayed until execution of the query, as happens with the `includes` clause, so further clauses, such as `where`, can be set to the relation:

    latest_blogs_with_posts_count = Blog.scoped.includes_count(:posts).where('updated_at > ?', 1.week.ago)

This will retrieve only the blogs that have been updated since 1 week ago, along with their counts. Supposing there are only two blogs that match that condition (ids 3 and 5), the `SELECT` query issued will be the following:

    SELECT SQL_NO_CACHE posts.blog_id, COUNT(id) AS posts_count FROM `posts` WHERE `posts`.`blog_id` IN (3, 5) GROUP BY `posts`.`blog_id`

Conditions can be specified on the included association (using a string, a hash or a proc), in order to filter which records are to be counted:

    blogs_with_rails_posts_count = Blog.scoped.includes_count(:posts, :count_name => 'rails_posts_count', :conditions => "category = 'rails'")
    
    SELECT SQL_NO_CACHE posts.blog_id, COUNT(id) AS posts_count FROM `posts` WHERE `posts`.`blog_id` IN (3, 5) AND `posts`.`category` = 'rails' GROUP BY `posts`.`blog_id`

    
Through Associations
--------------------

The `includes_count` method also supports through associations, and issues as many `SELECT` queries as needed to navigate the hierarchy and obtain the specified counts.

    blogs_with_comments_count = Blog.scoped.includes_count(:comments)
    
    SELECT SQL_NO_CACHE `posts`.*, FROM `posts` WHERE `posts`.`blog_id` IN (1, 2, 3, 4, 5, 6, 7, 8)
    
    SELECT SQL_NO_CACHE `comments`.post_id, COUNT(id) AS comments_count FROM `comments` WHERE `comments`.`post_id` IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12) GROUP BY `comments`.`post_id`

As usual, the value can be accessed via the method named after the association, and overridden via `count_name`:

    blogs_with_posts_count.map(&:comments_count)
    
It is also possible to specify conditions at any of the intermediate associations in the `through` association:

    blogs_with_comments_count_from_rails_posts = Blog.scoped.includes_count(:comments, :through_options => { :posts => { :conditions => "category = 'rails'"} })
    
    SELECT SQL_NO_CACHE `posts`.*, FROM `posts` WHERE `posts`.`blog_id` IN (1, 2, 3, 4, 5, 6, 7, 8) AND `posts`.`category` = 'rails'
    
    SELECT SQL_NO_CACHE `comments`.post_id, COUNT(id) AS comments_count FROM `comments` WHERE `comments`.`post_id` IN (5, 6, 10, 11, 12) GROUP BY `comments`.`post_id`
    

Known Issues
------------

* The `includes_count` method is included only in `ActiveRecord::Relation` objects, which means you cannot execute it straight on a model. As a workaround, supply the method `scoped` before executing `includes_count`: `Blog.scoped.includes_count(:posts)`
