# Comments

Simple comment system for blogs.

- It is free (more info later)
- It doesn't have adds
- It respects your privacy

Currently a very minimal set of features are implemented, and it relies on a external service
that provides the storage and API layer.

## Usage

In order to use is you need to complete 2 steps.

## Provisioning your own backend

Our backend is going to be based in [FaunaDB](https://fauna.com/). FaunaDB provides document storage
(MongoDB like) and it can create a graphql API for you. This API will be used by our frontend to
read and write comments.

First you'll need an account in [FaunaDB](https://fauna.com/) and log in.

You will see your dashboard page like in the screenshot below.

![Dashboard](/img/dashboard.png)

Click on the `New database` button, enter the DB name of your choice and click `Save`.

![Dashboard](/img/newDB.png)

A DB will be created and you will be redirected to the DB page.

![DB page](/img/DBPage.png)

We are going to use GraphQL so just click `GraphQL` in the left menu.

![GraphQL](/img/graphql.png)

Now you need to click the `Import Schema` button and upload the file [schemal.graphql](/schemal.graphql) that lives
on this repository.

This will create the collections and indexes we need, but we need to sort out some permissions.
To do that, click on the `Shell` button on the left menu.

You will need to enter the following command in the shell:

```
Update(Collection("Comment"), {permissions: {read: "public", create: "public"}})
```

![Shell1](/img/shell1.png)

Then click on `Run Query`. The query should run and you should see a response similar to the
following screenshot.

![Shell2](/img/shell2.png)

This query applied the necessary permissions to read and create new comments. There is an additional
permission we need to change, to allow indexing comments by discussion. Enter and execute the following
query in the shell.

```
Update(Index("commentsByDiscussionId"), { permissions: { read: "public" } })
```

Nice. The permissions are ready now. There is a last step, getting the access key.
Click on the `Security` button on the left menu.

![Keys](/img/keys.png)

Click on `New key` to create your key.

![Key config](/img/keyconfig.png)

Select `Client` as the role and enter a name of your choice as key name. When you are
happy click `Save`. The key will be shown on the screen like in the following screenshot.

![Access key](/img/accessKey.png)

Make sure you copy this key as is the only time you will see it. If you forget don't worry,
you can create a new one following the same steps.

### Load the library in your HTML/JS

First, you need to load the `Comments.js` file. The compiled file lives in
https://simple-comments.netlify.com/Comments.js. You can see the HTML code
you need below.

```html
<!doctype html>

<body>
  <script src="https://simple-comments.netlify.com/Comments.js"></script>
</body>
```

Once the script is loaded, a `startComments` function should be available.
You just need to call it and pass some parameters:
- `node`: is the html node where you want to mount your comment system.
- `endpoint`: is the graphql endpoint, it you followed the instructions, it should be `https://graphql.fauna.com/graphql`.
- `accessKey`: is the key you created a minute ago.
- `discussionId`: this is used to support many topics. For example you can use the url or slug of the post.

An example is provided below:

```html
<!doctype html>

<body style="width: 80%; margin: auto">
  <div></div>
  <script src="https://simple-comments.netlify.com/Comments.js"></script>
  <script>
      startComments({
        node: document.querySelector("div"),
        endpoint: "https://graphql.fauna.com/graphql",
        accessKey: "dasdj-your-own-access-key-fjpi",
        discussionId: "/posts/awesome-post-title"
      });
  </script>
</body>
```
Here we tell the comment system to render in the empty div, and load and save the comments
on the topic `/posts/awesome-post-title`.

Load your page and if everything was set up correctly, you should see the comment system 
being rendered in you pages!

### Limits

At the moment of writing this FaunaDB offers a generous free tier with:

- 5GB storage
- 100K read operations per day
- 50K write operations per day
- 50 MB data transfer per day

These limits are more than enough for my use case, but have a look at the [current pricing](https://fauna.com/pricing)

## Ok but is it production ready?

Depends, I intend to use it for [my blog](https://danmarcab.com) where I expect between 0 and 1 comments per
month. For my use case I think is good enough. If you have a big volume of comments or page visits, you
may run into the limits of [FaunaDB](https://fauna.com/)
