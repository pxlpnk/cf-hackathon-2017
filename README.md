Ordnungsamt - Simple Audit Logging for Contentful
-------------------------------------------------

At Grumpy BOFH Inc we needed an audit log of who has been doing what with our precious content. The chosen solution was to configure webhooks on the Space where content is managed, and use this to populate a second restricted Space with a record of changes.

The webhooks are consumed by a Sinatra app, which massages the metadata from the webhook and spits it out to two destinations:

1. Using the CMA, each event is recorded in the Audit Log space
1. Events are also logged to a Fluentd instance so we can use existing Fluentd plugins to alert via Slack or Email, etc.

Things we came up against:

* Publish/Unpublish events do not log `sys.updatedBy` with the user key, this is present on all other events
* Publish/Unpublish "createdAt" timestamps correspond to the moment of publishing / deletion from the public index, which is confusing
* The README for contentful/contentful-management.rb is somewhat confusing, e.g. Content Types are described after Entries, in general it would be good to start with a minimal but complete example at the top to show how it works.
* We tried storing the raw data from the webhook in a JSON field; this broke the Web App - it couldn't handle JSON inception. The APIs were fine with it though.
